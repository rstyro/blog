---
title: Springboot集成MQTT：手把手教你实现设备通信
tags: [Spring Boot,MQTT]
categories: 物联网
date: 2025-05-11 18:14:45
updated: 2025-05-11 18:14:45
---


## 一、前言
- 在物联网（IoT）应用中，设备之间的实时通信至关重要。而 MQTT（Message Queuing Telemetry Transport） 是一种轻量级、高效的发布/订阅协议，非常适合用于物联网场景中的消息传输。

- 本文将带你一步步使用 Spring Boot + Paho-MQTT 实现一个简单的 MQTT 客户端，包括连接、订阅和发布消息的功能。

## 二、 技术栈🧰

- Spring Boot 3.* 以上
- Java 17+
- Maven 构建工具
- MQTT Broker（例如 EMQX、Mosquitto）
- Paho-MQTT（Java 客户端库）

<!--more-->

## 三、快速开始
- IDEA新建一个空的Springboot项目，然后添加或修改如下

#### 1、添加依赖

```xml
<properties>
    <java.version>17</java.version>
    <mqttv3.version>1.2.5</mqttv3.version>
    <lombok.version>1.18.30</lombok.version>
    <fastjson.version>2.0.57</fastjson.version>
</properties>

<dependencies>
    <!-- web -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>

    <!-- mqtt客户端依赖 -->
    <dependency>
        <groupId>org.eclipse.paho</groupId>
        <artifactId>org.eclipse.paho.client.mqttv3</artifactId>
        <version>${mqttv3.version}</version>
    </dependency>

    <!-- 方便getter setter方法 -->
    <dependency>
        <groupId>org.projectlombok</groupId>
        <artifactId>lombok</artifactId>
        <version>${lombok.version}</version>
    </dependency>

<!-- 方便序列化对象，可不要 -->
    <dependency>
        <groupId>com.alibaba.fastjson2</groupId>
        <artifactId>fastjson2</artifactId>
        <version>${fastjson.version}</version>
    </dependency>

<!-- 测试 -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-test</artifactId>
        <scope>test</scope>
    </dependency>

</dependencies>
```

#### 2、application.yml
- 为了支持多个MQTT服务地址，使用如下配置：

```yml
spring:
  application:
    name: springboot-mqtt


# mqtt配置
mqtt:
  max-retries: 10
  clients:
    client1:
      brokerUrl: tcp://broker.emqx.io:1883
      clientId: client1Id
      username: test
      password: test
      topics:
        - topic: /device/control
          qos: 1
        - topic: /test/rstyro
          qos: 1
        - topic: /room/502
          qos: 1
        - topic: test/topic
          qos: 1
#    client2:
#      brokerUrl: tcp://127.0.0.1:1883
#      clientId: client2Id
#      username: admin
#      password: admin
#      topics:
#        - topic: /device/test
#          qos: 1

```

#### 3、对应的配置类
- 根据yml生成对应的配置类：`MqttClientProperties`

```java
import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;
import java.util.List;
import java.util.Map;

@Data
@Component
@ConfigurationProperties(prefix = "mqtt")
public class MqttClientProperties {
    /**
     * 最大重试次数
     */
    private int maxRetries=10;
    /**
     * 多个MQTT客户端map
     */
    private Map<String, ClientConfig> clients;

    @Data
    public static class ClientConfig  {
        // MQTT服务地址
        private String brokerUrl;
        // 客户端ID
        private String clientId;
        // 认证的账号密码
        private String username;
        private String password;
        // 多个主题
        private List<TopicConfig> topics;
    }

    @Data
    public static class TopicConfig {
        // 主题
        private String topic;
        /**
         * 消息传递的保证程度：
         * 0=最多一次，消息不会被确认。不会有重发机制
         * 1=至少一次，确保消息至少会被送达一次，但也可能多次。这意味着接收者可能会收到重复的消息
         * 2=恰好一次，提供了最高的消息传递保证，确保每条消息仅被接收者准确地接收一次。这是最安全但也是最耗资源的方式
         *      使用两阶段握手协议来确保消息的唯一性和可靠性。
         *      首先发送PUBLISH消息并等待PUBREC响应，然后发送PUBREL消息并等待PUBCOMP响应。
         *      适用于不允许消息丢失或重复的关键性应用
         */
        private int qos;
    }
}
```

#### 4、管理类
- 为了方便管理MQTT客户端，我们新建一个: `MqttClientManager` 来管理

**构造函数：**

```java
@Slf4j
@Component
public class MqttClientManager {

    // 存储所有客户端实例
    private final Map<String, MqttClient> clients = new ConcurrentHashMap<>();

    private final MqttClientProperties mqttProperties;
    private final ObjectMapper objectMapper;

    @Autowired
    public MqttClientManager(MqttClientProperties mqttProperties, ObjectMapper objectMapper) {
        this.mqttProperties = mqttProperties;
        this.objectMapper = objectMapper;
    }

    // 应用启动完成后初始化MQTT客户端
    @EventListener(ApplicationReadyEvent.class)
    public void init() {
        initializeClientsWithRetry(mqttProperties.getMaxRetries());
    }
}
```


**initializeClientsWithRetry方法**
- 这个方法主要是初始化MQTT客户端并当连接失败时进行重试

```java
private void initializeClientsWithRetry(int maxRetries) {
        mqttProperties.getClients().forEach((name, config) -> {
            int attempt = 0;
            while (attempt < maxRetries) {
                try {
                    MqttClient client = new MqttClient(
                            config.getBrokerUrl(),
                            config.getClientId(),
                            new MemoryPersistence()
                    );
                    // 客户端连接配置
                    MqttConnectOptions options = getMqttConnectOptions(config);
                    // 设置客户端回调逻辑
                    setupClientCallback(client, name, config.getTopics());
                    client.connect(options);
                    clients.put(name, client);
                    break; // 成功退出循环
                } catch (MqttException e) {
                    handleInitializationFailure(name, ++attempt, maxRetries, e);
                }
            }
        });
    }
```
- 代码很简单，主要看 `setupClientCallback` 客户端回调相关


**setupClientCallback**

```java
private void setupClientCallback(MqttClient client, String clientName, List<MqttClientProperties.TopicConfig> topics) {
        client.setCallback(new MqttCallbackExtended() {
            @Override
            public void connectComplete(boolean reconnect, String serverURI) {
                log.info("MQTT 连接成功: {}", serverURI);
                if (reconnect) {
                    log.info("MQTT 客户端[{}]断开后重连成功", clientName);
                    resubscribeTopics(client, clientName, topics);
                } else {
                    log.info("首次连接到 Broker: {}", serverURI);
                    subscribeTopics(client, clientName, topics);
                }
            }

            @Override
            public void connectionLost(Throwable cause) {
                log.error("MQTT 连接丢失: {}", cause.getMessage(), cause);
            }

            @Override
            public void messageArrived(String topic, MqttMessage message) {
                String payload = new String(message.getPayload(),UTF_8);
            	log.info("收到消息 - 主题: {}, 内容: {}", topic, payload);
            }

            @Override
            public void deliveryComplete(IMqttDeliveryToken token) {
                log.debug("消息发送完成");
            }
        });
    }
```

- 1、`connectComplete` 主要是连接完成之后，首次配置主题订阅，和重连后重新配置主题
- 2、`messageArrived()`监听收到消息，对消息进行解析处理，这个根据自己业务处理就行
- 订阅主题方法`subscribeTopics`如下：



**subscribeTopics**

```java
private void subscribeTopics(MqttClient client, String name, List<MqttClientProperties.TopicConfig> topics) {
        for (MqttClientProperties.TopicConfig topic : topics) {
            try {
                client.subscribe(topic.getTopic(), topic.getQos());
                log.info("客户端 [{}] 已成功订阅主题: {}", name, topic.getTopic());
            } catch (MqttException e) {
                log.error("客户端 [{}] 订阅主题 [{}] 失败", name, topic.getTopic(), e);
            }
        }
    }
```

- resubscribeTopics和subscribeTopics 逻辑是一样的，抽2个方法是为了重连时可能有其他操作要处理
- 如上的这些方法是初始化客户端并监听订阅主题的
- 如果要发送消息，我们还需要添加发布消息的方法，如下：



**publish**



```java
/**
 * 向指定客户端和主题发布消息
 * @param clientName 客户端名称（配置中定义）
 * @param topic      主题名称
 * @param payload    要发布的对象内容（将自动转换为 JSON）
 * @param qos        消息质量等级（0, 1, 2）
 * @param retained 是否保留消息
 */
public void publish(String clientName, String topic, Object payload, int qos,boolean retained) {
    MqttClient client = clients.get(clientName);
    if (client != null && client.isConnected()) {
        try {
            // 使用 objectMapper 将对象转为 JSON 字符串，并编码为字节数组
            String jsonPayload = objectMapper.writeValueAsString(payload);
            client.publish(topic, jsonPayload.getBytes(StandardCharsets.UTF_8), qos,retained);
            log.info("消息已发布到主题: {}, 内容: {}", topic, jsonPayload);
        } catch (JsonProcessingException e) {
            log.error("MQTT 消息序列化失败", e);
        } catch (MqttException e) {
            log.error("发布 MQTT 消息失败: {}", e.getMessage(), e);
        }
    } else {
        log.warn("MQTT 客户端 [{}] 不在线，无法发布消息到主题 [{}]", clientName, topic);
    }
}
```

- 这样，我们发布和订阅的方法都有了
- 为了服务的健壮性，我们再加一个方法`checkConnections`去检查客户端，断开就重新连接

**checkConnections**

```java
@Scheduled(fixedRate = 60_000)
public void checkConnections() {
    log.info("健康检查与自动重连");
    clients.forEach((name, client) -> {
        if (!client.isConnected()) {
            log.warn("MQTT 客户端 [{}] 当前未连接，尝试重新连接", name);
            try {
                client.reconnect();
            } catch (MqttException e) {
                log.error("手动重连失败", e);
            }
        }
    });
}
```

- 有上面这些方法，我们的这个demo算是齐全了，接下来就是测试了

#### 5、使用与测试

- 如何使用`MqttClientManager` 呢？我们可以新建一个接口

```java
@Slf4j
@RestController
@RequestMapping("/test")
@RequiredArgsConstructor
public class TestController {

    private final MqttClientManager mqttClientManager;
    private final MqttClientProperties mqttClientProperties;

    @PostMapping("/sendMessage")
    public Object sendMessage(@RequestBody Map<String, Object> data) {
        String topic = (String) data.get("topic");
        if(Objects.isNull(topic)) {
            topic = "test/topic";
        }
        String finalTopic = topic;
        mqttClientProperties.getClients().forEach((clientName, v)->{
            try {
                mqttClientManager.publish(clientName, finalTopic,data,1);
            }catch (Exception e){
                log.error(e.getMessage(),e);
            }
        });
        return data;
    }
}

```

- 测试结果如下图：

**请求发送接口**

![](api.png)

**控制台收到消息**

![](msg.png)

**使用mqttx客户端发送消息，也可以收到**

![](mqttx1.png)

## 四、总结与展望

**文本总结：**
- 本文围绕 Spring Boot 如何集成 MQTT 协议进行了详细的讲解，从环境搭建、依赖引入、配置管理到客户端连接、消息订阅与发布，逐步引导读者实现一个完整的 MQTT 客户端通信模块。我们通过 MqttClientManager 类实现了对多个客户端的统一管理，并结合 Spring Boot 的事件监听机制和定时任务，确保了系统的稳定性与健壮性。

**完整的代码**
- Github地址：[https://github.com/rstyro/Springboot/tree/master/springboot-mqtt](https://github.com/rstyro/Springboot/tree/master/springboot-mqtt)


**写在最后**
-  随着物联网技术的不断发展，设备之间的通信变得越来越复杂，而 MQTT 凭借其轻量、高效、可靠的特点，成为 IoT 场景中的首选协议之一。Spring Boot 作为一个强大的后端开发框架，为快速构建 MQTT 客户端提供了良好的支持。

- 希望本文能够帮助你快速掌握 Spring Boot 集成 MQTT 的核心方法，并为你后续开发更复杂的物联网系统打下坚实基础。如果你喜欢这种风格的技术实践文章，也欢迎继续关注我后续关于 IoT、微服务通信、边缘计算等相关内容的分享！
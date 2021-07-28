---
title: Gateway与Nacos实现动态路由
date: 2021-07-28 18:37:59
updated: 2021-07-28 18:37:59
tags: [Gateway,Nacos,SpringCloud-Alibaba]
categories: Java
---

### 一、前言
+ 一般Gateway配置路由会在配置文件中写死，如下

```yaml
spring:
  application:
    name: gateway
  cloud:
    gateway:
      enabled: true
      discovery:
        locator:
          enabled: true 
          lower-case-service-id: true #是将请求路径上的服务名配置为小写
      routes:
        - id: provider
          uri: lb://nacos-provider
          predicates:
            - Path=/provider/**
          filters:
            # StripPrefix 数字表示要截断的路径的数量
            - StripPrefix=1
        - id: consumer
          uri: lb://nacos-consumer
          predicates:
            - Path=/consumer/**
          filters:
            - StripPrefix=1
```

+ 当我们想添加新路由的时候还得，在routes中添加新路由然后重启服务
+ 这样显然是不太合理的，那路由是不是可以动态获取与更新呢（废话）

### 二、实现思路
+ 在Gateway启动的时候，读取nacos的路由信息配置，然后刷到Gateway路由
+ 监听nacos信息变化，如果配置修改了，重新调用Gateway刷新事件，刷新最新路由信息
+ Gateway的路由信息，默认是保存在内存中的，可查看`GatewayAutoConfiguration`源码


```java
**
 * @author Spencer Gibb
 * @author Ziemowit Stolarczyk
 */
@Configuration(proxyBeanMethods = false)
@ConditionalOnProperty(name = "spring.cloud.gateway.enabled", matchIfMissing = true)
@EnableConfigurationProperties
@AutoConfigureBefore({ HttpHandlerAutoConfiguration.class,
		WebFluxAutoConfiguration.class })
@AutoConfigureAfter({ GatewayLoadBalancerClientAutoConfiguration.class,
		GatewayClassPathWarningAutoConfiguration.class })
@ConditionalOnClass(DispatcherHandler.class)
public class GatewayAutoConfiguration {


	@Bean
	@ConditionalOnMissingBean(RouteDefinitionRepository.class)
	public InMemoryRouteDefinitionRepository inMemoryRouteDefinitionRepository() {
		return new InMemoryRouteDefinitionRepository();
	}

	@Bean
	@Primary
	public RouteDefinitionLocator routeDefinitionLocator(
			List<RouteDefinitionLocator> routeDefinitionLocators) {
		return new CompositeRouteDefinitionLocator(
				Flux.fromIterable(routeDefinitionLocators));
	}
	//...
}
```

+ 默认就是`InMemoryRouteDefinitionRepository`，实现了`RouteDefinitionRepository`，底层是一个线程安全的Map:`SynchronizedMap` 
+ 其中注解`@ConditionalOnMissingBean(RouteDefinitionRepository.class)` 表示RouteDefinitionRepository没有实现类时，使用`InMemoryRouteDefinitionRepository`

#### 实现动态路由

**方法1**

+ 既然知道了 路由信息 是保存在内存中，那我们可以自定义路由保存的位置，如：redis 等
+ 只需要继承 `RouteDefinitionRepository` 接口，重写其中的三个方法逻辑即可

```java
// 获取所有路由信息
Flux<RouteDefinition> getRouteDefinitions();

// 添加路由信息
Mono<Void> save(Mono<RouteDefinition> route);

// 删除路由信息
Mono<Void> delete(Mono<String> routeId);
```

+ 他们的save和delete都是 `RouteDefinitionWriter` 接口的方法

**方法二**
+ 监听Nacos的路由配置变化，Nacos变化了，我们这边收到数据
+ 收到数据之后，发布刷新路由事件，通知所有存储路由的组件更新路由即可

***1、自定义动态路由发布事件***
+ 实现Spring的`ApplicationEventPublisherAware` 接口。
+ 初始化时监听Nacos路由配置信息，注入：`RouteDefinitionWriter`更新`InMemoryRouteDefinitionRepository` 数据，并发布`RefreshRoutesEvent`事件
+ 完整代码如下：

```java
/**
 * 动态路由配置
 *
 */
@Slf4j
@Component
@ConditionalOnProperty(name = "route.dynamic.enabled", matchIfMissing = true)
public class DynamicGatewayRouteConfig implements ApplicationEventPublisherAware {

    @Value("${route.dynamic.enabled}")
    private Boolean enabled =Boolean.FALSE;

    @Value("${route.dynamic.dataId}")
    private String dataId;

    @Value("${route.dynamic.namespace}")
    private String namespace;

    @Value("${route.dynamic.group}")
    private String group;

    @Value("${spring.cloud.nacos.config.server-addr}")
    private String serverAddr;

    @Value("${spring.cloud.nacos.config.username}")
    private String username;

    @Value("${spring.cloud.nacos.config.password}")
    private String password;

    private RouteDefinitionWriter routeDefinitionWriter;
    
    private final long timeoutMs=5000;

    @Autowired
    public void setRouteDefinitionWriter(RouteDefinitionWriter routeDefinitionWriter) {
        this.routeDefinitionWriter = routeDefinitionWriter;
    }

    private ApplicationEventPublisher applicationEventPublisher;

    private static final List<String> ROUTES = new ArrayList<String>();

    @PostConstruct
    public void dynamicRouteByNacosListener() {
        if(enabled){
            try {
                Properties properties = new Properties();
                properties.put("serverAddr", serverAddr);
                properties.put("namespace", namespace);
                properties.put("username", username);
                properties.put("password", password);
                // 参考官网：https://nacos.io/zh-cn/docs/sdk.html
                ConfigService configService = NacosFactory.createConfigService(properties);
                // 程序首次启动, 并加载初始化路由配置
                String initConfigInfo = configService.getConfig(dataId, group, timeoutMs);
                batchAddOrUpdateRouteAndPublish(initConfigInfo);
                configService.addListener(dataId, group, new Listener() {
                    @Override
                    public void receiveConfigInfo(String configInfo) {
                        batchAddOrUpdateRouteAndPublish(configInfo);
                    }

                    @Override
                    public Executor getExecutor() {
                        return null;
                    }
                });
            } catch (NacosException e) {
                e.printStackTrace();
            }
        }

    }

    /**
     * 清空所有路由
     */
    private void clearRoute() {
        for(String id : ROUTES) {
            this.routeDefinitionWriter.delete(Mono.just(id)).subscribe();
        }
        ROUTES.clear();
    }

    /**
     * 添加单条路由信息
     * @param definition RouteDefinition
     */
    private void addRoute(RouteDefinition definition) {
        routeDefinitionWriter.save(Mono.just(definition)).subscribe();
        ROUTES.add(definition.getId());
    }

    /**
     * 批量添加或更新路由，及发布 路由
     * @param configInfo 配置文件字符串, 必须为json array格式
     */
    private void batchAddOrUpdateRouteAndPublish(String configInfo) {
        try {
            clearRoute();
            List<RouteDefinition> gatewayRouteDefinitions = JSONObject.parseArray(configInfo, RouteDefinition.class);
            for (RouteDefinition routeDefinition : gatewayRouteDefinitions) {
                addRoute(routeDefinition);
            }
            publish();
            log.info("添加路由信息. {}", JSON.toJSONString(gatewayRouteDefinitions));
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void publish() {
        this.applicationEventPublisher.publishEvent(new RefreshRoutesEvent(this.routeDefinitionWriter));
    }

    @Override
    public void setApplicationEventPublisher(ApplicationEventPublisher applicationEventPublisher) {
        this.applicationEventPublisher = applicationEventPublisher;
    }
}

```

+ 配置文件内容：

```yaml
spring:
  application:
    name: gateway
  redis:
    host: 127.0.0.1
    port: 6379
    password:
  profiles:
    active: dev
  cloud:
    nacos:
      config:
        server-addr: 127.0.0.1:8848
        file-extension: yaml
        group: DEFAULT_GROUP
        username: nacos
        password: nacos
      discovery:
        server-addr: 127.0.0.1:8848
        username: nacos
        password: nacos
#  # 网关配置在nacos中配置
    gateway:
      enabled: true
      discovery:
        locator:
          enabled: true 
          lower-case-service-id: true #是将请求路径上的服务名配置为小写
# 动态路由配置
route:
  dynamic:
    enabled: true
    namespace:
    dataId: gateway_route
    group: DEFAULT_GROUP
```

***2、Nacos配置路由信息***
+ Nacos中的gateway_route配置内容如下：

![](nacos.png)

```json
[{
    "id":"provider",
    "predicates":[
      {
        "args":{
          "pattern": "/provider/**"
        },
        "name": "Path"
      }
    ],
    "filters": [
      {
        "name": "StripPrefix",
        "args": {
          "parts": "1"
        }
      }
    ],
    "uri": "lb://nacos-provider"
},{
    "id":"consumer",
    "predicates":[
      {
        "args":{
          "pattern": "/consumer/**"
        },
        "name": "Path"
      }
    ],
    "filters": [
      {
        "name": "StripPrefix",
        "args": {
          "parts": "1"
        }
      },
      {
      	"name":"MyRequestRateLimiter",
      	"args":{
      		"redis-rate-limiter.replenishRate": 1,
      		"redis-rate-limiter.burstCapacity": 2,
      		"key-resolver": "#{@pathKeyResolver}"
      	}
      }
    ],
    "uri": "lb://nacos-consumer"
}]
```


+ 启动网关服务，查看控制台

![](route.png)

+ 每个json对象都是一个：`org.springframework.cloud.gateway.route.RouteDefinition`
+ MyRequestRateLimiter 这个是我随便配置的Redis限流，也是生效的

![](limit.png)

自此就Gateway动态路由就结束了，完整SpringCloud-alibaba示例源码如下：

+ **Github:** [https://github.com/rstyro/SpringCloud-Alibaba-learning/tree/main/springcloud-gateway](https://github.com/rstyro/SpringCloud-Alibaba-learning/tree/main/springcloud-gateway)
+ **Gitee:** [https://gitee.com/rstyro/SpringCloud-Alibaba-learning/tree/main/springcloud-gateway](https://gitee.com/rstyro/SpringCloud-Alibaba-learning/tree/main/springcloud-gateway)


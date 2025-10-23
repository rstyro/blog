---
title: spring-ai 三行代码治好AI “祖传健忘症”
tags: [AI,Spring AI Alibaba]
categories: AI
date: 2025-07-02 11:10:38
updated: 2025-07-02 11:10:38
---



> 让AI记住你说过的话，只需几行代码

在日常与AI聊天机器人互动时，你是否曾因它“记性差”而沮丧？刚告诉它“我叫张三”，下一句问“我是谁”时，它却茫然无措。这种尴尬的背后，是**大模型本质的无状态特性**——每次请求都是独立处理，无法自动关联历史上下文。

## 一、为什么需要对话记忆？

想象一个典型场景：


```
chatModel.call("我叫张三");  
chatModel.call("我是谁？"); // 模型无法回答你是“张三”
```

**大模型（LLM）本身不保存任何状态**，每次调用都是全新的开始。在真实应用场景中，这种“健忘症”会带来巨大障碍——无论是智能客服处理用户咨询，还是旅行助手规划行程，都需要基于**连续对话的上下文**才能提供连贯服务。

<!--more-->

Spring AI 的ChatMemory正是为解决这一痛点而生，它让开发者能轻松管理对话历史，打造真正智能的多轮对话体验。



## 二、技术探秘：ChatMemory的架构与实现



### 核心接口设计

Spring AI通过`ChatMemory`接口统一了对话记忆的抽象层，其核心能力包括：

- **消息存储**：保存对话中的用户输入和AI响应
- **上下文检索**：根据会话ID获取相关历史
- **记忆管理**：自动清理过期或冗余信息



### 多样化存储策略

根据应用场景需求，开发者可选择多种存储后端：

| **存储类型**       | **适用场景**         | **依赖配置**                                               |
| :----------------- | :------------------- | :--------------------------------------------------------- |
| **内存存储**       | 开发测试、轻量级应用 | `InMemoryChatMemory`（默认启用）                           |
| **JDBC（关系型）** | 企业级应用、需持久化 | `spring-ai-starter-model-chat-memory-repository-jdbc`      |
| **Cassandra**      | 高并发、分布式系统   | `spring-ai-starter-model-chat-memory-repository-cassandra` |
| **Neo4j**          | 复杂关系型对话场景   | `spring-ai-starter-model-chat-memory-repository-neo4j`     |



## 三、Spring AI ChatMemory：从原理到实践的完整方案



- 为了让读者快速体验，我们以阿里云百炼模型（Spring AI Alibaba Starter）为例，演示不同存储后端的实现方式。

#### 1、内存存储：

- **开发测试首选:**


```xml
<!-- 阿里云百炼模型 -->
<dependency>    
  <groupId>com.alibaba.cloud.ai</groupId>    
  <artifactId>spring-ai-alibaba-starter-dashscope</artifactId>
</dependency>
<!-- 对话记忆-默认内存 -->
<dependency>    
  <groupId>com.alibaba.cloud.ai</groupId>    
  <artifactId>spring-ai-alibaba-starter-memory</artifactId>
</dependency>
```



**示例代码：**



```java
@RestController
@RequestMapping("/advisor/memory/in")
public class InMemoryController {

    public final String DEFAULT_CONVERSATION_ID="rstyro";
    private final ChatClient chatClient;

    // 默认放在内存，重启之后就没了
    private final InMemoryChatMemoryRepository chatMemoryRepository = new InMemoryChatMemoryRepository();
    private final int MAX_MESSAGES = 10;
    private final MessageWindowChatMemory messageWindowChatMemory = MessageWindowChatMemory.builder()
            .chatMemoryRepository(chatMemoryRepository)
            .maxMessages(MAX_MESSAGES)
            .build();

    public InMemoryController(ChatClient.Builder builder) {
        this.chatClient = builder
                .defaultAdvisors(
                        MessageChatMemoryAdvisor.builder(messageWindowChatMemory)
                                .build()
                )
                .build();
    }

    @GetMapping("/ask")
    public String ask(@RequestParam(value = "query", defaultValue = "你好，我叫张三") String query,
                       @RequestParam(value = "conversationId", defaultValue =DEFAULT_CONVERSATION_ID) String conversationId
    ) {
        return chatClient.prompt(query)
                .advisors(
                        a -> a.param(CONVERSATION_ID, conversationId)
                )
                .call().content();
    }

    @GetMapping("/messages")
    public List<Message> messages(@RequestParam(value = "conversationId", defaultValue = DEFAULT_CONVERSATION_ID) String conversationId) {
        return messageWindowChatMemory.get(conversationId);
    }

}
```

conversationId就是会话**唯一标识符ID**,整个将用户的多轮交互串联成连贯会话。实际应用中可通过用户ID、设备ID或随机UUID生成。

**测试效果**：

- 第一次请求：`GET /advisor/memory/in/ask?query=你好` → AI回复"你好！有什么可以帮你？"
- 第二次请求：`GET /advisor/memory/in/ask?query=我叫张三` → AI能识别"你之前提到过名字是张三"
- 第三次请求：`GET /advisor/memory/in/ask?query=我是谁？` → AI正确回答"你是张三"



#### 2、Redis存储：生产级高可用方案

- **适用场景**：需要分布式共享记忆、高并发访问（如电商大促期间的智能客服）




```xml
<!-- 对话记忆-redis -->
<dependency>
    <groupId>com.alibaba.cloud.ai</groupId>
    <artifactId>spring-ai-alibaba-starter-memory-redis</artifactId>
</dependency>
<!-- spring-ai-alibaba-starter-memory-redis 的<optional>true</optional>阻断依赖传递,所以要加一下 -->
<dependency>
    <groupId>redis.clients</groupId>
    <artifactId>jedis</artifactId>
</dependency>
```



然后使用示例如下：



```java
@RestController
@RequestMapping("/advisor/memory/redis")
public class RedisMemoryController {

    private final ChatClient chatClient;
    private final int MAX_MESSAGES = 100;
    private final MessageWindowChatMemory messageWindowChatMemory;

    public RedisMemoryController(ChatClient.Builder builder, RedisChatMemoryRepository redisChatMemoryRepository) {
        this.messageWindowChatMemory = MessageWindowChatMemory.builder()
                .chatMemoryRepository(redisChatMemoryRepository)
                .maxMessages(MAX_MESSAGES)
                .build();

        this.chatClient = builder
                .defaultAdvisors(
                        MessageChatMemoryAdvisor.builder(messageWindowChatMemory)
                                .build()
                )
                .build();
    }

    @GetMapping("/ask")
    public String ask(@RequestParam(value = "query", defaultValue = "你好，我叫张三") String query,
                       @RequestParam(value = "conversationId", defaultValue = "sessionId") String conversationId
    ) {
        return chatClient.prompt(query)
                .advisors(
                        a -> a.param(CONVERSATION_ID, conversationId)
                )
                .call().content();
    }

    @GetMapping("/messages")
    public List<Message> messages(@RequestParam(value = "conversationId", defaultValue = "sessionId") String conversationId) {
        return messageWindowChatMemory.get(conversationId);
    }
}

```



#### 3、数据库存储



- **适用场景**：需要留存对话记录的业务（如金融咨询、医疗服务）



```xml
<!-- 对话记忆-数据库相关依赖 -->
<dependency>
    <groupId>com.alibaba.cloud.ai</groupId>
    <artifactId>spring-ai-alibaba-starter-memory-jdbc</artifactId>
</dependency>
<!-- mysql 数据库连接 -->
<dependency>
    <groupId>com.mysql</groupId>
    <artifactId>mysql-connector-j</artifactId>
</dependency>
```

使用示例：

```java
@RestController
@RequestMapping("/advisor/memory/mysql")
public class MysqlMemoryController {

    private final ChatClient chatClient;
    private final int MAX_MESSAGES = 100;
    private final MessageWindowChatMemory messageWindowChatMemory;

    public MysqlMemoryController(ChatClient.Builder builder, MysqlChatMemoryRepository mysqlChatMemoryRepository) {
        this.messageWindowChatMemory = MessageWindowChatMemory.builder()
                .chatMemoryRepository(mysqlChatMemoryRepository)
                .maxMessages(MAX_MESSAGES)
                .build();

        this.chatClient = builder
                .defaultAdvisors(
                        MessageChatMemoryAdvisor.builder(messageWindowChatMemory)
                                .build()
                )
                .build();
    }

    @GetMapping("/ask")
    public String ask(@RequestParam(value = "query", defaultValue = "你好，我叫张三") String query,
                       @RequestParam(value = "conversationId", defaultValue = "sessionId") String conversationId
    ) {
        return chatClient.prompt(query)
                .advisors(
                        a -> a.param(CONVERSATION_ID, conversationId)
                )
                .call().content();
    }

    @GetMapping("/messages")
    public List<Message> messages(@RequestParam(value = "conversationId", defaultValue = "sessionId") String conversationId) {
        return messageWindowChatMemory.get(conversationId);
    }
}

```


- 还有很多存储方式，这里就不一一列举了



## 四、注意事项：避坑指南

- **内存存储的局限性**

  仅在开发或测试环境使用，生产环境务必切换为持久化存储（Redis/数据库）。

- **会话ID的唯一性**

  确保每个用户的会话ID唯一，避免不同用户的对话互相干扰。

- **消息容量限制**

  `maxMessages`需根据业务场景合理设置（如客服场景建议100-500条，避免遗漏关键信息）。

- **依赖冲突**

  引入Redis或数据库依赖时，注意排除冲突的传递依赖（如Spring Boot默认的HikariCP与某些数据库驱动的冲突）。

------

## 五、总结：让AI从"单次对话"到"有温度的陪伴"

- Spring AI的`ChatMemory`组件，通过标准化的接口和灵活的存储策略，让开发者能轻松为AI添加"长期记忆"。无论是轻量级的开发测试，还是高并发的生产环境，都能找到合适的解决方案。

- 下次开发多轮对话应用时，不妨试试这些方法——让你的AI不再"健忘"，而是成为能记住用户偏好、理解上下文的"智能伙伴"。

- （本文示例代码已上传至GitHub：https://github.com/rstyro/spring-ai-alibaba-demo，欢迎克隆体验！）

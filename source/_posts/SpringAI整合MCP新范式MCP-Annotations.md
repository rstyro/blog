---
title: SpringAI整合MCP新范式MCP-Annotations
tags: [AI,Spring AI,MCP]
categories: AI
date: 2025-10-28 18:37:46
---

## 一、前言

AI 领域的技术迭代确实非常迅速。几个月前我写过一篇关于 Spring AI 与 MCP（Model Context Protocol）的整合文章，如今 Spring AI 1.1.0-M3 版本又带来了全新的实现方式。

<!--more-->

上篇文章我们本地已经部署了Ollama了，正好可以借此验证 Spring AI 与 Ollama 集成调用 MCP 服务的能力。之前我们使用的是 Spring AI 1.0.0 版本，这次我们将升级到当前最新的 `1.1.0-M3` 版本。



从 Spring AI 1.1.0 开始，框架引入了一种全新的 MCP 服务创建与注册机制——**`Spring AI MCP Annotations`**。这套基于声明式 Java 注解的解决方案，简化了 MCP 服务器方法与客户端处理程序的开发与注册流程。




> **注意：目前 1.1.0版本还在开发中，还不是稳定版本，但是我们倒是可以尝尝鲜**




### 服务器注释

对于 MCP 服务器，提供以下注释：

- `@McpTool`- 实现具有自动 JSON 模式生成功能的 MCP 工具
- `@McpResource`- 通过 URI 模板提供对资源的访问
- `@McpPrompt`- 生成提示消息
- `@McpComplete`- 提供自动完成功能

### 客户端注释

对于 MCP 客户端，提供以下注释：

- `@McpLogging`- 处理日志消息通知
- `@McpSampling`- 处理采样请求
- `@McpElicitation`- 处理收集额外信息的引出请求
- `@McpProgress`- 在长时间运行的作期间处理进度通知
- `@McpToolListChanged`- 处理工具列表更改通知
- `@McpResourceListChanged`- 处理资源列表更改通知
- `@McpPromptListChanged`- 处理提示列表更改通知



### 特殊参数和注释

- `McpSyncServerExchange`- 用于有状态同步作的特殊参数类型，提供对服务器交换功能的访问，包括日志记录通知、进度更新和其他服务器端作。此参数会自动注入并从 JSON 架构生成中排除
- `McpAsyncServerExchange`- 用于有状态异步作的特殊参数类型，提供对具有响应式支持的服务器交换功能的访问。此参数会自动注入并从 JSON 架构生成中排除
- `McpTransportContext`- 用于无状态作的特殊参数类型，提供对传输级上下文的轻量级访问，而无需完整的服务器交换功能。此参数会自动注入并从 JSON 架构生成中排除
- `@McpProgressToken`- 标记一个方法参数以从请求中接收进度令牌。此参数会自动注入并从生成的 JSON 架构中排除
- `McpMeta`- 特殊参数类型，提供对 MCP 请求、通知和结果中元数据的访问。此参数会自动注入并从参数计数限制和 JSON 架构生成中排除



注解功能的底层实现依赖于：

```xml
<dependency>
    <groupId>org.springframework.ai</groupId>
    <artifactId>spring-ai-mcp-annotations</artifactId>
</dependency>
```

在实际使用中，我们无需单独引入此依赖，因为相关的客户端或服务端 starter 已经包含了它：

- `spring-ai-starter-mcp-client`
- `spring-ai-starter-mcp-client-webflux`
- `spring-ai-starter-mcp-server`
- `spring-ai-starter-mcp-server-webflux`
- `spring-ai-starter-mcp-server-webmvc`




## 二、快速开始

首先，我们在 Maven 项目中统一声明 Spring AI 的版本号和相关依赖，导入以下依赖

```xml
<properties>
    <revision>1.0.0</revision>
    <java.version>17</java.version>
    <maven.compiler.target>17</maven.compiler.target>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>

    <!-- springboot 与spring ai 相关版本 -->
    <spring-boot.version>3.4.0</spring-boot.version>
    <spring-ai.version>1.1.0-M3</spring-ai.version>
</properties>



<!-- 依赖声明 -->
<dependencyManagement>
    <dependencies>
        <!-- springboot 版本 -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-dependencies</artifactId>
            <version>${spring-boot.version}</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>

         <!-- Spring AI 版本管理 -->
        <dependency>
            <groupId>org.springframework.ai</groupId>
            <artifactId>spring-ai-bom</artifactId>
            <version>${spring-ai.version}</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
    </dependencies>

</dependencyManagement>
```

### 1、MCP服务端

- **技术选型：三种 MCP Server 启动器对比**

  Spring AI 提供了三种 MCP Server 实现，适用于不同的应用场景：



| 特性         | STDIO               | Spring MVC (SSE)            | WebFlux (Reactive SSE)               |
| :----------- | :------------------ | :-------------------------- | :----------------------------------- |
| **通信协议** | 标准输入/输出流     | HTTP + SSE、Streamable HTTP | HTTP + Reactive SSE、Streamable HTTP |
| **编程模型** | 同步                | 同步阻塞                    | 响应式非阻塞                         |
| **I/O模型**  | 阻塞                | 阻塞                        | 非阻塞                               |
| **线程模型** | 单线程              | 线程池（每个连接一个线程）  | 事件循环（少量线程）                 |
| **并发能力** | 低                  | 中等                        | 高                                   |
| **适用场景** | 命令行工具/本地调试 | 传统Web应用/内部系统        | 高并发/云原生应用                    |



- **`spring-ai-starter-mcp-server`**(STDIO)
    - 基于标准输入/输出流进行进程间通信，不依赖任何网络协议
- **`spring-ai-starter-mcp-server-webmvc`**(Spring MVC)
    - 基于传统的Spring MVC框架，适用于基于 **Spring MVC 构建的传统单体应用或企业内部系统**，需要将现有业务能力暴露给 AI 使用

- **`spring-ai-starter-mcp-server-webflux`**(Spring WebFlux)
    - 基于响应式编程模型，使用Reactive Server-Sent Events，采用非阻塞I/O模型，基于事件循环机制，使用少量线程即可处理大量并发连接



根据场景选择对应的依赖，本次我们选择`spring-ai-starter-mcp-server-webmvc` 来演示



##### ①、导入依赖

```xml
<dependency>
    <groupId>org.springframework.ai</groupId>
    <artifactId>spring-ai-starter-mcp-server-webmvc</artifactId>
</dependency>
```



##### ②、创建MCP服务

我们随意创建一个类，使用`@Service`使spring扫描得到，然后在你所需要暴露的方法上，使用`@McpTool` 注解即可，如下示例，我们创建一个趣味工具的MCP服务，测算今日运势。

```java
/**
 * 趣味工具
 */
@Slf4j
@Service
public class FortuneTellingTools {

    private final Random random = new Random();

    /**
     * 测算今日运势
     * 
     * @param exchange MCP 服务器交换对象，用于发送通知
     * @param progressToken 进度令牌，用于跟踪长时间运行的操作
     * @return 格式化的运势报告字符串
     */
    @McpTool(name = "daily_fortune", description = "测算今日运势")
    public String getDailyFortune(
            McpSyncServerExchange exchange,
            @McpProgressToken String progressToken) {

        log.info("token={}", progressToken);

        // 发送日志通知
        exchange.loggingNotification(McpSchema.LoggingMessageNotification.builder()
                .level(McpSchema.LoggingLevel.INFO)
                .data("工具调用token为: " + progressToken)
                .build());

        progressToken = StrUtil.nullToDefault(progressToken, IdUtil.fastSimpleUUID());

        String[] luckLevels = {"大吉", "中吉", "小吉", "平", "凶", "大凶"};
        String[][] luckDescriptions = {
                {"诸事顺利，心想事成"}, {"平稳发展，小有收获"}, {"稍有波折，但无大碍"},
                {"平平淡淡才是真"}, {"今日不宜做重大决定"}, {"诸事不宜，低调行事"}
        };

        int luckIndex = random.nextInt(luckLevels.length);

        // 发送进度通知
        exchange.progressNotification(new McpSchema.ProgressNotification(
                progressToken, 0.5, 1.0, "Processing..."));

        int overallScore = 60 + luckIndex * 8 + random.nextInt(20);
        String[] emojis = {"🎉", "😊", "🙂", "😐", "😟", "💀"};

        exchange.progressNotification(new McpSchema.ProgressNotification(
                progressToken, 0.9, 1.0, "准备返回数据"));

        return """
                🔮 您今日运势报告
                
                📊 综合评分：%d/100
                ✨ 运势等级：%s
                💫 运势解读：%s
                
                %s 保持好心情，明天会更好！
                """.formatted(overallScore, luckLevels[luckIndex],
                luckDescriptions[luckIndex][0], emojis[luckIndex]);
    }

}
```

- 很简单一个注解就搞定所有



- 如果是之前的版本（1.0.0）还需要如下配置，手动注册。

```java

@Bean
public ToolCallbackProvider toolCallbackProvider(你的服务类名 mcpService) {
    return MethodToolCallbackProvider.builder().toolObjects(mcpService).build();
}

```

- 如果有多个服务类，你还得手动一个一个的注入配置，现在直接一个注解解放了，由程序自己扫描帮我们注册。




##### ③、配置MCP服务

上面我们已经创建了一个MCP服务，现在我们在配置文件`application.yml`中来配置它

```yaml
server:
  port: 8101

spring:
  application:
    name: mcp-server-annotation

  ai:
    mcp:
      server:
        name: fortuneServer
        annotation-scanner:
          enabled: true
        version: 1.0.0
        type: SYNC
        protocol: STREAMABLE  # SSE or STDIO, STREAMABLE
        streamable-http:
          mcp-endpoint: /mcp
        capabilities:
          tools: true
          logging: true


logging:
  level:
    root: info
    org.springframework.ai: debug
    io.modelcontextprotocol: debug
    top.lrshuai.ai: info

```

- 我们的`spring.ai.mcp.annotation-scanner.enabled`要设置为`true`,它会去扫描`@McpTool`这些MCP的注解帮我们自动注册
- `protocol` 我这里选择最新出的：`STREAMABLE`,Streamable HTTP是 MCP 协议的一次重大升级，为了解决传统通信方式的一下缺陷，如下对比：



| 特性             | Stdio (标准输入/输出)                            | SSE (服务器发送事件)                                 | **Streamable HTTP (可流式HTTP)**                             |
| :--------------- | :----------------------------------------------- | :--------------------------------------------------- | :----------------------------------------------------------- |
| **通信方式**     | 本地进程间管道                                   | 基于HTTP长连接                                       | **标准HTTP + 动态流式升级**                                  |
| **数据流向**     | 双向                                             | 单向 (仅服务器到客户端)                              | **灵活，支持双向通信**                                       |
| **核心应用场景** | 本地开发、调试                                   | 实时通知（**正被Streamable HTTP取代**）              | **云原生、分布式系统、AI交互**                               |
| **核心特点**     | 简单、安全、低延迟。<br />但**无法**进行远程通信 | 浏览器原生支持，实现简单<br />**不支持**断线自动恢复 | **高灵活性、资源效率高、兼容性好**<br />支持按需流式传输和**断线重连** |



- 自此我们的MCP服务就配置完成了，启动就可以使用了

![MCP程序服务启动示例图](mcp1.png)



### 2、MCP客户端

客户端也有2个，一个是WebFlux Client和标准客户端，因为我们服务端使用的是SpringMVC，所以这里使用的是标准客户端

##### ①、导入依赖

```xml

<!-- MCP客户端 -->
<dependency>
    <groupId>org.springframework.ai</groupId>
    <artifactId>spring-ai-starter-mcp-client</artifactId>
</dependency>


<!-- AI请求，使用ollama -->
<dependency>
    <groupId>org.springframework.ai</groupId>
    <artifactId>spring-ai-starter-model-ollama</artifactId>
</dependency>

<!-- AI模型自动配置的 -->
<dependency>
    <groupId>org.springframework.ai</groupId>
    <artifactId>spring-ai-autoconfigure-model-chat-client</artifactId>
</dependency>

<!-- 正常MVC接口访问 -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
</dependency>
```





##### ②、更新配置文件

- 配置`application.yml` 如下

```yaml
server:
  port: 8102

spring:
  application:
    name: mcp-client-annotation
  ai:
    ollama:
      base-url: http://localhost:11434
      chat:
        options:
          model: llama3.2

    mcp:
      client:
        enabled: true
        type: SYNC
        initialized: false
        name: spring-ai-mcp-client-annotation
        root-change-notification: true
        request-timeout: 30s
        annotation-scanner:
          enabled: true
        toolcallback:
          enabled: true
#        sse:
#          connections:
#            fortuneServer:
#              url: http://localhost:8101
        streamable-http:
          connections:
            fortuneServer:
              url: http://127.0.0.1:8101


logging:
  level:
    root: info
    org.springframework.ai: debug
    io.modelcontextprotocol: debug
    top.lrshuai.ai: info

```



**配置要点说明：**

- ollama使用的模型是 `llama3.2`
- `spring.ai.mcp.client.annotation-scanner.enabled`是否启用客户端
- `spring.ai.mcp.client.toolcallback.enabled`启用/禁用 MCP 工具回调与 Spring AI 的工具执行框架的集成
- 其中`streamable-http.connections` 可以配置多个MCP服务，`fortuneServer` 是给MCP自定义一个名字，后面的url就是MCP服务地址了






##### ③、请求接口示例

- 为了方便演示，我们创建两个测试接口：一个是没有使用MCP的，一个是使用MCP的。

```java
@RequestMapping("/client")
@RestController
public class DemoController {

    private final ChatClient chatClient;
    private static final String DEFAULT_QUESTION="今日运势如何";

    @Resource
    private SyncMcpToolCallbackProvider toolCallbackProvider;

    public DemoController (OllamaChatModel chatModel) {

        this.chatClient = ChatClient.builder(chatModel)
                .defaultSystem("回答以下问题结果都用中文回答，如果你不知道答案，请只回复‘我不知道’")
                // 打印日志
                .defaultAdvisors(new SimpleLoggerAdvisor())
              .build();
    }

    /**
     * 普通 AI 对话接口
     */
    @GetMapping("/ask")
    public String ask(@RequestParam(defaultValue = DEFAULT_QUESTION) String question) {
        return chatClient
                .prompt(question)
                .call()
                .content();
    }

    /**
     * 工具增强的 AI 对话接口
     * 启用 MCP 工具回调，AI 可自动判断并调用相应工具
     */
    @GetMapping("/askByTool")
    public String askByTool(@RequestParam(defaultValue = DEFAULT_QUESTION) String question) {
        return chatClient
                .prompt(question)
                .toolCallbacks(toolCallbackProvider)
                .toolContext(Map.of("progressToken", "my-progress-token"))
                .call()
                .content();
    }

}
```

- 我们通过给ChatClient配置`toolCallbacks` ，AI模型会自己判断是否要调用MCP服务工具
- 其中`toolContext()`方法是为了配置上下文的，比如我们token，我们这里配置`progressToken`在服务端方法中：`@McpProgressToken String progressToken`就可以拿到这个token。



- 好了，准备工具就绪，我们可以通过请求接口，进行验证了，如下：


![不使用MCP的情况](mcp-http1.png)

- 当不启用 MCP 工具时，AI 模型基于自身知识回答，对于运势这类特定问题通常会回复"我不知道"。





![使用MCP的情况](mcp-http2.png)

- 启用 MCP 工具后，AI 模型自动识别到问题匹配可用的 `daily_fortune` 工具，调用我们的运势测算服务并返回详细结果。






## 三、总结

通过本文的实践，我们成功体验了 Spring AI 1.1.0-M3 中全新的 MCP 注解开发模式。这种声明式的编程方式带来了以下优势：

- **开发效率提升**：通过注解自动注册工具，减少样板代码
- **维护性增强**：工具定义与实现紧密关联，代码更易理解
- **灵活性提高**：支持多种通信协议和编程模型
- **集成简便**：与 Spring 生态无缝集成，配置简单直观

Spring AI 的 MCP 集成正在快速发展，虽然当前版本仍处于里程碑阶段，但已经展现出强大的生产就绪能力。随着正式版的发布，相信会有更多企业级特性和优化加入，为 AI 应用开发带来更多便利。




**资源获取：**
本文完整代码已上传至 GitHub，欢迎 Star ⭐ 和 Fork：
https://github.com/rstyro/spring-ai-demo



**支持与关注**：

如果觉得这篇文章对你有帮助，欢迎点赞、收藏和转发。同时，欢迎关注我的 GitHub 和博客，获取最新技术文章和项目更新。

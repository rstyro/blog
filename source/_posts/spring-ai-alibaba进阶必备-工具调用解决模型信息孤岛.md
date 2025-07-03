---
title: spring-ai-alibaba进阶必备:工具调用解决模型信息孤岛
tags: [AI]
description: 大模型(LLM)调用工具函数
categories: Java
date: 2025-07-03 13:37:39
updated: 2025-07-03 13:37:39
---


## 一、什么是工具函数

- **核心概念：** “工具调用”（Tool Calling）或“函数调用”（Function Calling）是一种强大的机制，允许大型语言模型（LLM）在推理过程中，根据上下文需求**声明调用**一个或多个开发者预定义的工具。
- **工具范围：** 工具可以是任何功能性组件，例如：执行网页搜索、调用外部 API、查询数据库、执行特定计算或访问系统信息（如获取当前时间）。
- **执行流程：**
    1.  **意图表达：** LLM **自身不直接执行工具**。当它判断需要调用工具时，会在响应中**结构化地表达调用特定工具的意图**（而非生成常规文本回复）。
    2.  **工具执行：** 应用程序负责**解析**模型的意图，**定位**并**执行**指定的工具。
    3.  **结果反馈：** 应用程序将**工具执行的结果**（成功或失败）反馈回给模型。
- **核心价值：** 通过工具调用，LLM 的能力边界得到显著扩展，能够完成超出其原生文本生成能力的任务（如获取实时数据、操作外部系统），极大提升了应用的实用性和灵活性。

<!--more-->

## 二、工具调用定义

Spring AI 提供了两种灵活的方式来定义和使用工具：**方法工具** 和 **函数工具**。以下以“获取当前城市天气信息”为例进行说明。


### 1、方法工具

这种方式直接在 Java 类的方法上声明工具。

-   **核心注解：**
    - `@Tool`: 标记在方法上，定义该方法为一个工具，提供工具描述。
    - `@ToolParam`: 标记在方法参数上，描述参数的作用。
-   **示例工具类 (`WeatherTool`):**

```java
/**
 * 天气方法工具
 */
public class WeatherTool {

    @Tool(description = "获取城市天气信息")
    public String getWeatherInfo(@ToolParam(description = "城市名称") String city) {
        // todo 请求具体的接口得到城市天气
        return String.format("%s 天气是多云转晴，温度38.9",city);
    }
}
```

- **集成与调用：**
    在创建或调用 `ChatClient` 时，将工具类的实例通过 `.tools()` 方法注册进去。也可以在构建 `ChatClient` 时通过 `.defaultTools()` 设置默认工具集。



```java
/**
 * 调用 方法工具
 */
@GetMapping("/askByTool")
public R askByTool(@RequestParam(value = "question", defaultValue = "深圳今天的天气怎样") String question) {
    /**
     * 在调用 ChatClient 时，通过 .tools() 方法传递工具对象，
     * 或者在实例化 ChatClient 对象的时候通过 .defalutTools() 方法传递工具对象
     */
    return R.ok(chatClient.prompt(question)
            // 方法工具调用
            .tools(new WeatherTool())
            .call().content());
}
```


- **使用已有类方法 (无需修改源码)：`MethodToolCallback`**
    如果你有一个现有的工具类，但不想或不能修改其源码添加注解，可以使用 `MethodToolCallback` 来包装它。
    - **现有工具类 (`WeatherTool`):** 添加一个方法：`geCityWeatherInfo`

```java
public class WeatherTool {

    public String geCityWeatherInfo(String city) {
        // todo 请求具体的接口得到城市天气
        return String.format("%s 天气是小雨多云，微风清爽",city);
    }
}
```

使用示例：

```java
/**
 * 调用 方法工具
 */
@GetMapping("/askByToolCallback")
public R askByToolCallback(@RequestParam(value = "question", defaultValue = "深圳今天的天气怎样") String question) {
    /**
     * 
     * 在调用 ChatClient 时，通过.toolCallbacks() 传递 MethodToolCallBack 对象，
     * 或者在实例化 ChatClient 对象的时候通过 .defalutToolCallBacks() 方法传递工具对象：
     */
    Method method = ReflectionUtils.findMethod(WeatherTool.class, "geCityWeatherInfo", String.class);
    // 可以使用 JsonSchemaGenerator.generateForMethodInput(method) 方法获取 Input Schema。
    String inputSchema = JsonSchemaGenerator.generateForMethodInput(method);
    MethodToolCallback toolCallback = MethodToolCallback.builder()
            .toolDefinition(ToolDefinition.builder()
                    .description("获取城市天气信息")
                    .name("geCityWeatherInfo")
                    .inputSchema(inputSchema)
                    .build())
            .toolMethod(method)
            .toolObject(new WeatherTool())
            .build();
    return R.ok(chatClient.prompt(question)
            // 方法工具调用
            .toolCallbacks(toolCallback)
            .call().content());
}
```



### 2、函数工具调用

- 开发者可以把任意实现 `Function` 接口的对象，定义为 `Bean` ，并通过 `.toolNames()` 或 `.defaultToolNames()` 传递给 ChatClient 对象。
- 例如有这么一个实现了`Function` 接口的类：

```java
public class WeatherFunction implements Function<WeatherFunction.WeatherRequest, String> {

    @Override
    public String apply(WeatherRequest weatherRequest) {
        System.out.println("cityName="+weatherRequest.getCityName());
        // todo 这里可以通过cityName 去请求真实的天气api
        return String.format("%s 天气是晴天",weatherRequest.getCityName());
    }

    @Data
    public static class WeatherRequest{
        private String cityName;
    }
}
```

- 将该类的对象定义为 Bean：

```
@Configuration
public class FunctionConfig {
    @Bean
    @Description("获取指定城市天气的信息")
    public Function<WeatherFunction.WeatherRequest, String> weatherFunction() {
        return new WeatherFunction();
    }
}
```

- 在调用 ChatClient 时，通过`.toolNames()` 传递函数工具的 Bean 名称，或者在实例化 ChatClient 对象的时候通过 `.defalutToolNames()` 方法传递函数工具：

```java
/**
 * 调用 函数工具
 */
@GetMapping("/askFunction")
public R askFunction(@RequestParam(value = "question", defaultValue = "深圳今天的天气怎样") String question) {
    /**
     * 在调用 ChatClient 时，通过.toolNames() 传递函数工具的 Bean 名称，
     * 或者在实例化 ChatClient 对象的时候通过 .defalutToolNames() 方法传递函数工具
     */
    return R.ok(chatClient.prompt(question).toolNames("weatherFunction").call().content());
}
```



### 3、返回值转换

- **作用：** 工具执行后返回的结果（通常是 Java 对象）需要转换成模型能够理解和处理的格式（通常是字符串）。`ToolCallResultConverter` 接口定义了这一转换过程。
- **默认行为：** Spring AI 默认使用 `DefaultToolCallResultConverter`。它利用 Jackson 库将工具返回的 Java 对象**序列化为 JSON 字符串**。
- **自定义转换：** 如果需要特殊的返回值格式（如 XML、HTML 片段、特定摘要等），可以实现 `ToolCallResultConverter` 接口。
- **指定自定义转换器：** 在 `@Tool` 注解的 `resultConverter` 属性中指定自定义转换器的类。

    ```java
    @Tool(description = "...", resultConverter = MyCustomConverter.class)
    public MyResultObject myToolMethod(...) { ... }
    ```



### 4、工具上下文

- **作用：** 提供一种机制，在执行工具时向其传递**额外的、动态的上下文信息**。这些信息**独立于模型请求中显式传递的参数**。
- **常见用途：** 传递当前用户身份 (ID, 角色)、会话 ID、安全令牌、环境变量、请求范围的数据等。
- **示例工具 (`UserInfoTools`):**

```java
public class UserInfoTools {
    @Tool(description = "get current user name")
    public String getUserName(ToolContext context) {
        String userId = context.getContext().get("userId").toString();
        if (!StringUtils.hasText(userId)) {
            return "null";
        }
        // 模拟数据
        return userId + "user";
    }
}
```

- **传递上下文：** 在调用 `ChatClient` 时，通过 `.toolContext()` 方法传入一个 `Map<String, Object>`。



```java
String response = chatClient.prompt("获取我的用户名")
    .tools(new UserInfoTools())
    .toolContext(Map.of("userId", "12345"))
    .call()
    .content();
```


## 三、总结

Spring AI Alibaba 的工具函数调用机制为 LLM 应用开发提供了强大的扩展能力。通过将外部功能（如 API 调用、数据查询、系统操作等）封装成工具，开发者可以显著突破模型本身的限制，实现更复杂、更动态、更贴近实际业务场景的智能交互。

**核心价值与优势：**

1.  **能力无限扩展：** 模型不再局限于自身知识库，能够调用任意预定义的工具获取实时信息（如天气、股票）或执行特定操作（如发送邮件、创建工单）。
2.  **开发灵活高效：**
    *   **方法工具 (`@Tool`, `@ToolParam`)**： 提供简洁的注解式声明，适合新建工具或能修改源码的类。
    *   **函数工具 (`Function` Bean)**： 遵循 Spring 生态标准，易于集成现有服务，支持清晰的输入结构定义。
    *   **`MethodToolCallback`**： 无需侵入源码即可复用已有类方法，提供最大灵活性。
3.  **上下文感知：** `ToolContext` 机制允许传递运行时信息（如用户身份、会话状态），使工具行为更具针对性和安全性。
4.  **结果可控：** 通过自定义 `ToolCallResultConverter`，开发者可以精细控制工具执行结果如何被格式化并反馈给模型，确保模型能正确理解。

**最佳实践建议：**

*   **清晰定义：** 为工具及其参数提供精确、简洁的 `description`，帮助模型准确理解何时以及如何使用该工具。
*   **职责单一：** 每个工具应聚焦于完成一个特定的、明确的任务。
*   **健壮性：** 工具实现中务必考虑错误处理（如网络异常、参数无效），并返回有意义的错误信息供模型处理。
*   **安全性：** 谨慎设计可被调用的工具，特别是涉及敏感操作或数据的工具。结合 `ToolContext` 进行权限校验至关重要。
*   **性能考量：** 工具执行通常是 I/O 操作（如网络请求），需注意其对应用整体响应时间的影响。

**展望：**

Spring AI Alibaba 的工具调用功能为构建真正“行动型”AI Agent 奠定了坚实基础。随着模型的持续进化和工具生态的丰富，开发者能够创造出更智能、更主动、更能解决实际问题的下一代 AI 应用。合理利用工具调用，是解锁 LLM 全部潜力的关键一步。


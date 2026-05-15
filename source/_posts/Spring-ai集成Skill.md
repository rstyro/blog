---
title: Spring-ai集成Skill
tags: [AI,Spring AI]
categories: AI
date: 2026-05-15 18:59:57
updated: 2026-05-15 18:59:57
---

# Spring-AI 集成 Skills

## 一、概述

现在一聊到 AI，无论是在地铁上还是和朋友闲谈，耳边总会飘过几个“洋词儿”，比如 RAG、Skill、MCP。这些词到底是什么意思，又有什么作用？我们这就来唠唠。

<!--more-->


### 1、什么是 RAG

RAG（Retrieval-Augmented Generation，检索增强生成）是一种将信息检索与文本生成相结合的技术范式。它的核心思想是：在生成回答之前，先从外部知识库中检索出与问题相关的文档或片段，然后将这些检索到的内容连同原始问题一起提供给语言模型，让模型基于“找到的上下文”生成更准确、更接地气的答案。

RAG 解决了大语言模型的两大天然缺陷：一是知识截止日期带来的信息陈旧问题，二是模型在缺乏背景知识时容易“幻觉”（编造事实）的问题。通过引入外部检索，模型可以回答训练数据之外的最新知识，并且答案可以溯源到具体的文档，大幅提升了可信度。典型实现中，RAG 系统会先将文档切割成块、向量化存入向量数据库，用户提问时执行相似度搜索，再把最相关的片段注入 prompt，形成“提问—检索—增强—生成”的流水线。

### 2、什么是 Function Calling（函数调用）

Function Calling（函数调用）是大语言模型与外部工具或 API 进行交互的标准化机制。其工作方式是：开发者预先定义一组函数（工具）及其参数 schema 并告知模型，当模型判断用户的意图适合使用某个工具时，它不会直接生成文本回答，而是返回一个结构化的“函数调用请求”，其中包含要调用的函数名和参数。应用程序收到这个请求后，在本地执行相应的函数，将结果返回给模型，模型再根据结果生成最终的自然语言回复。

Function Calling 让模型从“只会聊天”进化为“能干活”：它可以查询实时天气、操作数据库、发送邮件、控制智能家居等等。但它存在一个明显限制——模型在每次请求中都需要“看到”所有可用工具的定义。当工具数量膨胀到几十甚至上百个时，这些定义会占据大量上下文窗口，增加 token 消耗，并且模型在众多工具中做出正确选择的难度也会显著上升。

### 3、什么是 MCP

MCP（Model Context Protocol，模型上下文协议）是由 Anthropic 提出的一种开放标准，用于规范大模型与外部工具、数据源之间的通信方式。它定义了一套通用协议，让模型可以通过标准化的接口发现和调用远程工具，而无需每接入一个新工具都编写定制化的适配代码。

MCP 采用客户端-服务器架构，支持 STDIO 和 HTTP 两种传输方式。工具提供方实现一个 MCP Server，暴露工具列表及调用接口；模型端通过 MCP Client 动态发现这些工具并执行调用。MCP 的价值在于互操作性：一个 MCP 工具可以在不同模型、不同平台间复用，避免了供应商锁定。Spring AI 对 MCP 提供了良好支持，通过 `@Tool` 或 `@McpTool` 注解即可将本地 Bean 暴露为 MCP 工具，或调用远程 MCP 工具。

### 4、🔥什么是 Skills

Skills 是一种模块化的 AI 能力封装单位。每个 Skill 是一个独立的文件夹，内部至少包含一个 `SKILL.md` 文件，该文件使用 YAML 前置元数据（frontmatter）定义名称和描述，用 Markdown 正文承载具体的任务指令。Skill 还可以附带辅助脚本、参考文档和模板资源。

一个典型的 Skill 目录结构如下：

```
my-skill/
├── SKILL.md          # 必需：元数据 + 指令
├── scripts/          # 可选：可执行脚本
├── references/       # 可选：参考文档
└── assets/           # 可选：模板、资源文件
```

Skills 的本质是一套 **Tool 的组织与调度机制**，而不是某个单一的工具。它将完成某类任务所需的全部指令、流程、领域知识和执行脚本打包在一起，形成一个可被 Agent 按需发现和加载的“能力单元”。

#### 4.1 Skill 的由来

Skills 概念的萌芽可以追溯到 AI 编程工具（如 Claude Code、Cursor 等）中的“技能目录”设计。这些工具为高频任务（如代码审查、PDF 生成、自动化测试）预置了可复用的指令包，存储在工作区的 `.claude/skills/` 或类似目录下。开发者可以将重复性的提示词和脚本提炼为 Skill，在不同项目间共享。

随着这一实践的价值被社区广泛认可，Skills 模式开始向通用 AI 应用框架渗透。Spring AI 在 2026 年初的 Agentic Patterns 探索中正式引入了 Agent Skills 支持，将其从特定的开发者工具扩展为通用的智能体能力组织范式，使 Java 生态也能享受这种模块化能力复用的红利。

#### 4.2 Skill 解决了什么问题

Skills 主要解决传统 Function Calling 模式下的三大痛点：

**1. 工具膨胀与上下文污染**
Function Calling 要求每次请求都将全部工具定义放入上下文。当系统能力从几十个函数增长到上百个时，token 消耗线性增加，且无关工具的信息会严重干扰模型的决策。Skills 通过“渐进式披露”从根本上解决了这个问题——模型启动时仅加载所有 Skill 的名称和描述（每个仅几十 token），只有在判定某个 Skill 与当前任务匹配后，才将完整指令加载进上下文。

**2. 团队协作冲突**
在大型项目中，多个团队共同维护一套全局工具列表极易产生冲突和耦合。Skills 以独立的文件夹和文件作为分发单元，各团队可以独立开发、测试、版本控制自己的 Skill 包，最后通过目录聚合到一起，实现了真正的模块化隔离。

**3. 能力可复用性差**
传统的 Function Calling 工具通常与特定业务逻辑强绑定，换一个项目或模型就需要重新适配。Skills 采用纯文本的 Markdown 指令加可选脚本的形式，天然具备跨平台、跨模型的可移植性，定义一次即可在多种 LLM 上使用。

### 5、什么是 Agent

Agent（智能体）是指具备自主感知、规划、决策与执行能力，能够使用工具完成复杂任务的 AI 系统。与简单的“问答机器人”不同，Agent 的核心特征在于能够动态分解任务、选择并调用合适的工具、根据中间结果调整下一步行动，并在多次迭代中逼近最终目标。

在技术实现上，Agent 通常由大语言模型充当“大脑”，通过 Function Calling 或 MCP 等机制接入多种工具，以 ReAct（推理+行动）或 Plan-and-Execute 等模式循环执行。引入 Skills 后，Agent 又多了一种更高层级的任务组织方式：它不再逐个调用零散的工具函数，而是将整个任务委派给一个 Skill，由 Skill 内部的指令和脚本自行完成子任务的编排与执行。这使得 Agent 的“思考”粒度从原子工具提升到了能力单元，在面对复杂需求时更加从容。

### 6、RAG与Skills 、MCP、Agent的关系与区别

RAG、MCP、Skills 以及 Agent 都是扩展大模型能力的关键技术，在实际应用中经常协同工作。

**四者的核心定位**

- **RAG 是“知识注入层”**：通过外部检索为模型补充领域知识，解决信息过时和幻觉问题。
- **MCP 是“工具通信层”**：定义模型与外部服务之间的标准化调用协议，解决工具接入的互操作性问题。
- **Skills 是“能力组织层”**：将复杂任务拆解为可复用的能力单元，解决工具膨胀与上下文管理问题。
- **Agent 是“智能决策层”**：实现自主规划、工具调度与多步执行，是前三者的集成宿主和运行框架。



它们之间不是替代关系，而是互补关系。一个完整的 Agent 系统可以同时使用三者：Skills 定义“该做什么、怎么做”，MCP 打通“调用外部工具的通道”，RAG 提供“最新的领域知识”。当 Skill 需要调用外部 API 时，可以通过 MCP 工具完成；当 Skill 需要参考业务规则文档时，可以在 `references/` 下放置文件并借助 RAG 检索。



一句话概括：**Agent 是核心指挥官，它使用 RAG 来获取知识，使用 Function Calling 或 Skills 来执行具体动作，而 MCP 则为这些工具提供了标准化的连接方式**。




## 二、Spring-AI 集成 Skill

Spring AI 是Java集成大模型比较火的框架，比较大部分项目都是spring全家桶。但是spring ai官方目前并没有集成skill的能力（后期应该会添加得等一下），但是我们可以集成社区版的`spring-ai-agent-utils`模块提供了对 Agent Skills 的开箱支持。该模块将 Skills 实现为一种特殊的 Tool，借助渐进式披露机制，让任何支持 Function Calling 的 LLM（OpenAI、Anthropic、Google Gemini 等）都可以按需发现和加载 Skill，实现“一次定义，多模型使用”。

下面以 Spring Boot 项目为例，展示从依赖配置到 Skill 定义、注册、调用的完整流程。

### 1. 添加依赖

在 `pom.xml` 中引入 `spring-ai-agent-utils` 和所需的模型 starter（以 deepseek 为例）：

```xml
<dependency>
    <groupId>org.springframework.ai</groupId>
    <artifactId>spring-ai-agent-utils</artifactId>
    <version>0.7.0</version>
</dependency>

<dependency>
    <groupId>org.springframework.ai</groupId>
    <artifactId>spring-ai-starter-model-deepseek</artifactId>
</dependency>
```

### 2. 配置 Skill 目录

在 `application.yml` 中指定 Skill 存放路径，支持 classpath 和文件系统路径混合使用：

```yaml
agent:
  skillsPath: classpath:/skills/
```

### 3. 编写 Skill

在 `src/main/resources/skills/` 下创建 Skill 文件夹，例如一个代码审查的 `code-reviewer` Skill：

```
skills/
└── code-reviewer/
    ├── SKILL.md
    └── scripts/
        └── init_scripts.py
```

`SKILL.md` 文件内容：

```yaml
---
name: code-reviewer
description: 代码审查助手，帮助审查Java/Spring代码，检查潜在问题、代码质量、安全性和最佳实践。当用户请求代码审查、代码优化建议时触发。
allowed-tools: Read, Grep, Bash
---

# 代码审查助手

## 概述
作为代码审查助手，我将帮助你审查Java/Spring代码，识别潜在问题、代码质量问题、安全漏洞和最佳实践违规。

## 审查维度
1. **代码质量**: 检查代码复杂度、重复代码、命名规范
2. **安全性**: 检查SQL注入、XSS攻击、敏感信息泄露
3. **性能**: 检查潜在的性能瓶颈
4. **最佳实践**: 检查是否遵循Spring和Java最佳实践
5. **可维护性**: 检查代码结构、注释和文档

## 审查步骤
1. 分析用户提供的代码或代码路径
2. 识别潜在问题并分类
3. 提供具体的改进建议
4. 给出优化后的代码示例

## 示例
用户: "帮我审查这个Controller代码"
助手: "请提供代码或文件路径，我将为你进行全面的代码审查。"

```

YAML 前置元数据中的 `name` 和 `description` 用于发现阶段的语义匹配；Markdown 正文将在 Skill 被激活时完整加载给模型，指导具体执行。



### 4. 注册工具 Bean

将 Skills 相关的工具注册为 Spring Bean，并挂载到 `ChatClient` 上。`SkillsTool` 是核心工具，负责发现和加载 Skill；`ShellTools` 和 `FileSystemTools` 是可选的，分别用于执行附带脚本和读取参考文件。

```java
@Slf4j
@Data
@ConfigurationProperties(prefix = "agent")
@Configuration
public class SkillConfig {

    // 我们配置的skill路径
    private String skillsPath;

    @Resource
    private ResourceLoader resourceLoader;

    @Bean
    public ChatClient chatClient(ChatClient.Builder chatClientBuilder) {
        ChatClient chatClient = chatClientBuilder
                // 配置默认的工具调用回调：SkillsTool，用于加载并执行技能（SKILL.md）
                .defaultToolCallbacks(SkillsTool.builder()
                        .addSkillsResource(resourceLoader.getResource(skillsPath))
                        .build())
                // 注册默认工具：文件系统操作工具（读写文件、列出目录等）
                .defaultTools(FileSystemTools.builder().build())
                // 注册默认工具：Shell 命令执行工具（允许执行系统命令）
                .defaultTools(ShellTools.builder().build())
                .defaultAdvisors(
                        // 工具调用顾问：管理工具调用的上下文，需要添加这个才会调用skill
                        ToolCallAdvisor.builder()
                                .conversationHistoryEnabled(false)// 禁用历史记录，不然和MessageChatMemoryAdvisor一起用会报错
                                .advisorOrder(Ordered.HIGHEST_PRECEDENCE + 999)
                                .build(),
                        // 消息聊天记忆顾问：使用滑动窗口内存，保留最近 500 条消息以维持上下文
                        MessageChatMemoryAdvisor.builder(MessageWindowChatMemory.builder().maxMessages(500).build())
                                .conversationId(MessageWindowChatMemory.CONVERSATION_ID)
                                .order(Ordered.HIGHEST_PRECEDENCE + 1000)
                                .build(),
                        // 技能日志顾问：自定义的日志记录增强器，用于记录技能调用详情
                        SkillLoggingAdvisor.builder().order(Ordered.HIGHEST_PRECEDENCE + 3000).build()
                )
                .build();

        return chatClient;
    }

}
```

### 5. 调用执行流程

注册完成后，整个调用链路如下：

1. **发现阶段**：`SkillsTool` 在初始化时扫描配置路径下的所有 Skill，提取 `name` 和 `description`，将其嵌入自身工具描述的上下文中。当 `ChatClient` 向 LLM 发送请求时，LLM 会看到 `SkillsTool` 及其提供的 Skill 列表（仅名称与描述）。
2. **激活阶段**：当用户提出请求（例如 "帮我审查这段 Java 代码的潜在问题"），LLM 判断该意图与 `code-reviewer` 的描述高度匹配，于是返回一个调用 `SkillsTool` 的工具请求，参数为 `skillName="code-reviewer"`。`SkillsTool` 收到调用后，从磁盘加载完整的 `SKILL.md` 内容并返回给 LLM。
3. **执行阶段**：LLM 阅读 Skill 指令，按步骤执行。通过 `FileSystemTools` 读取代码文件，结合自身推理能力进行全面审查，生成最终的审查报告返回给用户。

整个过程对用户完全透明。无论系统注册了多少 Skill，每次请求的初始上下文只包含轻量级的 Skill 列表，完全消除了工具膨胀带来的 token 浪费和模型选择压力。

### 6. 与 MCP 工具协同

当 Skill 需要调用外部服务时，可以直接使用通过 MCP 暴露的远程工具。Spring AI 允许将 MCP 工具也注册到 `ChatClient` 的默认工具列表中，与 `SkillsTool` 共存：

```java
@Bean
public ChatClient chatClient(ChatModel chatModel,
                             SkillsTool skillsTool,
                             List<McpToolCallback> mcpTools) {
    return ChatClient.builder(chatModel)
            .defaultTools(skillsTool)
            .defaultTools(mcpTools.toArray(new McpToolCallback[0]))
            .build();
}
```

这样 Skill 的指令中就可以自然地引用 MCP 工具，实现“本地脚本 + 远程服务”的混合编排，赋予 Agent 更强大的能力边界。


### 7、测试接口

```java
@Slf4j
@RestController
@RequestMapping("/api/skills")
public class SkillDemoController {

    private static final String DEFAULT_SYSTEM_PROMPT = "你是一位博学多识，专业严谨，幽默风趣，热爱生活的智能助手";
    private static final String DEFAULT_USER_PROMPT = "你夸夸我";
    private static final String EMPTY_PROMPT_MSG = "Prompt 不能为空";

    @Resource
    private ChatClient chatClient;

    @GetMapping(value = "/client/chat", produces = MediaType.APPLICATION_JSON_VALUE)
    public R<String> clientChat(
            @RequestParam(defaultValue = DEFAULT_SYSTEM_PROMPT) String system,
            @RequestParam(defaultValue = DEFAULT_USER_PROMPT) String prompt,
            @RequestParam(defaultValue = "1")String userId) {
        
        validatePrompt(prompt);
        
        try {
            String response = chatClient.prompt(prompt)
//                    .system(system)
                    // 添加会话用户id
                    .advisors(advisorSpec -> advisorSpec.param(ChatMemory.CONVERSATION_ID,userId))
                    .call()
                    .content();
            
            log.info("Client chat completed successfully. Prompt length: {}, Response length: {}", 
                    prompt.length(), 
                    response != null ? response.length() : 0);
            
            return R.ok(response);
            
        } catch (Exception e) {
            log.error("Client chat failed: {}", e.getMessage(), e);
            return R.fail("对话失败: " + e.getMessage());
        }
    }

    @GetMapping(value = "/client/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public Flux<String> clientStream(
            @RequestParam(defaultValue = DEFAULT_SYSTEM_PROMPT) String system,
            @RequestParam(defaultValue = DEFAULT_USER_PROMPT) String prompt,
            @RequestParam(defaultValue = "1")String userId) {
        
        validatePrompt(prompt);
        
        return chatClient.prompt(prompt)
                .system(system)
                .advisors(advisorSpec -> advisorSpec.param(ChatMemory.CONVERSATION_ID,userId))
                .stream()
                .content()
                .doOnError(e -> log.error("Client stream error: {}", e.getMessage(), e));
    }

    private void validatePrompt(String prompt) {
        if (prompt == null || prompt.trim().isEmpty()) {
            throw new IllegalArgumentException(EMPTY_PROMPT_MSG);
        }
    }
}

```



![测试/api/skills/client/chat接口](test1.png)

![控制台skill日志打印](log.png)



## 三、结尾



从 RAG 到 MCP，从 Function Calling 到 Skills，AI 能力扩展的技术栈日趋完善，但真正的工程挑战从未改变：**如何让模型在能力膨胀的同时，依然保持简洁与可控**。

Skills 给出的答案是“渐进式披露”——先让模型看目录，再按需加载详情。这一机制在上下文效率与能力丰富度之间找到了最佳平衡点。Spring AI 将其无缝融入 Java 生态，让开发者用熟悉的依赖注入与配置管理，即可构建模块化的智能体。

展望未来，Skill 将进化为“子 Agent”，形成递归的能力树。但眼下，我们更应关注落地：

1. **高频场景优先** – 2~3 个 Skill 起步，感受渐进式披露的收益。
2. **描述重于文档** – 精准的 `description` 比堆砌参考文件更关键。
3. **警惕上下文膨胀** – Skill 正文过长会反向拖累效率。
4. **三方协同** – Skills + MCP + RAG 才是完整解法。

AI 应用开发的范式瞬息万变，但好架构的原则永恒：**做更多事时，依然简洁**。Skills 践行了这一点。愿文章为你的 Spring AI 智能体之路，提供一份清晰、可落地的技术参考。


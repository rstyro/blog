---
title: Midscene.js零基础入门完全指南-UI自动化
tags: [Midscene.js,自动化测试,Playwright]
categories: 工具
date: 2026-05-13 15:52:24
updated: 2026-05-13 15:52:24
---


## 一、传统 UI 自动化的

作为一名前端开发或者测试工程师，你一定经历过这些场景——

辛辛苦苦写了几百行测试脚本，前端同学一个 DOM 结构调整，几十个用例集体飘红。定位元素全靠 `.header > nav > ul > li:nth-child(2) > a` 这种意大利面式的选择器，不但写着难受，改起来更是让人头皮发麻。调试的时候更崩溃：脚本失败了，只有一行冷冰冰的报错信息，你根本不知道当时页面上到底是什么样子。



这就是传统 UI 自动化的三大痛点：**选择器脆弱**（页面一改就挂）、**维护成本高**（动态内容处理复杂）、**调试体验差**（缺乏可视化回放）。



有没有一种方式，能让我们**用自然语言描述想做什么**，然后交给 AI 去理解页面、找到元素、执行操作？

<!--more-->


这就是 **Midscene.js** 要做的事。




## 二、Midscene.js 是什么？

**Midscene.js 是字节跳动 Web Infra 团队开源的 AI 驱动 UI 自动化框架**，核心理念非常朴素：用自然语言描述操作意图，由 AI 来理解页面并执行操作，而不是让你写一堆 CSS 选择器。

简单来说——**让 AI 成为你的浏览器操作助手**。只需用日常语言描述你想做的事情，它就会帮你操作网页、验证内容、提取数据。

它发布于 2024 年，采用 MIT 许可证开源，目前在 GitHub 上已斩获超过 1 万 Star。



### 2.1 它能做什么？

- **用自然语言写自动化脚本**：描述你的目标和步骤，Midscene 会帮你规划和操作用户界面。
- **跨平台**：支持 Web（集成 Puppeteer / Playwright）、Android（通过 adb）、iOS（通过 WebDriverAgent）、PC 桌面应用，甚至 IoT 设备和车载显示器等任意界面。
- **三种核心 API**：交互 API（操作界面）、数据提取 API（提取结构化数据）、实用 API（断言、定位、等待等）。
- **可视化报告与调试**：每次运行后生成可视化报告，包含动画回放和步骤详情。
- **MCP 支持**：Midscene 提供 MCP 服务，将 Agent 的原子操作暴露为 MCP 工具，上层 AI Agent 可以用自然语言直接检查和操作界面。



### 2.2 为什么它不一样？

Midscene.js 从 v1.0 开始，全面采用了**纯视觉**（pure-vision）技术路线——元素定位和交互**只基于截图完成**，不再依赖 DOM 信息。

这样做的好处非常直观：

- **效果稳定**：视觉模型（如 `Doubao-Seed-1.6-Vision`、`Qwen3.x`）在 UI 操作规划和组件定位上表现稳定，能适应 UI 布局的微调；
- **适用于任意系统**：不管是 Android、iOS、桌面应用，还是浏览器里的 Canvas 标签，只要能获取截图，Midscene 就能完成交互操作；
- **Token 消耗大幅下降**：相比 DOM 方案，视觉方案的 token 使用量最多可以减少 80%，成本更低、运行更快；



当然，在数据提取和页面理解场景中，Midscene 仍支持按需附带 DOM 信息，兼顾灵活性。






## 三、3分钟快速体验

你不需要搭建任何代码项目，最快只需 3 分钟就能体验 Midscene 的核心能力。

### 方式一：Chrome 插件

1. 前往 [Chrome 扩展商店](https://chromewebstore.google.com/detail/midscene/gbldofcpkknbggpkmbdaefngejllnief) 安装 Midscene 扩展。

> https://chromewebstore.google.com/detail/midscene/gbldofcpkknbggpkmbdaefngejllnief



![](chrome.png)


2. 启动扩展，你会看到浏览器右侧出现一个名为 “Midscene” 的侧边栏。
3. 在侧边栏中配置 AI 模型服务：

```bash
MIDSCENE_MODEL_BASE_URL="https://替换为你的模型服务地址/v1"
MIDSCENE_MODEL_API_KEY="替换为你的 API Key"
MIDSCENE_MODEL_NAME="替换为你的模型名称"
MIDSCENE_MODEL_FAMILY="替换为你的模型系列"
```

![](baidu1.png)



4. 配置完成后，你就能看到四个核心操作 Tab：

| Tab | 对应方法 | 说明 |
|---|---|---|
| **Action** | `aiAct` | 自动规划并与页面交互。例如：`填写完整的注册表单，注意让所有字段通过校验` |
| **Query** | `aiQuery` | 从界面提取 JSON 数据。例如：`提取页面中的用户 ID，返回 { id: string } 结构` |
| **Assert** | `aiAssert` | 对页面状态进行断言。例如：`页面上存在一个登录按钮，下方有一个用户协议链接` |
| **Tap** | `aiTap` | 即时点击某个元素。例如：`点击登录按钮` |

Act 是“自动规划”，AI 会自己思考需要分几步、按什么顺序来完成任务；Tap 是“即时操作”，你明确告诉 AI 点哪里，它就只执行那一步。复杂流程用 Act，精准操作用 Tap。



![](baidu2.png)



## 四、集成到代码项目

体验完零代码模式之后，我们进入正题：如何把 Midscene 集成到你的代码项目中。

### 4.1 环境准备

**系统要求**：Node.js 20 或更高版本。

**平台依赖**：

- **macOS**：首次运行时需要授予辅助功能权限，前往 `系统设置 > 隐私与安全性 > 辅助功能`，为 Terminal / iTerm2 / VS Code 等应用启用权限。
- **Linux**：需要安装 ImageMagick 用于截图功能；在无头 CI 环境（如 GitHub Actions）中还需安装 Xvfb 来创建虚拟显示器。

**安装依赖**（以最常见的方式为例）：

```bash
# 与 Playwright 集成（推荐）
npm install @midscene/web playwright --save-dev

# 与 Puppeteer 集成
npm install @midscene/web puppeteer --save-dev

# PC 桌面自动化
npm install @midscene/computer --save-dev
```

### 4.2 配置 AI 模型

Midscene 需要连接 AI 视觉模型来驱动作业。推荐通过环境变量配置，下面是系统环境变量：

```bash
export MIDSCENE_MODEL_BASE_URL="https://api.openai.com/v1"
export MIDSCENE_MODEL_API_KEY="sk-xxxxxxxxxxxxxxxx"
export MIDSCENE_MODEL_NAME="gpt-4o"
export MIDSCENE_MODEL_FAMILY="openai"
```

**模型选择建议**：Midscene 官方推荐的模型包括豆包 Seed、千问 Qwen3.x、智谱 GLM-V、智谱 AutoGLM、Gemini-3-Flash 等。如果刚开始接触，建议先用最容易获得的模型，之后再根据实际效果做横向对比。



### 4.3 用 YAML 写自动化脚本（最简单）

如果你不想写代码，Midscene 支持用 YAML 格式描述自动化流程，零 JavaScript 知识也能搞定：

**1. 安装 CLI**

```bash
npm i -g @midscene/cli  # 全局安装
# 或项目中安装
npm i @midscene/cli --save-dev
```

**2. 编写 YAML 脚本**

```yaml
# demo.yaml —— 一个搜索天气的示例
web:
  url: https://www.bing.com
  viewportWidth: 1280
  viewportHeight: 960

# tasks 部分定义了要执行的一系列步骤
tasks:
  - name: 搜索天气
    flow:
      - ai: 搜索 "今日天气"
      - sleep: 3000
      - aiAssert: 结果显示天气信息
      # 执行一个查询，返回一个 JSON 对象
      - aiQuery: >
          提取天气的相关信息,返回{city:string,description:string}
          提取城市，和相关天气信息最高位，最低温等基础数据
        name: weatherResult
```

**3. 运行脚本**

```bash
# 需要全局安装配置环境才有
midscene ./demo.yaml
# 或者项目中执行
npx midscene ./demo.yaml
```

YAML 脚本的完整配置项非常丰富——你可以设置浏览器 UA、视口大小、Cookie 文件路径、网络空闲等待策略、输出结果文件路径等。YAML 文件不仅可读性强，还能与 JavaScript 灵活集成，适合构建复杂的测试逻辑。



### 4.4 与 Playwright 集成（最常用）

Playwright 是 2026 年端到端测试领域采用率最高的框架，Midscene 与它原生配合使用体验最好。

**安装**

```bash
npm install @midscene/web playwright --save-dev
npx playwright install  # 安装浏览器驱动
```

**基础示例**

```javascript
import { chromium } from 'playwright';
import { PlaywrightAgent } from '@midscene/web/playwright';

(async () => {
  // 启动浏览器
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();
  const agent = new PlaywrightAgent(page);

  // 打开页面
  await page.goto('https://github.com/login');

  // 用自然语言完成登录
  await agent.aiAct('输入用户名 "testuser" 和密码 "testpass"，然后点击登录按钮');

  // 用自然语言做断言
  await agent.aiAssert('页面显示了用户头像或 Dashboard 界面');

  // 提取数据
  const repos = await agent.aiQuery(
    '返回 {name: string, stars: number}[]，找到仓库列表中的仓库名称和 Star 数'
  );
  console.log('我的仓库：', repos);

  await browser.close();
})();
```

Midscene 跟 Playwright 的集成非常深入。PlaywrightAgent 在构造时会自动接管 Playwright 的 Page 对象，并默认启用 `forceSameTabNavigation`（强制新标签页重定向到当前页，避免多窗口带来的不确定性）。你还可以通过 `waitForNetworkIdle` 让 Agent 在每次 AI 动作前等待网络空闲，确保页面渲染完毕。

另外，`PlaywrightAiFixture` 让 Midscene 可以直接嵌入 Playwright 的 test runner，`MidsceneReporter` 则是专门的 Playwright reporter 插件，生成可视化报告。

```javascript
// 使用 PlaywrightAiFixture 在测试用例中集成 Midscene
import { test } from '@playwright/test';
import { PlaywrightAiFixture } from '@midscene/web/playwright';

const aiTest = test.extend(PlaywrightAiFixture());

aiTest('用户能够成功搜索商品', async ({ page, aiAct, aiAssert, aiQuery }) => {
  await page.goto('https://example-shop.com');

  await aiAct('在搜索框输入"无线耳机"，点击搜索按钮');
  await aiAssert('搜索结果列表中至少展示了 3 件商品');

  const productInfo = await aiQuery(
    '返回 {name: string, price: number}[]，提取第一页所有商品的名称和价格'
  );
  console.log('搜索结果：', productInfo);
});
```

对于需要精准点击的场景，可以使用即时操作 API：

```javascript
// 自动规划 —— AI 自己决定步骤
await agent.aiAct('在购物车中，把商品数量改为 3，然后点击结算');

// 即时操作 —— 精确描述目标
await agent.aiTap('购物车页面底部的"去结算"按钮（红色背景）');
```

关于自动规划（Auto Planning）和即时操作（Instant Action）的区别：自动规划适合那些需要 AI 自己判断步骤顺序的复杂任务；即时操作则适合你已经清楚知道要操作哪个元素的场景，执行更快也更准确。

### 4.5 与 Puppeteer 集成

如果你更习惯用 Puppeteer，集成方式几乎一模一样：

```bash
npm install @midscene/web puppeteer --save-dev
```

```javascript
import puppeteer from 'puppeteer';
import { PuppeteerAgent } from '@midscene/web/puppeteer';

(async () => {
  const browser = await puppeteer.launch({ headless: false });
  const page = await browser.newPage();
  const agent = new PuppeteerAgent(page);

  await page.goto('https://www.example.com');
  await agent.aiAct('在搜索框中输入 "hello world" 并搜索');
  await agent.aiAssert('搜索结果已显示');

  await browser.close();
})();
```

### 4.6 PC 桌面自动化

Midscene 还支持控制整个桌面应用，不仅仅是浏览器。这对于自动化办公软件、本地应用、车机大屏等场景非常实用。

```bash
npm install @midscene/computer
```

```javascript
import { agentFromComputer } from '@midscene/computer';

const agent = await agentFromComputer();

await agent.aiAct('打开系统设置，找到"关于本机"信息');

const systemInfo = await agent.aiQuery(
  '返回 {os: string, version: string}，提取操作系统名称和版本号'
);
console.log('系统信息：', systemInfo);
```

macOS 用户首次运行需要授予辅助功能权限。Linux 无头环境需安装 Xvfb 创建虚拟显示器，传入 `headless: true` 选项即可。






## 五、核心 API 详解

Midscene 的 API 分为三大类：交互 API、数据提取 API 和实用 API。

### 5.1 交互 API：操控界面

| 方法 | 说明 | 示例 |
|---|---|---|
| `aiAct(prompt)` | 自动规划并完成一系列操作 | `'填写注册表单，注意让所有字段通过校验'` |
| `aiTap(prompt)` | 精确点击某个元素（即时操作） | `'页面顶部的"登录"按钮'` |
| `aiInput(prompt, { value })` | 定位输入框并填入内容 | `'搜索框', { value: 'Midscene' }` |
| `aiScroll(prompt, direction)` | 滚动到某个区域 | `'滚动到页面底部'` |
| `aiAction(prompt)` | 通用交互方法（旧版别名） | 与 `aiAct` 类似 |

**关键概念：自动规划 vs 即时操作**

- **自动规划（aiAct）** ：AI 自己分析任务、拆解步骤、按序执行。适合复杂流程。
- **即时操作（aiTap / aiInput）** ：你明确告诉 AI 操作哪个元素，它直接定位并执行。适合你已经知道目标在哪里的场景。

### 5.2 数据提取 API：获取结构化数据

| 方法 | 说明 |
|---|---|
| `aiQuery(prompt)` | 提取 JSON 结构数据 |
| `aiBoolean(prompt)` | 提取布尔值结果 |
| `aiNumber(prompt)` | 提取数字结果 |
| `aiString(prompt)` | 提取字符串结果 |

```javascript
// 提取结构化数据
const products = await agent.aiQuery(
  '{title: string, price: number, stock: number}[], 提取商品列表中的标题、价格和库存'
);
// 返回: [{ title: '无线耳机', price: 299, stock: 120 }, ...]

// 提取简单值
const isLoggedIn = await agent.aiBoolean('当前页面是否显示已登录状态？');
const total = await agent.aiNumber('页面中购物车角标上显示的数字是多少？');
const pageTitle = await agent.aiString('当前页面的主标题是什么？');
```

这些方法在底层对 AI 响应做了格式化约束。比如 `aiQuery` 会指定返回 JSON Schema，`aiBoolean` 只接受 `true` 或 `false`，`aiNumber` 只接受数字。这样你在代码里拿到的一定是已经解析好的、类型安全的结果。

### 5.3 实用 API：断言、定位与等待

| 方法 | 说明 |
|---|---|
| `aiAssert(prompt)` | 验证页面或应用状态 |
| `aiLocate(prompt)` | 定位元素坐标 |
| `aiWaitFor(prompt)` | 等待某个状态出现 |

```javascript
// 断言 —— 最重要也最常用的 API
await agent.aiAssert('登录成功提示已经显示，页面自动跳转到了首页');
await agent.aiAssert('购物车图标上显示商品数量为 3');

// 定位
const rect = await agent.aiLocate('页面中红色的"提交订单"按钮');
console.log('按钮位置：', rect); // { left, top, width, height }

// 等待
await agent.aiWaitFor('商品列表加载完成，显示了至少 5 个商品卡片');
```



## 六、调试与可视化报告

Midscene 每次运行后都会自动生成一个**可视化报告文件**，这是它区别于传统工具的杀手级功能。

**报告包含什么？**

- **动画回放**：一步步回放脚本的执行过程，每步都附带截图
- **步骤详情**：每个操作的详情、AI 的思考和规划过程
- **Token 消耗统计**：按模型汇总 Token 消耗量，分析不同场景的成本
- **内置 Playground**：在报告中重新运行 Prompt 并调试，无需回到代码环境



在 Agent 构造函数中，可以通过 `generateReport`、`reportFileName`、`outputFormat` 等选项控制报告行为：

```javascript
const agent = new PlaywrightAgent(page, {
  generateReport: true,
  reportFileName: 'my-test-report',
  outputFormat: 'single-html',       // 默认：截图内嵌在单个 HTML 文件中
  // outputFormat: 'html-and-external-assets', // 截图存为独立文件，适合报告过大的场景
});
```

**outputFormat 的选择**：`single-html`（默认）将所有截图作为 base64 内嵌到一个 HTML 文件中，方便分享和归档。如果页面很多、报告体积过大，可以切换为 `html-and-external-assets`，把截图存成独立 PNG 文件——但注意这种方式不能直接用 `file://` 协议打开，需要通过 HTTP 服务器访问。





## 七、进阶：MCP 服务、缓存与多模型组合



### 7.1 MCP 服务

Midscene 提供 MCP（Model Context Protocol）服务，将 Agent 的原子操作暴露为 MCP 工具。这意味着上层 AI Agent（如 Claude Desktop、Cursor、CodeBuddy 等）可以用自然语言直接检查和操作界面。

这对于构建 AI-Native 的开发工作流尤其关键——比如你可以让 Claude 直接操控浏览器帮你做测试、填表单、搜集数据。





### 7.2 使用缓存提高执行效率

Midscene 支持缓存机制，避免重复执行相同的步骤时反复调用 AI：

```javascript
const agent = new PlaywrightAgent(page, {
  cacheId: 'my-test-cache',  // 启用缓存并指定 cacheId
});

await agent.aiAct('执行一些复杂操作...'); // 首次执行，调用 AI
// 再次运行相同脚本时，缓存命中，跳过 AI 调用
```

这在持续集成环境中特别有用——同样的测试用例每天跑，缓存能大幅降低模型调用成本。



### 7.3 多模型组合

从 v1.0 开始，Midscene 支持为不同意图配置不同模型。比如用能力更强的模型做规划，用性价比更高的模型做元素定位：

- **Planning（规划）意图**：负责整体任务规划
- **Insight（洞察）意图**：负责页面理解和数据提取
- **默认交互**：负责元素定位和操作执行

这种多模型组合策略让开发者可以按需平衡效果与成本——规划能力强一点的模型可以稍贵，占大头的元素定位可以用更经济的模型。

```javascript
// 多模型配置示例（环境变量方式）
export MIDSCENE_MODEL_NAME="doubao-seed-1.6-vision"          // 默认模型
export MIDSCENE_PLANNING_MODEL_NAME="gpt-4o"                 // 规划模型
```





## 八、实战案例

- 如上基本需要提前编写代码并固化到项目中，灵活性不足
- 我现在就想服务启动，脚本可以通过接口动态传入然后返回结果，不用把脚本固定写到项目里



### 1、使用pnpm初始化项目

```bash
# 创建项目目录
mkdir midscene-demo
cd midscene-demo

# 初始化package.json
pnpm init

# 安装express 与环境变量dotenv
pnpm add dotenv express

# 安装midscene.js 依赖,并集成playwright
# cross-env设置不同环境变量的，nodemon开发环境修改代码自动重启
pnpm add -D @midscene/web playwright @playwright/test cross-env nodemon 


# 3. 安装 Playwright 浏览器驱动（首次执行）
npx playwright install chromium
```

### 2、配置环境变量

- 新建`.env` 文件里面配置你的模型设置相关的环境变量

```bash
# 服务端口
PORT=3000

# 可选：浏览器是否 headless（生产环境建议 true，开发时可 false 看到界面）
HEADLESS=false


# 默认视觉模型
MIDSCENE_MODEL_BASE_URL="https://ark.cn-beijing.volces.com/api/coding/v3"
MIDSCENE_MODEL_API_KEY="ark-df2d3152-...."
MIDSCENE_MODEL_NAME="doubao-seed-2.0-pro"
MIDSCENE_MODEL_FAMILY="doubao-seed"
MIDSCENE_MODEL_REASONING_ENABLED="false"


# 下面的模型配置可不设置，如果想要不同阶段不同的模型可设置
# 负责任务规划（aiAct / ai 里的 Planning）
MIDSCENE_PLANNING_MODEL_BASE_URL="https://dashscope.aliyuncs.com/compatible-mode/v1"
MIDSCENE_PLANNING_MODEL_API_KEY="......"
MIDSCENE_PLANNING_MODEL_NAME="qwen3.5-plus"
MIDSCENE_PLANNING_MODEL_FAMILY="qwen3.5"

# 负责数据提取、断言与页面理解（aiQuery / aiAsk / aiAssert 等）
MIDSCENE_INSIGHT_MODEL_BASE_URL="https://ark.cn-beijing.volces.com/api/coding/v3"
MIDSCENE_INSIGHT_MODEL_API_KEY="ark-df2d3152-...."
MIDSCENE_INSIGHT_MODEL_NAME="doubao-seed-2.0-lite"
MIDSCENE_INSIGHT_MODEL_FAMILY="doubao-seed"
```

### 3、创建沙箱工具类

- 安全执行动态脚本，隔离全局环境，避免恶意代码或变量污染

```js
// 沙箱 sandbox.js - 使用 Node.js 内置 vm 模块，支持传递 page/agent 等复杂对象
const vm = require('vm');

class IsolatedSandbox {
  constructor(options = {}) {
    this.options = {
      timeout: options.timeout || 60000, // 默认60秒
    };
    this.context = null;
  }

  async init() {
    if (this.context) return;
    // 创建基础上下文，注入常用的全局工具
    const sandbox = {
      console: {
        log: (...args) => console.log('[Sandbox]', ...args),
        error: (...args) => console.error('[Sandbox]', ...args),
        warn: (...args) => console.warn('[Sandbox]', ...args),
        info: (...args) => console.info('[Sandbox]', ...args),
      },
      setTimeout: setTimeout,
      clearTimeout: clearTimeout,
      setInterval: setInterval,
      clearInterval: clearInterval,
      Buffer: Buffer,
      // 注意：不提供 require 和 process，保持基本安全
    };
    // 冻结 console 方法避免被篡改
    Object.freeze(sandbox.console);
    this.context = vm.createContext(sandbox);
  }

  /**
   * 注入外部 API 到沙箱全局对象中
   * @param {Object} apiMap 键值对，例如 { page, agent, __addStep }
   */
  async injectAPI(apiMap) {
    await this.init();
    for (const [key, value] of Object.entries(apiMap)) {
      this.context[key] = value;
    }
  }

  /**
   * 执行脚本
   * @param {string} scriptContent - 脚本代码字符串
   * @param {Object} contextParams - 额外的全局参数（会被注入）
   * @returns {Promise<{success: boolean, result?: any, error?: string, duration?: number}>}
   */
  async execute(scriptContent, contextParams = {}) {
    await this.init();
    const startTime = Date.now();

    // 合并参数到上下文
    for (const [key, value] of Object.entries(contextParams)) {
      this.context[key] = value;
    }

    // 包装脚本为 async 函数，方便捕获 return 值
    // 注意：用户脚本可以直接使用 await，并且最后返回的值会被捕获
    const wrappedScript = `(async () => { ${scriptContent} })()`;

    try {
      const script = new vm.Script(wrappedScript, {
        timeout: this.options.timeout,
        displayErrors: true,
      });
      const result = await script.runInContext(this.context);
      return {
        success: true,
        result,
        duration: Date.now() - startTime,
      };
    } catch (err) {
      console.error('Sandbox execution error:', err);
      return {
        success: false,
        error: err.message,
        stack: err.stack,
        duration: Date.now() - startTime,
      };
    }
  }

  async dispose() {
    // 释放上下文（gc 会回收）
    this.context = null;
  }
}

module.exports = IsolatedSandbox;
```

### 4、执行脚本的执行器

```js
// scriptExecutor.js

const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const IsolatedSandbox = require('../utils/sandbox');
const ReportManager = require('../utils/reportManager');

class ScriptExecutor {
  constructor() {
    this.reportManager = new ReportManager();
    this.tempDir = path.join(__dirname, '../../temp');
    this.ensureDirs();
    this.activeTasks = new Map();
  }

  ensureDirs() {
    if (!fs.existsSync(this.tempDir)) {
      fs.mkdirSync(this.tempDir, { recursive: true });
    }
  }

  /**
   * 执行动态脚本内容
   * @param {string} scriptContent - JavaScript 代码（支持 async/await）
   * @param {Object} injections - 注入到沙箱的全局对象，通常包含 page, agent 等
   * @param {Object} params - 普通参数对象，可通过全局变量 params 访问
   */
  async executeDynamicScript(scriptContent, injections = {}, params = {}) {
    const taskId = uuidv4();
    
    const report = {
      taskId,
      startTime: new Date().toISOString(),
      endTime: null,
      duration: null,
      status: 'running',
      steps: [],
      params,
      scriptType: 'dynamic'
    };

    this.activeTasks.set(taskId, {
      status: 'running',
      startTime: Date.now()
    });

    const stepLogs = [];
    const addStep = (stepName, status, details = {}) => {
      const step = {
        stepName,
        status,
        timestamp: new Date().toISOString(),
        ...details
      };
      stepLogs.push(step);
      report.steps.push(step);
      console.log(`[${taskId}] [${status.toUpperCase()}] ${stepName}`,details || '无');
    };

    let sandbox = null;
    try {
      console.log(`[${taskId}] 开始执行动态脚本`);

      // 1. 创建并初始化沙箱
      sandbox = new IsolatedSandbox({ memoryLimit: 512 });
      await sandbox.init();

      // 2. 注入步骤记录函数和工具
      const sandboxAPI = {
        __addStep: (stepName, status, details) => {
          addStep(stepName, status, details);
        },
        __log: (...args) => console.log(`[${taskId}]`, ...args),
        __error: (...args) => console.error(`[${taskId}]`, ...args),
      };
      await sandbox.injectAPI(sandboxAPI);

      // 3. 注入外部需要的浏览器对象（page, agent 等）
      if (injections && Object.keys(injections).length > 0) {
        await sandbox.injectAPI(injections);
      }

      addStep('初始化沙箱环境', 'success');

      // 4. 准备全局参数（将以普通变量形式存在于脚本中）
      const globalParams = {
        taskId,
        params,
      };

      addStep('编译并执行脚本', 'success');
      // console.log(`scriptContent=`, scriptContent);

      // 5. 执行脚本
      const result = await sandbox.execute(scriptContent, globalParams);
      console.log("result=",result)
      if (result.success) {
        addStep('脚本执行完成', 'success', { duration: result.duration });
        report.status = 'completed';
        report.result = result.result;
        report.duration = result.duration + 'ms';
        console.log(`[${taskId}] 脚本执行成功，耗时: ${result.duration}ms`);
      } else {
        addStep('脚本执行失败', 'failed', { error: result.error });
        report.status = 'failed';
        report.error = result.error;
        report.duration = result.duration + 'ms';
        console.error(`[${taskId}] 脚本执行失败: ${result.error}`);
      }

    } catch (error) {
      report.status = 'failed';
      report.error = error.message;
      report.steps.push({
        stepName: '异常捕获',
        status: 'failed',
        timestamp: new Date().toISOString(),
        error: error.message
      });
      console.error(`[${taskId}] 执行异常: ${error.message}`);
    } finally {
      report.endTime = new Date().toISOString();
      if (!report.duration) {
        const ms = (new Date(report.endTime) - new Date(report.startTime));
        report.duration = ms + 'ms';
      }

      // 保存报告
      await this.reportManager.saveReport(taskId, report);
      this.activeTasks.delete(taskId);

      // 清理沙箱资源
      if (sandbox) {
        await sandbox.dispose();
      }
    }

    return report;
  }

  /**
   * 执行存储的脚本文件
   * @param {string} scriptPath - 脚本文件路径
   * @param {Object} injections - 注入到沙箱的对象
   * @param {Object} params - 普通参数
   */
  async executeStoredScript(scriptPath, injections = {}, params = {}) {
    const taskId = uuidv4();
    
    const report = {
      taskId,
      startTime: new Date().toISOString(),
      endTime: null,
      duration: null,
      status: 'running',
      steps: [],
      params,
      scriptType: 'stored',
      scriptPath
    };

    this.activeTasks.set(taskId, {
      status: 'running',
      startTime: Date.now()
    });

    try {
      if (!fs.existsSync(scriptPath)) {
        throw new Error(`脚本文件不存在: ${scriptPath}`);
      }

      const scriptContent = fs.readFileSync(scriptPath, 'utf8');
      return await this.executeDynamicScript(scriptContent, injections, params);

    } catch (error) {
      report.status = 'failed';
      report.error = error.message;
      report.endTime = new Date().toISOString();
      const ms = (new Date(report.endTime) - new Date(report.startTime));
      report.duration = ms + 'ms';

      await this.reportManager.saveReport(taskId, report);
      this.activeTasks.delete(taskId);
      
      return report;
    }
  }

  getActiveTasks() {
    const tasks = [];
    for (const [taskId, info] of this.activeTasks.entries()) {
      tasks.push({
        taskId,
        status: info.status,
        runningTime: (Date.now() - info.startTime) / 1000 + '秒'
      });
    }
    return tasks;
  }

  async shutdown() {
    // 如果有全局的 sandbox 资源需要清理，但这里每个任务独立创建，无需额外清理
    console.log('ScriptExecutor shutdown complete');
  }
}

module.exports = ScriptExecutor;
```

- 提供2个方法，一个是传入脚本文件路径，一个直接是脚本内容，进行执行
- 内置几个方法，如：`__addStep` 给报告添加每个步骤的执行结果和日志，帮忙排查

### 5、Playwright工具类

- 保证每个请求的浏览器上下文完全隔离，避免 Cookie/缓存/页面状态污染

```js
// browserManager.js
const { chromium } = require('playwright');
const { PlaywrightAgent } = require('@midscene/web/playwright');

class BrowserManager {
    constructor() {
        this.browser = null;
        this.initializing = false;
    }

    async getBrowser() {
        if (this.initializing) {
            await new Promise(resolve => setTimeout(resolve, 100));
            return this.getBrowser();
        }
        if (!this.browser) {
            this.initializing = true;
            try {
                await this.initBrowser();
            } finally {
                this.initializing = false;
            }
        }
        return this.browser;
    }

    async initBrowser() {
        console.log('🚀 启动浏览器...');
        this.browser = await chromium.launch({
            headless: process.env.HEADLESS !== 'false',
            args: ['--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage'],
        });
        console.log('✅ 浏览器初始化完成');
    }

    /**
     * 为每个请求创建独立的 page 和 agent
     */
    async createIsolatedPage() {
        const browser = await this.getBrowser();
        // 创建独立的浏览器上下文（完全隔离 cookies、localStorage 等）
        const context = await browser.newContext();
        const page = await context.newPage();
        const agent = new PlaywrightAgent(page);
        return { page, agent, context };
    }

    /**
     * 清理一个请求的 page 和 context
     */
    async closePageContext(context, page) {
        if (page) await page.close().catch(e => console.warn('关闭 page 失败', e));
        if (context) await context.close().catch(e => console.warn('关闭 context 失败', e));
    }

    async cleanup() {
        if (this.browser) {
            await this.browser.close();
            console.log('✅ 浏览器已关闭');
        }
    }
}

module.exports = new BrowserManager();
```

### 6、应用示例

- 提供 HTTP 接口，接收脚本执行请求并返回结果

```js
const express = require('express');
const ScriptExecutor = require('../services/scriptExecutor');
const ReportManager = require('../utils/reportManager');
const browserManager = require('../utils/browserManager');

const router = express.Router();
const executor = new ScriptExecutor();
const reportManager = new ReportManager();


router.post('/execute', async (req, res) => {
  let pageContext = null;
  try {
    const { scriptContent, params } = req.body;

    if (!scriptContent) {
      return res.status(400).json({ 
        success: false, 
        error: 'scriptContent 不能为空' 
      });
    }
    const { page, agent, context } = await browserManager.createIsolatedPage();
    pageContext = { page, agent, context };
    const report = await executor.executeDynamicScript(scriptContent, { page, agent },params || {});
    res.json(report);
    
  } catch (error) {
    console.error('执行动态脚本异常:', error);
    res.status(500).json({ 
      success: false, 
      error: error.message 
    });
  }finally {
    // 无论成功失败，释放此请求的 page 和 context
    if (pageContext) {
      await browserManager.closePageContext(pageContext.context, pageContext.page);
    }
  }
});

router.post('/execute/stored', async (req, res) => {
  let pageContext = null;
  try {
    const { scriptPath, params } = req.body;
    
    if (!scriptPath) {
      return res.status(400).json({ 
        success: false, 
        error: 'scriptPath 不能为空' 
      });
    }
    const { page, agent, context } = await browserManager.createIsolatedPage();
    pageContext = { page, agent, context };
    const report = await executor.executeStoredScript(scriptPath, { page, agent },params || {});
    res.json(report);
    
  } catch (error) {
    console.error('执行存储脚本异常:', error);
    res.status(500).json({ 
      success: false, 
      error: error.message 
    });
  }finally {
    // 无论成功失败，释放此请求的 page 和 context
    if (pageContext) {
      await browserManager.closePageContext(pageContext.context, pageContext.page);
    }
  }
});

router.get('/reports/:taskId', (req, res) => {
  const { taskId } = req.params;
  
  if (!taskId) {
    return res.status(400).json({ 
      success: false, 
      error: 'taskId 不能为空' 
    });
  }

  const report = reportManager.getReport(taskId);
  
  if (report) {
    res.json(report);
  } else {
    res.status(404).json({ 
      success: false, 
      error: '报告未找到' 
    });
  }
});

router.get('/reports', (req, res) => {
  const reports = reportManager.listReports();
  res.json({ 
    success: true, 
    reports 
  });
});

router.delete('/reports/:taskId', (req, res) => {
  const { taskId } = req.params;
  
  if (!taskId) {
    return res.status(400).json({ 
      success: false, 
      error: 'taskId 不能为空' 
    });
  }

  const deleted = reportManager.deleteReport(taskId);
  
  if (deleted) {
    res.json({ 
      success: true, 
      message: '报告已删除' 
    });
  } else {
    res.status(404).json({ 
      success: false, 
      error: '报告未找到' 
    });
  }
});

// 查询活跃任务
router.get('/tasks/active', (req, res) => {
  const activeTasks = executor.getActiveTasks();
  res.json({ 
    success: true, 
    activeTasks 
  });
});

// 健康检查
router.get('/health', (req, res) => {
  res.json({ 
    success: true,
    status: 'ok', 
    timestamp: new Date().toISOString(),
    activeTasks: executor.getActiveTasks().length
  });
});

module.exports = router;
```

- 暴露几个接口用于执行动态脚本和查询报告的

### 7、 项目目录结构
```
midscene-demo/
├── .env                # 环境变量
├── package.json        # 依赖配置
├── server.js              # 服务入口
├── routes/
│   └── scriptRouter.js # 脚本执行接口路由
├── services/
│   └── scriptExecutor.js # 脚本执行核心服务
├── utils/
│   ├── sandbox.js      # 脚本执行沙箱
│   ├── browserManager.js # 浏览器上下文管理
│   └── reportManager.js  # 执行报告管理
├── temp/               # 临时报告存储目录
└── scripts/            # 可选：存储静态脚本文件
```


- **完整的项目代码在Github中，刚兴趣的评论区回复：代码**







## 九、原理解析：Midscene 是怎么工作的？

Midscene 的运行流程可以概括为四个步骤：

1. **截图捕获** → `page.screenshot()` 获取当前视口的图像
2. **DOM 提取** → 在数据提取场景中，同时抓取可访问性树（Accessibility Tree），提供双重上下文
3. **模型推理** → 截图 + 操作意图发送给视觉大模型，模型理解页面内容、规划操作路径、定位目标元素
4. **坐标反推与执行** → 模型识别出的目标位置被转换为可执行的 locator，交给 Playwright / Puppeteer 执行真实的点击或输入操作

**为什么纯视觉方案更优？**

传统基于 DOM 的方案有几个致命问题：Canvas 元素、CSS background-image 绘制的控件、跨域 iframe 中的内容、没有辅助标注的元素，都会导致定位偏差。这些异常往往让开发者投入大量时间去排查和修复。

而纯视觉方案直接“看”页面截图，完全不受 DOM 结构影响。只要人类肉眼能看到的元素，AI 就能操作——这才是真正接近人类操作方式的做法。同时，去掉 DOM 信息后 Token 量最多可减少 80%，成本更低、速度更快。



## 十、总结


### 1、Midscene.js vs Browser Use：选哪个？

在 AI 驱动 UI 自动化领域，Midscene.js 和 Browser Use 是两个最受关注的工具。两者核心对比：

| 维度 | Midscene.js | Browser Use |
|---|---|---|
| 技术路线 | 纯视觉（截图） | 基于文本模型 + DOM |
| 适用场景 | 可视化的用例生成、跨端自动化、部署在用户机器上 | 云端自动化测试、代码生成丰富的场景 |
| 生态系统 | Chrome 插件 + 可视化报告 + MCP | 开箱即用的浏览器自动化能力 |
| 语言支持 | JavaScript / YAML | Python |

简单来说：如果你是前端工程师或用 JavaScript 技术栈、需要跨平台（尤其是移动端）能力、看重可视化调试体验——选 Midscene.js。如果你是 Python 技术栈、专注于云端自动化任务——选 Browser Use。





Midscene.js 正在重塑 UI 自动化的方式。它用一个全新的思路解决了传统 UI 自动化最痛的三个问题：**选择器脆弱性**、**高维护成本**和**跨平台困难**。



*如果这篇文章对你有帮助，欢迎点赞、在看、转发，也欢迎在评论区分享你的 Midscene.js 使用体验和踩坑心得！*
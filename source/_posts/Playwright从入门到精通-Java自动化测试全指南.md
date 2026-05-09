---
title: Playwright从入门到精通 Java自动化测试全指南
tags: [自动化测试,Playwright]
categories: Java
date: 2026-05-09 13:41:05
updated: 2026-05-09 13:41:05
---

## 目录

- [一、Playwright 简介与优势](# 一-Playwright 简介与优势)
- [二、 环境搭建与安装](# 二-环境搭建与安装)
- [三、基础入门](# 三、基础入门)
- [四、核心功能](# 四、核心功能)
- [五、高级用法](# 五、高级用法)
- [六、常见问题与解决方案](# 六、常见问题与解决方案)
- [七、总结](# 七、总结)

---

## 一. Playwright 简介与优势

### 1.1 什么是 Playwright

**Playwright** 是Microsoft（微软）推出的一款现代化的自动化测试框架，支持 Chromium、Firefox 和 WebKit 三大浏览器引擎，并提供 TypeScript/JavaScript、Python、Java、.NET快速的端到端测试能力，适用于 Web 应用测试、爬虫开发和自动化任务。

### 1.2 核心优势

- **多浏览器支持**：一套代码在 Chromium、Firefox、WebKit 上运行
- **多语言支持**：支持 TypeScript、JavaScript、Python、.NET、Java
- **自动等待机制**：智能等待元素可操作，无需手动添加 sleep
- **强大的选择器**：支持文本、CSS、XPath、自定义选择器
- **网络拦截**：可以模拟、修改、阻止网络请求
- **并行执行**：支持测试并行运行，提高效率
- **丰富的调试工具**：Trace Viewer、Codegen、Inspector
- **移动端模拟**：支持移动设备视口和触摸事件模拟


<!--more-->


### 1.3 Playwright vs Selenium vs Cypress 对比

| 特性 | Playwright | Selenium | Cypress |
|------|-----------|----------|---------|
| 跨浏览器 | Chromium, Firefox, WebKit | 所有主流浏览器 | Chromium, Firefox (实验性) |
| 语言支持 | JS/TS, Python, Java, .NET | Java, Python, JS, C#, Ruby | JS/TS |
| 自动等待 | ✅ 内置 | ❌ 需手动配置 | ✅ 内置 |
| 执行速度 | 快 | 中等 | 快 |
| 网络拦截 | ✅ 强大 | ⚠️ 有限 | ✅ 强大 |
| 多标签页 | ✅ 支持 | ✅ 支持 | ❌ 不支持 |
| 学习曲线 | 中等 | 陡峭 | 平缓 |

---

## 二、 环境搭建与安装

### 2.1 系统要求

- **JDK 版本**: JDK 8 或更高（推荐 JDK 11\+）

- **构建工具**: Maven 或 Gradle

- **操作系统**: Windows、macOS、Linux

### 2.2 Maven 依赖配置

在 `pom.xml` 中添加 Playwright 依赖：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.example</groupId>
    <artifactId>playwright-demo</artifactId>
    <version>1.0-SNAPSHOT</version>

    <properties>
        <maven.compiler.source>11</maven.compiler.source>
        <maven.compiler.target>11</maven.compiler.target>
        <playwright.version>1.59.0</playwright.version>
        <junit.version>5.10.0</junit.version>
    </properties>

    <dependencies>
        <!-- Playwright 核心依赖 -->
        <dependency>
            <groupId>com.microsoft.playwright</groupId>
            <artifactId>playwright</artifactId>
            <version>${playwright.version}</version>
        </dependency>

        <!-- JUnit 5 测试框架 -->
        <dependency>
            <groupId>org.junit.jupiter</groupId>
            <artifactId>junit-jupiter-api</artifactId>
            <version>${junit.version}</version>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.junit.jupiter</groupId>
            <artifactId>junit-jupiter-engine</artifactId>
            <version>${junit.version}</version>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-surefire-plugin</artifactId>
                <version>3.2.2</version>
            </plugin>
        </plugins>
    </build>
</project>
```

### 2.3 Gradle 依赖配置

在 `build.gradle` 中配置：

```groovy
plugins {
    id 'java'
}

group = 'com.example'
version = '1.0-SNAPSHOT'

repositories {
    mavenCentral()
}

dependencies {
    // Playwright 核心依赖
    implementation 'com.microsoft.playwright:playwright:1.59.0'
    
    // JUnit 5
    testImplementation 'org.junit.jupiter:junit-jupiter-api:5.10.0'
    testRuntimeOnly 'org.junit.jupiter:junit-jupiter-engine:5.10.0'
}

test {
    useJUnitPlatform()
}
```

### 2.4 浏览器安装

**首次运行时，Playwright 会自动下载浏览器二进制文件**，无需手动安装。也可以手动执行安装命令：

```bash
# Maven 项目
mvn exec:java -e -D exec.mainClass=com.microsoft.playwright.CLI -D exec.args="install"

# Gradle 项目
./gradlew run --args="install"
```

安装指定浏览器：

```bash
# 仅安装 Chromium
mvn exec:java -e -D exec.mainClass=com.microsoft.playwright.CLI -D exec.args="install chromium"

# 安装系统依赖（Linux）
mvn exec:java -e -D exec.mainClass=com.microsoft.playwright.CLI -D exec.args="install-deps"
```

### 2.5 第一个 Playwright 程序

```java
import com.microsoft.playwright.*;

public class FirstPlaywright {
    public static void main(String[] args) {
        // 1. 创建 Playwright 实例（使用 try-with-resources 自动关闭）
        try (Playwright playwright = Playwright.create()) {
            
            // 2. 启动浏览器（Chromium/Firefox/WebKit 三选一）
            Browser browser = playwright.chromium().launch(
                new BrowserType.LaunchOptions()
                    .setHeadless(false)  // 有头模式，可看到浏览器
                    .setSlowMo(100)      // 减慢操作速度，便于观察
            );
            
            // 3. 创建新页面
            Page page = browser.newPage();
            
            // 4. 导航到目标网址
            page.navigate("https://www.example.com");
            
            // 5. 获取页面信息
            System.out.println("页面标题: " + page.title());
            System.out.println("当前URL: " + page.url());
            
            // 6. 截图保存
            page.screenshot(new Page.ScreenshotOptions()
                .setPath(java.nio.file.Paths.get("example.png"))
                .setFullPage(true));
            
            // 7. 关闭浏览器
            browser.close();
            
            System.out.println("执行完成！");
        }
    }
}
```

---

## 三、基础入门

### 3.1 核心对象模型

Playwright Java 的核心对象层级：

```Plain Text
Playwright
└── Browser (浏览器实例)
    └── BrowserContext (浏览器上下文，隔离环境)
        └── Page (页面/标签页)
            └── Locator (元素定位器)
```

### 3.2 浏览器启动配置

#### 3.2.1 启动不同浏览器

```java
import com.microsoft.playwright.*;

public class BrowserLaunchExample {
    public static void main(String[] args) {
        try (Playwright playwright = Playwright.create()) {
            
            // 启动 Chromium (Chrome/Edge)
            Browser chromium = playwright.chromium().launch(
                new BrowserType.LaunchOptions().setHeadless(false)
            );
            
            // 启动 Firefox
            Browser firefox = playwright.firefox().launch(
                new BrowserType.LaunchOptions().setHeadless(false)
            );
            
            // 启动 WebKit (Safari)
            Browser webkit = playwright.webkit().launch(
                new BrowserType.LaunchOptions().setHeadless(false)
            );
            
            System.out.println("Chromium 版本: " + chromium.version());
            System.out.println("Firefox 版本: " + firefox.version());
            System.out.println("WebKit 版本: " + webkit.version());
            
            chromium.close();
            firefox.close();
            webkit.close();
        }
    }
}
```

#### 3.2.2 高级启动选项

```java
Browser browser = playwright.chromium().launch(
    new BrowserType.LaunchOptions()
        .setHeadless(false)                    // 有头模式
        .setSlowMo(50)                         // 每个操作延迟50ms
        .setTimeout(60000)                     // 启动超时60秒
        .setArgs(java.util.Arrays.asList(      // 浏览器启动参数
            "--start-maximized",               // 窗口最大化
            "--disable-blink-features=AutomationControlled"  // 隐藏自动化特征
        ))
        .setChannel("chrome")                  // 使用系统安装的 Chrome
        // .setChannel("msedge")               // 使用系统安装的 Edge
        .setDevtools(true)                     // 自动打开开发者工具
);
```

### 3.3 BrowserContext 浏览器上下文

**BrowserContext 提供了独立的浏览器会话环境**，每个上下文有独立的 Cookie、LocalStorage、缓存。

```java
// 创建独立的浏览器上下文
BrowserContext context1 = browser.newContext();
BrowserContext context2 = browser.newContext();

// 每个上下文创建独立的页面
Page page1 = context1.newPage();
Page page2 = context2.newPage();

// 两个页面完全隔离，Cookie 不共享
page1.navigate("https://example.com");
page2.navigate("https://example.com");
```

#### 上下文配置选项

```java
BrowserContext context = browser.newContext(
    new Browser.NewContextOptions()
        .setViewportSize(1920, 1080)          // 视口大小
        .setUserAgent("Custom User Agent")    // 自定义 User-Agent
        .setLocale("zh-CN")                   // 语言设置
        .setTimezoneId("Asia/Shanghai")       // 时区
        .setPermissions(java.util.Arrays.asList(  // 授权权限
            "geolocation", "notifications"
        ))
        .setGeolocation(31.2304, 121.4737)    // 地理位置（上海）
        .setAcceptDownloads(true)              // 允许下载
        .setIgnoreHTTPSErrors(true)            // 忽略 HTTPS 错误
);
```

### 3.4 页面导航

```java
import com.microsoft.playwright.*;

public class NavigationExample {
    public static void main(String[] args) {
        try (Playwright playwright = Playwright.create()) {
            Browser browser = playwright.chromium().launch(
                new BrowserType.LaunchOptions().setHeadless(false)
            );
            Page page = browser.newPage();
            
            // 1. 基础导航
            page.navigate("https://www.example.com");
            
            // 2. 带超时的导航
            page.navigate("https://www.example.com", 
                new Page.NavigateOptions()
                    .setTimeout(30000)  // 30秒超时
                    .setWaitUntil(WaitUntilState.NETWORKIDLE)  // 等待网络空闲
            );
            
            // 3. 页面刷新
            page.reload();
            
            // 4. 后退/前进
            page.goBack();
            page.goForward();
            
            // 5. 等待页面加载状态
            page.waitForLoadState(LoadState.DOMCONTENTLOADED);  // DOM加载完成
            page.waitForLoadState(LoadState.LOAD);              // 页面完全加载
            page.waitForLoadState(LoadState.NETWORKIDLE);       // 网络空闲
            
            browser.close();
        }
    }
}
```

### 3.5 元素定位（Locator）

**Locator 是 Playwright 的核心概念**，代表随时可以重新查找元素的定位器，支持自动等待。

#### 3.5.1 推荐定位方式（按优先级）

```java
// 1. 通过角色定位（最推荐，符合无障碍标准）
page.getByRole(AriaRole.BUTTON, 
    new Page.GetByRoleOptions().setName("提交"));

// 2. 通过文本定位
page.getByText("登录");
page.getByText("欢迎", new Page.GetByTextOptions().setExact(true));  // 精确匹配

// 3. 通过标签文本定位（表单输入）
page.getByLabel("用户名");
page.getByLabel("密码");

// 4. 通过占位符定位
page.getByPlaceholder("请输入邮箱");

// 5. 通过 alt 文本定位（图片）
page.getByAltText("产品图片");

// 6. 通过 title 属性定位
page.getByTitle("点击查看详情");

// 7. 通过测试 ID 定位（最稳定）
page.getByTestId("submit-button");
```

#### 3.5.2 CSS 和 XPath 定位

```java
// CSS 选择器
page.locator("#username");                    // ID
page.locator(".btn-primary");                 // Class
page.locator("button[type='submit']");        // 属性
page.locator("div > span");                   // 层级

// XPath 选择器
page.locator("//button[text()='提交']");
page.locator("//input[@name='username']");

// 链式定位
page.locator(".form-container")
    .locator("input")
    .first();  // 第一个匹配元素
```

#### 3.5.3 定位器过滤

```java
// 过滤包含特定文本的元素
page.locator("li")
    .filter(new Locator.FilterOptions().setHasText("苹果"))
    .click();

// 过滤包含子元素的元素
page.locator("div.product-card")
    .filter(new Locator.FilterOptions()
        .setHas(page.locator(".out-of-stock")))
    .click();

// 组合过滤
page.locator("tr")
    .filter(new Locator.FilterOptions().setHasText("John"))
    .filter(new Locator.FilterOptions()
        .setHas(page.locator(".status-active")));
```

### 3.6 元素交互操作

#### 3.6.1 基础交互

```java
Locator button = page.getByRole(AriaRole.BUTTON, 
    new Page.GetByRoleOptions().setName("提交"));
Locator input = page.getByLabel("用户名");

// 点击
button.click();
button.click(new Locator.ClickOptions()
    .setTimeout(5000)           // 超时时间
    .setForce(true)             // 强制点击（跳过可操作性检查）
    .setClickCount(2)           // 双击
    .setButton(MouseButton.RIGHT)  // 右键点击
);

// 双击
button.dblclick();

// 右键点击
button.click(new Locator.ClickOptions()
    .setButton(MouseButton.RIGHT));

// 输入文本
input.fill("hello@example.com");

// 清空输入
input.clear();

// 按下按键
input.press("Enter");
input.press("Control+A");  // 全选
input.press("Backspace");
```

#### 3.6.2 复选框和单选框

```java
Locator checkbox = page.getByLabel("我同意服务条款");
Locator radio = page.getByLabel("男");

// 勾选复选框
checkbox.check();

// 取消勾选
checkbox.uncheck();

// 选择单选框
radio.check();

// 判断是否选中
System.out.println("是否选中: " + checkbox.isChecked());
```

#### 3.6.3 下拉选择框

```java
Locator select = page.locator("select#city");

// 按值选择
select.selectOption("shanghai");

// 按标签选择
select.selectOption(new SelectOption().setLabel("上海"));

// 按索引选择
select.selectOption(new SelectOption().setIndex(2));

// 多选
select.selectOption(new String[]{"beijing", "shanghai", "guangzhou"});
```

#### 3.6.4 悬停和拖拽

```java
// 悬停
page.locator(".menu-item").hover();

// 拖拽
Locator source = page.locator("#item-to-drag");
Locator target = page.locator("#drop-zone");

source.dragTo(target);

// 自定义拖拽
source.hover();
page.mouse().down();
target.hover();
page.mouse().up();


// 精确控制滑动（鼠标方式）
page.mouse().move(100, 100);
page.mouse().down();
page.mouse().move(300, 300);
page.mouse().up();
```

---

## 四、核心功能

### 4.1 等待机制

#### 4.1.1 自动等待（推荐）

Playwright 在执行操作前会自动进行**可操作性检查**：

- 元素是否可见

- 元素是否启用

- 元素是否在视口内

- 元素是否未被遮挡

- 元素是否可接收事件

```java
// ✅ 自动等待，无需手动等待
page.getByRole(AriaRole.BUTTON).click();
page.getByLabel("用户名").fill("test");

// ❌ 不需要这样写
// Thread.sleep(3000);  // 禁止使用！
// page.waitForSelector("#button");  // 通常不需要
```

#### 4.1.2 显式等待

```java
Locator locator = page.locator(".loading");

// 等待元素出现
locator.waitFor();

// 等待元素消失
locator.waitFor(new Locator.WaitForOptions()
    .setState(WaitForSelectorState.HIDDEN));

// 等待元素从 DOM 移除
locator.waitFor(new Locator.WaitForOptions()
    .setState(WaitForSelectorState.DETACHED));

// 自定义超时
locator.waitFor(new Locator.WaitForOptions()
    .setTimeout(10000));  // 10秒
```

#### 4.1.3 条件等待

```java
// 等待 URL 变化
page.waitForURL("**/dashboard");
page.waitForURL(url -> url.contains("success"));

// 等待标题变化
page.waitForTitle("登录成功");
page.waitForTitle(title -> title.startsWith("欢迎"));

// 等待自定义条件
page.waitForFunction("() => document.readyState === 'complete'");

// 等待响应
page.waitForResponse("**/api/user");
```

### 4.2 断言（Assertions）

Playwright 提供了专门的断言 API，支持自动等待。

#### 4.2.1 基础断言

```java
import static com.microsoft.playwright.assertions.PlaywrightAssertions.assertThat;

// 元素可见性断言
assertThat(page.locator(".success-message")).isVisible();
assertThat(page.locator(".error")).isHidden();

// 文本断言
assertThat(page.locator("h1")).hasText("欢迎使用");
assertThat(page.locator(".items")).containsText("商品A");

// 属性断言
assertThat(page.locator("input")).hasValue("test@example.com");
assertThat(page.locator("button")).hasAttribute("disabled", "true");
assertThat(page.locator(".active")).hasClass("btn btn-primary active");

// 状态断言
assertThat(page.locator("input")).isEnabled();
assertThat(page.locator(".checkbox")).isChecked();
assertThat(page.locator("button")).isDisabled();

// 数量断言
assertThat(page.locator(".list-item")).hasCount(5);
```

#### 4.2.2 页面断言

```java
// URL 断言
assertThat(page).hasURL("https://example.com/dashboard");
assertThat(page).hasURL(url -> url.contains("login"));

// 标题断言
assertThat(page).hasTitle("首页");

// 截图对比断言（视觉回归测试）
assertThat(page).hasScreenshot("homepage.png");
```

#### 

### 4.3 截图功能

```java
// 基础截图
page.screenshot(new Page.ScreenshotOptions()
    .setPath(Paths.get("screenshot.png")));

// 全页截图
page.screenshot(new Page.ScreenshotOptions()
    .setPath(Paths.get("fullpage.png"))
    .setFullPage(true));

// 元素截图
page.locator(".header").screenshot(
    new Locator.ScreenshotOptions()
        .setPath(Paths.get("header.png")));

// 截图到字节数组
byte[] bytes = page.screenshot();

// 高级选项
page.screenshot(new Page.ScreenshotOptions()
    .setPath(Paths.get("custom.png"))
    .setType(ScreenshotType.PNG)
    .setQuality(90)                    // JPEG 质量
    .setOmitBackground(true)           // 透明背景
    .setScale(ScreenshotScale.DEVICE)  // 设备像素比
    .setMask(java.util.Arrays.asList(  // 遮罩敏感区域
        page.locator(".user-avatar"),
        page.locator(".email")
    ))
);
```

### 4.4 录屏功能

```java
// 创建上下文时开启录屏
BrowserContext context = browser.newContext(
    new Browser.NewContextOptions()
        .setRecordVideoDir(Paths.get("videos/"))  // 视频保存目录
        .setRecordVideoSize(1280, 720)            // 视频尺寸
);

Page page = context.newPage();
page.navigate("https://example.com");

// ... 执行操作 ...

// 关闭上下文时自动保存视频
context.close();

// 获取视频路径
Video video = page.video();
if (video != null) {
    Path videoPath = video.path();
    System.out.println("视频已保存到: " + videoPath);
    
    // 另存为指定路径
    video.saveAs(Paths.get("test-video.webm"));
    
    // 删除视频
    // video.delete();
}
```

### 4.5 网络拦截

#### 4.5.1 监听网络请求

```java
// 监听所有请求
page.onRequest(request -> {
    System.out.println("请求: " + request.method() + " " + request.url());
});

// 监听所有响应
page.onResponse(response -> {
    System.out.println("响应: " + response.status() + " " + response.url());
});

// 监听失败请求
page.onRequestFailed(request -> {
    System.out.println("请求失败: " + request.url());
});
```

#### 4.5.2 拦截并修改请求

```java
// 拦截 API 请求并修改
page.route("**/api/user", route -> {
    // 继续请求，修改请求头
    route.resume(new Route.ResumeOptions()
        .setHeaders(java.util.Map.of(
            "Authorization", "Bearer custom-token",
            "X-Custom-Header", "value"
        ))
    );
});

// 拦截并返回 Mock 数据
page.route("**/api/products", route -> {
    route.fulfill(new Route.FulfillOptions()
        .setStatus(200)
        .setContentType("application/json")
        .setBody("{\"products\": [{\"id\": 1, \"name\": \"Mock Product\"}]}")
    );
});

// 中止特定请求（如广告、图片）
page.route("**/*.png", route -> route.abort());
page.route("**/ads/**", route -> route.abort());
```

#### 4.5.3 获取响应数据

```java
// 等待特定 API 响应并获取数据
Response response = page.waitForResponse("**/api/user", () -> {
    page.navigate("https://example.com/profile");
});

System.out.println("状态码: " + response.status());
System.out.println("响应体: " + response.text());

// 解析 JSON 响应
String jsonBody = response.text();
```


### 4.6  登录状态复用

```java
// 1. 保存登录状态
page.navigate("/login");
page.getByLabel("用户名").fill("user");
page.getByLabel("密码").fill("pass");
page.getByText("登录").click();

// 保存存储状态
context.storageState(
    new BrowserContext.StorageStateOptions()
        .setPath(Paths.get("state.json"))
);

// 2. 后续测试复用状态
BrowserContext context = browser.newContext(
    new Browser.NewContextOptions()
        .setStorageStatePath(Paths.get("state.json"))
);

// 直接访问需要登录的页面，无需重新登录
Page page = context.newPage();
page.navigate("/dashboard");
```

### 4.7  键盘操作

```java
// 按下单个键
page.keyboard().press("Enter");
page.keyboard().press("Tab");
page.keyboard().press("Escape");

/**
Backquote, Minus, Equal, Backslash, Backspace, Tab, Delete, Escape,
ArrowDown, End, Enter, Home, Insert, PageDown, PageUp, ArrowRight,
ArrowUp, F1 - F12, Digit0 - Digit9, KeyA - KeyZ, etc.

*/
// 组合键
page.keyboard().press("Control+A"); // 全选
page.keyboard().press("Control+C"); // 复制
page.keyboard().press("Control+V"); // 粘贴

// Mac 组合键
page.keyboard().press("Meta+A"); // Command+A

// 输入文本
page.keyboard().type("Hello World");
page.keyboard().type("Hello", new Keyboard.TypeOptions().setDelay(100));

// 按下和释放
page.keyboard().down("Shift");
page.keyboard().press("A");
page.keyboard().up("Shift");

```

> 文档：[https://playwright.dev/java/docs/input#keys-and-shortcuts](https://playwright.dev/java/docs/input#keys-and-shortcuts)


### 4.8 对话框处理

```java
// 监听并接受 alert
page.onDialog(dialog -> {
    System.out.println(dialog.message());
    dialog.accept();
});

// 监听并取消 confirm
page.onDialog(dialog -> {
    dialog.dismiss();
});

// 接受 prompt 并输入文本
page.onDialog(dialog -> {
    System.out.println(dialog.defaultValue());
    dialog.accept("输入的文本");
});

// 触发对话框
page.click("#show-alert");
page.click("#show-confirm");
page.click("#show-prompt");
```

## 五、高级用法

### 5.1 多页面与多标签页

```java
BrowserContext context = browser.newContext();

// 创建多个页面（标签页）
Page page1 = context.newPage();
Page page2 = context.newPage();

// 分别导航
page1.navigate("https://example.com");
page2.navigate("https://google.com");

// 获取所有页面
List<Page> pages = context.pages();
System.out.println("打开的页面数: " + pages.size());

// 切换到特定页面
Page targetPage = pages.stream()
    .filter(p -> p.url().contains("google"))
    .findFirst()
    .orElse(null);

// 等待新页面打开（点击链接弹出新窗口）
Page newPage = context.waitForPage(() -> {
    page1.getByText("打开新窗口").click();
});

// 新页面自动加载完成
newPage.waitForLoadState();
System.out.println("新页面URL: " + newPage.url());

// 关闭页面
page2.close();
```

### 5.2 iframe 处理

```java
// 1. 通过 frameLocator 定位 iframe
FrameLocator frameLocator = page.frameLocator("#my-iframe");

// 在 iframe 内操作元素
frameLocator.getByLabel("用户名").fill("test");
frameLocator.getByRole(AriaRole.BUTTON).click();

// 2. 嵌套 iframe
FrameLocator outerFrame = page.frameLocator(".outer-frame");
FrameLocator innerFrame = outerFrame.frameLocator(".inner-frame");
innerFrame.getByText("提交").click();

// 3. 通过名称或 URL 获取 Frame
Frame frame = page.frame("frame-name");
if (frame != null) {
    frame.locator("button").click();
}

// 4. 获取所有 frames
List<Frame> frames = page.frames();
for (Frame f : frames) {
    System.out.println("Frame URL: " + f.url());
}
```

### 5.3 文件上传

#### 5.3.1 基础文件上传

```java
// 1. 最简单的方式（input[type=file]）
Locator fileInput = page.locator("input[type=file]");

// 上传单个文件
fileInput.setInputFiles(Paths.get("document.pdf"));

// 上传多个文件
fileInput.setInputFiles(new Path[]{
    Paths.get("file1.txt"),
    Paths.get("file2.jpg")
});

// 清空已选文件
fileInput.setInputFiles(new Path[0]);
```

#### 5.3.2 点击触发的文件选择

```java
// 同步方式（推荐）
FileChooser fileChooser = page.waitForFileChooser(() -> {
    page.getByText("上传").click();
});
fileChooser.setFiles(Paths.get("data.csv"));
```

#### 5.3.3 内存文件上传

```java
// 从内存创建文件并上传
fileInput.setInputFiles(new FilePayload[]{
    new FilePayload(
        "test.txt",           // 文件名
        "text/plain",         // MIME 类型
        "Hello World!".getBytes()  // 文件内容
    )
});
```

### 5.4 文件下载

```java
// 创建上下文时允许下载
BrowserContext context = browser.newContext(
    new Browser.NewContextOptions()
        .setAcceptDownloads(true)
);

Page page = context.newPage();

// 等待下载完成
Download download = page.waitForDownload(() -> {
    page.getByText("下载文件").click();
});

// 获取下载信息
System.out.println("文件名: " + download.filename());
System.out.println("下载URL: " + download.url());

// 保存到指定路径
download.saveAs(Paths.get("downloaded_file.pdf"));

// 获取下载失败原因
if (download.failure() != null) {
    System.out.println("下载失败: " + download.failure());
}

// 删除下载文件
// download.delete();
```

### 5.5 自定义移动端设备参数

```java
BrowserContext customMobile = browser.newContext(
    new Browser.NewContextOptions()
        .setViewportSize(390, 844)      // iPhone 14 尺寸
        .setDeviceScaleFactor(3)
        .setIsMobile(true)
        .setHasTouch(true)
        .setUserAgent("Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X)")
);
```



### 5.6 JavaScript 执行

```java
// 1. 执行简单 JS
String title = page.evaluate("document.title").toString();
System.out.println("标题: " + title);

// 2. 执行带参数的 JS
int sum = (int) page.evaluate("([a, b]) => a + b", 
    new Object[]{5, 3});

// 3. 传递元素给 JS
Locator element = page.locator("button");
String text = page.evaluate("el => el.textContent", element);

// 4. 执行异步 JS
String data = page.evaluate("async () => {\n" +
    "  const response = await fetch('/api/data');\n" +
    "  return response.json();\n" +
    "}").toString();

// 5. 处理返回的元素句柄
ElementHandle handle = page.evaluateHandle("document.body");
```




### 5.7 JUnit 5 集成

```java
package com.example.test;

import com.microsoft.playwright.*;
import org.junit.jupiter.api.*;
import static org.junit.jupiter.api.Assertions.*;

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
public class PlaywrightJUnitTest {
    
    private Playwright playwright;
    private Browser browser;
    private BrowserContext context;
    protected Page page;

    @BeforeAll
    void launchBrowser() {
        // 整个测试类只启动一次浏览器
        playwright = Playwright.create();
        browser = playwright.chromium().launch(
            new BrowserType.LaunchOptions()
                .setHeadless(true)
        );
    }

    @BeforeEach
    void createContextAndPage() {
        // 每个测试方法创建独立的上下文和页面
        context = browser.newContext();
        page = context.newPage();
    }

    @AfterEach
    void closeContext() {
        // 每个测试后关闭上下文
        context.close();
    }

    @AfterAll
    void closeBrowser() {
        // 所有测试完成后关闭浏览器
        browser.close();
        playwright.close();
    }

    // 测试用例
    @Test
    void testPageTitle() {
        page.navigate("https://example.com");
        assertEquals("Example Domain", page.title());
    }

    @Test
    void testNavigation() {
        page.navigate("https://example.com");
        page.getByText("More information...").click();
        assertTrue(page.url().contains("iana.org"));
    }
}
```

---


## 六、常见问题与解决方案

### 6.1 环境相关问题

#### Q1: 首次运行下载浏览器很慢？

**解决方案：**

```bash
# 设置国内镜像
export PLAYWRIGHT_DOWNLOAD_HOST=https://npmmirror.com/mirrors/playwright/

# 或 Maven 参数
mvn test -Dplaywright.download.host=https://npmmirror.com/mirrors/playwright/
```

#### Q2: Linux 环境缺少依赖？

**解决方案：**

```bash
# 自动安装系统依赖
mvn exec:java -e -D exec.mainClass=com.microsoft.playwright.CLI -D exec.args="install-deps"
```



### 6.2 元素定位问题

#### Q1: 元素找不到，报 TimeoutError？

**排查步骤：**

1. 检查选择器是否正确

2. 检查元素是否在 iframe 内

3. 检查元素是否在 Shadow DOM 内

4. 增加超时时间

5. 截图确认页面状态

```java
// 增加超时
locator.click(new Locator.ClickOptions().setTimeout(30000));

// 截图调试
page.screenshot(new Page.ScreenshotOptions()
    .setPath(Paths.get("debug.png")));
```

#### Q2: 元素被遮挡，点击失败？

**解决方案：**

```java
// 强制点击（跳过可操作性检查）
locator.click(new Locator.ClickOptions().setForce(true));

// 或使用 JS 点击
locator.evaluate("el => el.click()");

// 或滚动到可见区域
locator.scrollIntoViewIfNeeded();
locator.click();
```

#### Q3: 动态 ID 如何处理？

**解决方案：**

```java
// 使用部分匹配
page.locator("[id^='prefix-']");      // 开头匹配
page.locator("[id$='-suffix']");      // 结尾匹配
page.locator("[id*='contains']");     // 包含匹配

// 更好的方案：使用其他属性
page.getByRole(AriaRole.BUTTON);
page.getByText("提交");
```

### 6.3 并发与稳定性问题

#### Q1: 多线程环境报错？

**重要：Playwright 对象不是线程安全的！**

**解决方案：**

```java
// ✅ 正确：每个线程使用独立的 Playwright/Browser
ThreadLocal<Playwright> playwrightThreadLocal = ThreadLocal.withInitial(() -> {
    return Playwright.create();
});

// ❌ 错误：多线程共享同一个 Playwright 实例
```


#### Q2: CI/CD 环境运行失败？

**解决方案：**

```java
// CI 环境必须使用无头模式
Browser browser = playwright.chromium().launch(
    new BrowserType.LaunchOptions()
        .setHeadless(true)  // CI 环境必须为 true
        .setArgs(java.util.Arrays.asList(
            "--no-sandbox",
            "--disable-dev-shm-usage"
        ))
);
```

### 6.4 功能使用问题

#### Q1: 文件上传失败？

**解决方案：**

```java
// 确保 input 元素可见
page.locator("input[type=file]").setInputFiles(path);

// 如果 input 是隐藏的，使用 force
page.locator("input[type=file]").setInputFiles(
    path, 
    new Locator.SetInputFilesOptions().setNoWaitAfter(true)
);
```

#### Q2: 下载没有触发？

**解决方案：**

```java
// 必须在创建上下文时启用下载
BrowserContext context = browser.newContext(
    new Browser.NewContextOptions()
        .setAcceptDownloads(true)  // 必须设置！
);
```

#### Q3: iframe 内元素找不到？

**解决方案：**

```java
// 必须使用 frameLocator，不能直接定位
FrameLocator frame = page.frameLocator("#iframe-id");
frame.getByText("按钮").click();  // ✅ 正确

// page.getByText("按钮").click();  // ❌ 错误，找不到 iframe 内元素
```

### 6.5 性能问题

#### Q1: 测试执行太慢？

**优化建议：**

1. **启用并行执行** \- 最有效
2. **复用浏览器实例** \- 不要每个测试都启动浏览器
3. **复用登录状态** \- 使用 `storageState`
4. **阻止不必要资源** \- 图片、广告、分析脚本
5. **使用 API 准备测试数据** \- 不要通过 UI 创建数据
6. **减少不必要的截图 / 录屏**

#### Q2: 内存占用过高？

**解决方案：**

```java
// 及时关闭不需要的 BrowserContext
context.close();

// 限制并行数量
// junit.jupiter.execution.parallel.config.dynamic.factor = 0.5

// 定期重启浏览器
if (testCount > 100) {
    browser.close();
    browser = playwright.chromium().launch();
}
```

---

## 七、总结

Playwright Java SDK 提供了强大而现代的浏览器自动化能力，通过此文章你已经掌握了：

1. **环境搭建** \- Maven/Gradle 配置，浏览器管理
2. **基础操作** \- 浏览器启动、导航、元素定位、交互
3. **核心功能** \- 等待机制、断言、截图、录屏、网络拦截
4. **高级用法** \- 多页面、iframe、文件处理
5. **问题排查** \- 常见问题的解决方案

**下一步建议：**

- 阅读 [官方文档](https://playwright.dev/java/) 获取最新 API
- 在实际项目中练习使用
- 关注 Playwright 版本更新


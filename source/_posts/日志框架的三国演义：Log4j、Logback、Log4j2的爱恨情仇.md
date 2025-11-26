---
title: 日志框架的三国演义：Log4j、Logback、Log4j2的爱恨情仇
tags: [Spring Boot]
categories: Java
date: 2025-11-25 16:01:54
updated: 2025-11-25 16:01:54
---


## 一、概述

日志，作为一个开发者应该不会陌生吧，如果没有日志，当系统报错：“系统异常” 时，就算你是有几百年功力的技术大佬你也难以瞬间定位问题所在。

良好的日志系统就像飞机的"黑匣子"，它能记录运行轨迹、监控系统状态并快速定位问题。本文将带你了解`Log4j`、`Logback`和`Log4j2`这三个主流日志框架，以及如何通过门面模式统一日志接口。

<!--more-->

### 1、日志框架的发展历程



- 首先，我们来理清Log4j、Log4j2和Logback之间的“血缘关系”。它们的故事，几乎就是Java日志框架的进化史。这张时间线清晰地展示了它们的演进历程和核心特点：



![Java日志框架演进史](history.png)



- 在技术演进的道路上，`Ceki Gülcü`无疑是核心人物。他最初打造的 **Log4j** 是一个里程碑式的框架，引入了 `Logger`、`Appender`、`Layout`等至今仍在使用的核心概念。随后，为克服 Log4j 在架构上的一些历史局限性（如性能瓶颈），他又主导开发了 **Logback**，旨在成为 Log4j 的现代化继任者。。

- 然而，技术的脚步从未停歇。面对 Log4j 的逐渐老化，Apache 社区在充分借鉴 Log4j 和 Logback 设计思想的基础上，对架构进行了彻底的重构，推出了 **Log4j2**。值得注意的是，Log4j2 并非 Log4j 的简单升级，而是一个全新的架构，它在性能（尤其是异步日志处理）和灵活性方面实现了重大突破。



- 所以，简单来说：**Logback是Log4j 1.x的“正统改良版”，而Log4j2则是一个更具颠覆性的“全新版本”**。



- **标题有三国，不能骗你们，来首打油诗：**
  - 混沌先秦无日志，诸侯割据各纷争
  - Log4j 东汉定天下，一统江山制度明
  - Logback 蜀汉承正统，Log4j2 魏霸强
  - 三分归晋 SLF4J，自此日志大一统



### 2、日志门面

- 我们通常所说的日志门面（Logging Facade）是一种设计模式，它提供了一个抽象的日志接口，允许应用程序在运行时与具体的日志实现（如 `Logback`、`Log4j2`等）解耦。
- 在Java中最常用的日志门面是`SLF4J（Simple Logging Facade for Java）` 和 `JCL（Apache Commons Logging）`, `JCL`适用于遗留系统或需兼容旧代码的项目，但因维护成本高，已逐渐被`SLF4J`取代。



#### ①、为什么需要日志门面？

- 如果我的代码直接依赖了`Logback`的API，将来想换成`Log4j2`岂不是要改到天昏地暗？
- 这正是**SLF4J（Simple Logging Facade for Java）**，即**日志门面**，要解决的问题。门面模式的核心思想是：**外部与一个子系统的通信必须通过一个统一的外观对象进行**。
- 对我们而言，作为应用程序的开发者，我们只需要面向`SLF4J`这一套统一的API进行编程，而无需关心底层实际使用的是哪种日志实现框架。这带来了两大核心优势：
  - **解耦与灵活性**：你的业务代码和日志实现彻底解耦。今天用Logback，明天想换成Log4j2，只需替换依赖和配置文件，代码一行都不用改
  - **优雅的日志记录语法**：SLF4J提供了非常实用的占位符功能，避免了不必要的字符串拼接
    - **不推荐的做法**：`logger.debug("用户信息，id: " + id + ", name: " + name);`// 即使日志级别高于DEBUG，字符串拼接也会执行
    - **SLF4J推荐做法**：`logger.debug("用户信息，id: {}, name: {}", id, name);`// 只有确需输出时才会进行字符串格式化
- 那么，SLF4J是如何和具体的日志框架（我们称之为“绑定”）协作的呢？下图直观地展示了SLF4J作为门面，如何与各种日志实现框架连接：

![各种日志实现框架连接](impl.png)



- **SLF4J-Simple**：最简单的实现

  - maven依赖：`slf4j-simple`

- **Logback**：SpringBoot的默认选择
  - logback-classic
    - SLF4J绑定器
    - 核心日志功能
    - 自动配置支持
  - logback-core
    - 基础框架组件

- **Log4j 1.x**：经典但已过时
  - **开创者**：第一个成熟的Java日志框架
- **JUL**：Java标准库
  - **零依赖**：JDK自带，无需额外依赖
- **Log4j2**：新一代性能王者



####  ②、各实现对比总结

| 特性               | SLF4J-Simple | Logback | Log4j 1.x | JUL  | Log4j2         |
| :----------------- | :----------- | :------ | :-------- | :--- | :------------- |
| **性能**           | 差           | 优秀    | 差        | 一般 | **极致**       |
| **配置复杂度**     | 无           | 中等    | 中等      | 简单 | 复杂           |
| **异步支持**       | 无           | 有      | 无        | 无   | **高性能异步** |
| **自动重载**       | 无           | 支持    | 无        | 无   | 支持           |
| **生产就绪**       | 否           | **是**  | 否        | 一般 | **是**         |
| **SpringBoot默认** | 否           | **是**  | 否        | 否   | 可选           |



- 背景理论虽长，但经过一番“神仙打架”，如今在日志框架的江湖中，屹立不倒的只剩 **Logback** 与 **Log4j2** 这两位高手。下面，我们就来看看这场“终极对决”在 **SpringBoot** 的舞台上如何上演。



## 二、实战



### 1、Logback



- Spring Boot默认采用**SLF4J作为日志门面**和**Logback作为日志实现**,它的依赖是：`spring-boot-starter-logging`,当我们创建springboot项目引入的：`spring-boot-starter`或`spring-boot-starter-web` 的依赖里面就已经包含logback依赖了。
- 示例如下：



```java
@RestController
public class LogController {
    private static final Logger log = LoggerFactory.getLogger(LogController.class);

    @GetMapping("/test")
    public String test(String name) {
        log.debug("------------debug--------------{}", name);
        log.info("------------info--------------{}", name);
        log.warn("------------warn--------------{}", name);
        log.error("------------error--------------{}", name);
        return "log test..." + name;
    }
}
```

- 通过LoggerFactory，获取日志对象，就可以进行日志打印输出了。
- 默认情况下，你只能在控制台看到INFO级别及以上的输出，这是因为Spring Boot的**默认日志级别是INFO**，DEBUG 级别比INFO低，所以它不会显示。

#### ①、日志级别

- 日志级别从低到高分为：**TRACE → DEBUG → INFO → WARN → ERROR** 。设置级别后，只会打印该级别及更高级别的日志。在`application.yml`中配置级别很简单：



```yaml
logging:
  level:
  	# 根级别: info
    root: info
    # 我们自己的业务包名，开发的时候可以设置为debug级别，其他框架包info级别
    top.lrshuai.yourPackage: DEBUG
    com.example.demo: DEBUG
    
```



#### ②、日志配置实战

- 除了控制台输出，将日志保存到文件很重要：



```yaml
logging:
  file:
   # 指定日志目录
  	path: D:/log_space/demo/
  	# 指定日志文件名
    name: demo.log
    
```

- 除了配置日志文件，还可以配置日志打印格式：

```yaml
logging:
  pattern:
  	# 控制台输出日志
    console: "%d{yyyy-MM-dd HH:mm:ss} - %clr(%-5level) [%thread] %logger{15} - %msg%n"
    # 文件输入日志
    file: "%d{yyyy-MM-dd HH:mm:ss.SSS} >>> [%thread] >>> %-5level >>> %logger{50} >>> %msg%n"
```

- 如果我们的终端是支持显示彩色的，可以使用`%clr` 把想要打印彩色的给扩起来，如上的：`%clr(%-5level)`就会把日志级别文字就是彩色的，如下：



![日志使用彩色输出](prif1.png)

- `%clr` 的颜色默认：ERROR=红色，WARN=黄色，INFO=绿色，DEBUG、TRACE=绿色，你也可以自定义颜色，如：`%clr(%d{yyyy-MM-dd HH:mm:ss}){blue}` 时间打印`blue(蓝色)`,如下图。



![自定义时间日志颜色](prif2.png)

- 自定义颜色支持：`blue(蓝色)`、`cyan(青色)`、`faint(默认的，黑色)`、`green(绿色)`、`magenta(紫红色)`、`red(红色)`、`yellow(很色)`



#### ③、日志高级配置实战

- 上面是基本配置，高级复杂的还是使用 日志配置文件比较方便,来一个完整的示例吧：`logback-spring.xml`

  



```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration scan="true" scanPeriod="60 seconds" debug="false">
    <!-- 日志名称前缀 -->
    <property name="LOG_NAME" value="demo"/>
    <!-- 最大保存时间：15天-->
    <property name="KEEP_DAY" value="15"/>
    <!-- 日志输出格式 -->
    <property name="LOG_PATTERN" value="%d{yyyy-MM-dd HH:mm:ss.SSS} [%thread] %-5level %logger{36} - [%M,%line] - %msg%n"/>
    <property name="COLOR_PATTERN" value="%red(%d{yyyy-MM-dd HH:mm:ss.SSS}) %green([%thread]) %highlight(%-5level) %boldMagenta(%logger{36}) - [%M,%line] - %msg%n"/>

    <!-- 控制台打印日志的相关配置 -->
    <appender name="CONSOLE" class="ch.qos.logback.core.ConsoleAppender">
        <encoder>
            <pattern>${COLOR_PATTERN}</pattern>
            <charset>UTF-8</charset>
        </encoder>
    </appender>

    <!-- 通用文件滚动策略基础配置 -->
    <appender name="FILE_INFO" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <!-- 保存日志文件的路径 -->
        <file>logs/${LOG_NAME}_info.log</file>
        <encoder>
            <pattern>${LOG_PATTERN}</pattern>
            <charset>UTF-8</charset>
        </encoder>
        <!-- 使用LevelFilter精确匹配INFO级别 -->
        <filter class="ch.qos.logback.classic.filter.LevelFilter">
            <!-- 过滤的级别 -->
            <level>INFO</level>
            <!-- 匹配时的操作：接收（记录） -->
            <onMatch>ACCEPT</onMatch>
            <!-- 不匹配时的操作：拒绝（不记录） -->
            <onMismatch>DENY</onMismatch>
        </filter>

        <!-- 使用SizeAndTimeBasedRollingPolicy，同时按时间和大小滚动 -->
        <rollingPolicy class="ch.qos.logback.core.rolling.SizeAndTimeBasedRollingPolicy">
            <fileNamePattern>logs/${LOG_NAME}_info.%d{yyyy-MM-dd}.%i.log</fileNamePattern>
            <maxHistory>${KEEP_DAY}</maxHistory>
            <maxFileSize>50MB</maxFileSize>
            <totalSizeCap>2GB</totalSizeCap>
        </rollingPolicy>
    </appender>

    <!-- WARN 级别文件 -->
    <appender name="FILE_WARN" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <file>logs/${LOG_NAME}_warn.log</file>
        <encoder>
            <pattern>${LOG_PATTERN}</pattern>
            <charset>UTF-8</charset>
        </encoder>
        <filter class="ch.qos.logback.classic.filter.LevelFilter">
            <level>WARN</level>
            <onMatch>ACCEPT</onMatch>
            <onMismatch>DENY</onMismatch>
        </filter>
        <rollingPolicy class="ch.qos.logback.core.rolling.SizeAndTimeBasedRollingPolicy">
            <fileNamePattern>logs/${LOG_NAME}_warn.%d{yyyy-MM-dd}.%i.log.gz</fileNamePattern>
            <maxHistory>${KEEP_DAY}</maxHistory>
            <maxFileSize>50MB</maxFileSize>
            <totalSizeCap>1GB</totalSizeCap>
        </rollingPolicy>
    </appender>

    <appender name="FILE_ERROR" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <file>logs/${LOG_NAME}_error.log</file>
        <encoder>
            <pattern>${LOG_PATTERN}</pattern>
            <charset>UTF-8</charset>
        </encoder>
        <!-- 使用ThresholdFilter接收ERROR及以上级别 -->
        <filter class="ch.qos.logback.classic.filter.ThresholdFilter">
            <level>ERROR</level>
        </filter>
        <rollingPolicy class="ch.qos.logback.core.rolling.SizeAndTimeBasedRollingPolicy">
            <fileNamePattern>logs/${LOG_NAME}_error.%d{yyyy-MM-dd}.%i.log</fileNamePattern>
            <maxHistory>${KEEP_DAY}</maxHistory>
            <maxFileSize>50MB</maxFileSize>
            <totalSizeCap>1GB</totalSizeCap>
        </rollingPolicy>
    </appender>

    <!-- 添加异步日志Appender提升性能 -->
    <appender name="ASYNC_INFO" class="ch.qos.logback.classic.AsyncAppender">
        <!-- 不丢弃任何日志 -->
        <discardingThreshold>0</discardingThreshold>
        <queueSize>512</queueSize>
        <appender-ref ref="FILE_INFO" />
    </appender>

    <appender name="ASYNC_WARN" class="ch.qos.logback.classic.AsyncAppender">
        <discardingThreshold>0</discardingThreshold>
        <queueSize>512</queueSize>
        <appender-ref ref="FILE_WARN" />
    </appender>

    <appender name="ASYNC_ERROR" class="ch.qos.logback.classic.AsyncAppender">
        <discardingThreshold>0</discardingThreshold>
        <queueSize>512</queueSize>
        <appender-ref ref="FILE_ERROR" />
    </appender>

    <!-- 自定义业务包 日志级别 -->
    <logger name="top.lrshuai" level="DEBUG"/>
    <logger name="org.springframework.web" level="INFO"/>

    <!-- 多环境配置 -->
    <springProfile name="dev,default">
        <root level="INFO">
            <appender-ref ref="CONSOLE" />
            <appender-ref ref="FILE_INFO" />
            <appender-ref ref="FILE_WARN" />
            <appender-ref ref="FILE_ERROR" />
        </root>
    </springProfile>

    <springProfile name="test">
        <root level="INFO">
            <appender-ref ref="CONSOLE" />
            <appender-ref ref="ASYNC_INFO" />
            <appender-ref ref="ASYNC_WARN" />
            <appender-ref ref="ASYNC_ERROR" />
        </root>
    </springProfile>

    <springProfile name="prod">
        <root level="INFO">
            <appender-ref ref="ASYNC_INFO" />
            <appender-ref ref="ASYNC_WARN" />
            <appender-ref ref="ASYNC_ERROR" />
        </root>
    </springProfile>
</configuration>
```



- 通过`property` 属性自定义一些通用变量，如：日志名称，日志格式 等等
- 控制台Appender（`CONSOLE`）、还有文件 Appender（`FILE_INFO`、`FILE_WARN`、`FILE_ERROR`）
- 异步Appender（`ASYNC_INFO`、`ASYNC_WARN`、`ASYNC_ERROR`）
  - 异步记录日志，提升性能。
  - `discardingThreshold`：这个参数表示当队列剩余容量低于这个阈值时，开始丢弃日志。设置为0表示当队列满时，不会丢弃任何日志，而是阻塞等待,如果设置一个非零值（比如20），表示当队列剩余容量低于20%时，开始丢弃低于某个级别的日志（默认是`INFO`，但可以设置）。
  - `queueSize`是异步日志Appender中队列的大小。它决定了异步日志缓冲区可以容纳的日志事件数量。
    当队列已满时，默认情况下，异步日志Appender会阻塞应用程序线程，直到队列有空间为止（除非设置了丢弃策略）。
- 多环境配置（使用`springProfile`）,在开发环境（`dev`）和默认环境（`default`）下使用同步日志并输出到控制台，测试环境（`test`）使用异步日志并输出到控制台，生产环境（`prod`）只使用异步日志记录到文件，不输出控制台。



![日志文件](prif3.png)



- 虽然Logback是默认选择，但切换到Log4j2也很简单



### 2、Log4j2



- 排除默认日志依赖，添加Log4j2依赖



```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
    <exclusions>
        <exclusion>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-logging</artifactId>
        </exclusion>
    </exclusions>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-log4j2</artifactId>
</dependency>
```

- 因为springboot基于日志门面设计，所以yml配置和logback一样，如果是自定义配置文件倒是有点不同，如下`log4j2-spring.xml`：



```xml
<?xml version="1.0" encoding="UTF-8"?>
<Configuration monitorInterval="30" status="WARN">

    <!-- 定义全局属性 -->
    <Properties>
        <!-- 日志文件存储路径 -->
        <Property name="LOG_HOME">logs</Property>
        <!-- 日志名称 -->
        <Property name="APP_NAME">log4j2-demo</Property>

        <!-- 日志格式定义 -->
        <!-- 格式化输出：
           %style 彩色输出,例如：%style{[%tid]}{red}
           %highlight  自动彩色高亮,例如：%highlight{%-5level}
           %d表示日期，
           %tid：线程id,
           %t:表示线程名 [%15.15t]对线程名称进行格式控制，固定宽度为15个字符（不足时用空格填充，超长时截断处理），语法：%[对齐][最小宽度].[最大宽度]t
           %-5level：级别从左显示5个字符宽度
           %logger: 表示完整的类名  %logger{36}表示 Logger名字最长36个字符，
           %c: 表示完整的类名 {1.}只显示最后一级包名（类名本身），例：默认：top.lrs.java.MyApplication=t.l.j.MyApplication
           %msg：日志消息，
           %n是换行符
           %M- 方法名
           %L- 行号
       -->
        <Property name="LOG_PATTERN_CONSOLE">%d{yyyy-MM-dd HH:mm:ss.SSS} %style{[%tid]}{magenta} %highlight{%-5level} %style{[%15.15t]}{blue} %style{%-40.40c{1.}.%M(%L)}{cyan} : %msg%n</Property>
        <Property name="LOG_PATTERN_FILE">%d{yyyy-MM-dd HH:mm:ss.SSS} [%tid]=[%thread] %-5level [%15.15t] %logger{36} : %msg%n</Property>
        <Property name="LOG_PATTERN_JSON">{&quot;timestamp&quot;:&quot;%d{yyyy-MM-dd HH:mm:ss.SSS}&quot;,&quot;level&quot;:&quot;%level&quot;,&quot;thread&quot;:&quot;%t&quot;,&quot;logger&quot;:&quot;%logger&quot;,&quot;message&quot;:&quot;%msg&quot;,&quot;exception&quot;:&quot;%ex&quot;}</Property>
    </Properties>

    <!-- 定义Appenders -->
    <Appenders>

        <!-- 控制台输出 - 彩色日志 -->
        <Console name="Console" target="SYSTEM_OUT">
            <PatternLayout pattern="${LOG_PATTERN_CONSOLE}" disableAnsi="false"/>
        </Console>

        <!-- 信息级别文件输出 -->
        <RollingFile name="InfoFile" fileName="${LOG_HOME}/${APP_NAME}-info.log"
                     filePattern="${LOG_HOME}/${APP_NAME}-info-%d{yyyy-MM-dd}-%i.log.gz">
            <PatternLayout pattern="${LOG_PATTERN_FILE}"/>
            <Policies>
                <!-- 基于时间的滚动策略 -->
                <TimeBasedTriggeringPolicy interval="1" modulate="true"/>
                <!-- 基于文件大小的滚动策略 -->
                <SizeBasedTriggeringPolicy size="100 MB"/>
            </Policies>
            <!-- 最多保留30天的日志 -->
            <DefaultRolloverStrategy max="30"/>
            <Filters>
                <!-- 只接受INFO级别及以上的日志 -->
                <ThresholdFilter level="INFO" onMatch="ACCEPT" onMismatch="DENY"/>
            </Filters>
        </RollingFile>

        <!-- 错误级别文件输出 -->
        <RollingFile name="ErrorFile" fileName="${LOG_HOME}/${APP_NAME}-error.log"
                     filePattern="${LOG_HOME}/${APP_NAME}-error-%d{yyyy-MM-dd}-%i.log.gz">
            <PatternLayout pattern="${LOG_PATTERN_FILE}"/>
            <Policies>
                <TimeBasedTriggeringPolicy interval="1" modulate="true"/>
                <SizeBasedTriggeringPolicy size="50 MB"/>
            </Policies>
            <DefaultRolloverStrategy max="60"/>
            <Filters>
                <!-- 只接受ERROR级别及以上的日志 -->
                <ThresholdFilter level="ERROR" onMatch="ACCEPT" onMismatch="DENY"/>
            </Filters>
        </RollingFile>

        <!-- 异步Appender提升性能 -->
        <Async name="AsyncInfoFile" bufferSize="1024">
            <AppenderRef ref="InfoFile"/>
        </Async>

        <Async name="AsyncErrorFile" bufferSize="512">
            <AppenderRef ref="ErrorFile"/>
        </Async>

        <!-- 生产环境JSON格式输出（用于日志分析系统） -->
        <RollingFile name="JsonFile" fileName="${LOG_HOME}/${APP_NAME}.json"
                     filePattern="${LOG_HOME}/${APP_NAME}-%d{yyyy-MM-dd}-%i.json.gz">
            <JsonLayout complete="false" compact="false"/>
            <Policies>
                <TimeBasedTriggeringPolicy interval="1"/>
                <SizeBasedTriggeringPolicy size="200 MB"/>
            </Policies>
            <DefaultRolloverStrategy max="15"/>
        </RollingFile>

    </Appenders>

    <!-- 日志级别配置 -->
    <Loggers>
        <!-- Spring框架日志级别控制 -->
        <Logger name="org.springframework" level="INFO" additivity="false"/>

        <!-- 应用包日志级别 -->
        <Logger name="com.example" level="DEBUG" additivity="false"/>

        <!-- 第三方库日志级别优化 -->
        <Logger name="org.apache" level="WARN" additivity="false"/>

        <!-- 根日志配置 -->
        <Root level="INFO">
            <!-- 默认引用，具体环境配置在SpringProfile中覆盖 -->
            <AppenderRef ref="Console"/>
            <AppenderRef ref="InfoFile"/>
            <AppenderRef ref="ErrorFile"/>
        </Root>
    </Loggers>

    <!-- 开发环境配置 -->
    <SpringProfile name="dev | development | local">
        <Loggers>
            <!-- 开发环境：详细日志级别 -->
            <Logger name="top.lrshuai" level="TRACE"/>
            <Logger name="com.example" level="DEBUG"/>
            <Logger name="sun.rmi.runtime" level="INFO"/>
            <Logger name="org.springframework" level="INFO"/>

            <Root level="INFO">
                <AppenderRef ref="DevConsole"/>
                <AppenderRef ref="InfoFile"/>
                <AppenderRef ref="ErrorFile"/>
                <AppenderRef ref="JsonFile"/>
            </Root>
        </Loggers>
    </SpringProfile>

    <!-- 测试环境配置 -->
    <SpringProfile name="test">
        <Loggers>
            <Root level="INFO">
                <AppenderRef ref="Console"/>
                <AppenderRef ref="AsyncInfoFile"/>
                <AppenderRef ref="AsyncErrorFile"/>
            </Root>
        </Loggers>
    </SpringProfile>

    <!-- 生产环境配置 -->
    <SpringProfile name="prod | production">
        <Loggers>
            <!-- 生产环境：精简日志级别，提升性能 -->
            <Logger name="com.example" level="INFO"/>
            <Logger name="org.springframework" level="WARN"/>

            <Root level="INFO">
                <!-- 生产环境关闭控制台输出，减少IO开销 -->
                <AppenderRef ref="AsyncInfoFile"/>
                <AppenderRef ref="AsyncErrorFile"/>
                <AppenderRef ref="JsonFile"/>
                <!-- 只在需要时开启控制台日志 -->
                <!-- <AppenderRef ref="Console" level="INFO"/> -->
            </Root>
        </Loggers>
    </SpringProfile>

</Configuration>
```

- 我们只需要改写依赖和，日志配置文件，就可以实现日志框架的切换，一行代码都不用改。



![log4j2日志打印示例图](prif5.png)





### 3、使用Lombok简化日志代码

- 通过Lombok的`@Slf4j`注解，可以大幅简化日志声明：

```java
@Slf4j
@SpringBootApplication
public class Application {
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
        // 直接使用log对象
        log.info("应用启动成功"); 
    }
}
```

- 需要先添加Lombok依赖：

```xml
<dependency>
    <groupId>org.projectlombok</groupId>
    <artifactId>lombok</artifactId>
</dependency>
```



- 通过 `@Slf4j` 注解，我们就可以在类中，使用内置的 `log` 对象进行日志的打印，简直YYDS。





## 三、总结



- Spring Boot日志配置并不复杂，但却是项目不可或缺的重要组成部分。良好的日志实践能帮助**快速定位问题、监控系统运行状态、分析用户行为**。




#### 选型决策矩阵

  **选择Logback**：

  - 项目基于Spring Boot且无特殊性能要求
  - 团队对Logback配置更熟悉
  - 需要快速上手和稳定运行

  **选择Log4j2**：

  - 高并发、高性能是核心需求
  - 需要极致的异步日志性能
  - 项目规模大，需要复杂的日志管理策略





- **最后，祝大家，掌握日志的艺术，让每一次系统异常都成为提升的机会，而非排查的噩梦！🚀**

---
title: Spring Boot (四)：日志管理
date: 2017-07-30 10:13:22
tags: [Spring Boot, Java]
categories: Java
---
### 默认情况下，Spring Boot会用Logback来记录日志，并用INFO级别输出到控制台。在运行应用程序和其他例子时，你应该已经看到很多INFO级别的日志了。

## 1、添加依赖
### maven依赖中添加了spring-boot-starter-logging：
```
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-logging</artifactId>
</dependency>
```
#### 但是呢，实际开发中我们不需要直接添加该依赖，你会发现spring-boot-starter其中包含了 spring-boot-starter-logging，该依赖内容就是 Spring Boot 默认的日志框架 logback。如果工程中有用到了Thymeleaf，而Thymeleaf依赖包含了spring-boot-starter，最终我只要引入Thymeleaf即可。

## 2、把日志写入文件
#### 第一种方法：在application.properties 添加 logging.file="文件路径" 或者 logging.path="文件路径"  的属性
![](1501062665966089016.png)
#### 第二种方法：自定义logback.xml 文件
##### Spring Boot官方推荐优先使用带有-spring的文件名作为你的日志配置（如使用logback-spring.xml，而不是logback.xml），命名为logback-    spring.xml的日志配置文件，spring boot可以为它添加一些spring boot特有的配置项，如下图。


## 3、我的logback-spring.xml
```
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
  <!-- 控制台打印日志的相关配置 --> 
  <appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender"> 
    <!-- 日志格式 -->
    <encoder>
        <pattern>%d{yyyy-MM-dd HH:mm:ss} [%level] - %m%n</pattern>
    </encoder>
    <!-- 日志级别过滤器 -->
    <filter class="ch.qos.logback.classic.filter.LevelFilter">
      <!-- 过滤的级别 -->
      <level>INFO</level>
      <!-- 匹配时的操作：接收 （记录） -->
      <onMatch>ACCEPT</onMatch>
      <!-- 不匹配时的操作：拒绝DENY（不记录）接受：ACCEPT（记录） -->
      <onMismatch>ACCEPT</onMismatch>
    </filter>
  </appender>
 
  <!-- 文件保存日志的相关配置 --> 
  <appender name="file" class="ch.qos.logback.core.rolling.RollingFileAppender">
     <!-- 保存日志文件的路径 -->
    <file>e:/logs/info.log</file>
    <!-- 
    <file>/var/logs/info.log</file>
     -->
    <!-- 日志格式 -->
    <encoder>
        <pattern>%d{yyyy-MM-dd HH:mm:ss} [%class:%line] - %m%n</pattern>
    </encoder>
    <!-- 日志级别过滤器 -->
    <filter class="ch.qos.logback.classic.filter.LevelFilter">
      <!-- 过滤的级别 -->
      <level>INFO</level>
      <!-- 匹配时的操作：接收（记录） -->
      <onMatch>ACCEPT</onMatch>
      <!-- 不匹配时的操作：拒绝（不记录） -->
      <onMismatch>DENY</onMismatch>
    </filter>
    <!-- 循环政策：基于时间创建日志文件 -->
    <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
      <!-- 日志文件名格式 -->
      <fileNamePattern>info.%d{yyyy-MM-dd}.log</fileNamePattern>
      <!-- 最大保存时间：30天-->
      <maxHistory>30</maxHistory>
    </rollingPolicy>
  </appender>
   
   
  <appender name="error" class="ch.qos.logback.core.rolling.RollingFileAppender">
     <!-- 保存日志文件的路径 -->
    <file>e:/logs/error.log</file>
    <!-- 
    <file>/var/logs/error.log</file>
     -->
    <!-- 日志格式 -->
    <encoder>
        <pattern>%d{yyyy-MM-dd HH:mm:ss} [%class:%line] - %m%n</pattern>
    </encoder>
    <!-- 日志级别过滤器 -->
    <filter class="ch.qos.logback.classic.filter.LevelFilter">
      <!-- 过滤的级别 -->
      <level>ERROR</level>
      <!-- 匹配时的操作：接收（记录） -->
      <onMatch>ACCEPT</onMatch>
      <!-- 不匹配时的操作：拒绝（不记录） -->
      <onMismatch>DENY</onMismatch>
    </filter>
    <!-- 循环政策：基于时间创建日志文件 -->
    <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
      <!-- 日志文件名格式 -->
      <fileNamePattern>error.%d{yyyy-MM-dd}.log</fileNamePattern>
      <!-- 最大保存时间：30天-->
      <maxHistory>30</maxHistory>
    </rollingPolicy>
  </appender>
 
  <!-- 基于dubug处理日志：具体控制台或者文件对日志级别的处理还要看所在appender配置的filter，如果没有配置filter，则使用root配置 -->
  <root level="debug">
    <appender-ref ref="STDOUT" />
    <appender-ref ref="file" />
    <appender-ref ref="error" />
  </root>
</configuration>
```

## 4、java 代码调用示例
```
package top.lrshuai.helloword.controller;
 
import org.apache.log4j.Logger;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
 
import top.lrshuai.helloword.entity.User;
import top.lrshuai.helloword.mapper.UserMapper;
 
@RestController
public class UserController {
 
//  private Logger log = LoggerFactory.getLogger(this.getClass());
     
    private final Logger log = Logger.getLogger(this.getClass());
    @Autowired
    private UserMapper userMapper;
     
    @RequestMapping("/getAll")
    public Object getAllList(){
        List<User> ulist = userMapper.getAll();
        log.info("......");
        log.info("......");
        log.info("......");
        log.info("......");
        log.info("......");
        log.info("......");
        log.info("......");
        log.info("......");
        log.warn("warn....................");
        log.error("error....................");
        log.debug("debug....................");
        System.out.println("ulist="+ulist);
        return ulist;
    }
}
```


> 我的Github 地址： [https://github.com/rstyro/spring-boot/tree/master/springboot-log](https://github.com/rstyro/spring-boot/tree/master/springboot-log)


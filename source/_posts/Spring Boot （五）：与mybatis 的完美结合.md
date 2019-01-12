---
title: Spring Boot （五）：与mybatis 的完美结合
date: 2017-07-30 10:28:34
tags: [Spring Boot, Java]
categories: Java
---
# springboot 与mybatis 的整合
## 一、首先有两种方式：
### 1、第一：全注解版的
### 2、第二：配置版的

## 二、配置Springboot
### 1、添加依赖
```
<!-- 添加mybatis 依赖 -->
<dependency>
    <groupId>org.mybatis.spring.boot</groupId>
    <artifactId>mybatis-spring-boot-starter</artifactId>
    <version>1.3.0</version>
</dependency>
<!-- 驱动 -->
<dependency>
    <groupId>mysql</groupId>
    <artifactId>mysql-connector-java</artifactId>
</dependency>
```
### 2、application.xml 要配置数据源
```
spring.datasource.driverClassName = com.mysql.jdbc.Driver
spring.datasource.url = jdbc:mysql://localhost:3306/demo?useUnicode=true&characterEncoding=utf-8&useSSL=false
spring.datasource.username = root
spring.datasource.password = toor
# druid pool config
#spring.datasource.type = com.alibaba.druid.pool.DruidDataSource
```
### 3、在启动类 添加 @MapperScan("你mapper文件所在的包路径")
> 括号内修改为你mapper文件所在的包路径

```
@SpringBootApplication
@MapperScan("top.lrshuai.blog.dao")
public class Application{

	public static void main(String[] args) {
		SpringApplication.run(Application.class, args);
	}
}
```

> 我Github 地址：[https://github.com/rstyro/spring-boot](https://github.com/rstyro/spring-boot)

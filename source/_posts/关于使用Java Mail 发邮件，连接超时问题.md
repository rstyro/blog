---
title: 关于使用Java Mail 发邮件，连接超时问题
date: 2017-10-11 11:29:02
tags: [Spring Boot, Java]
categories: Java
---
# 异常信息
> send mail err:Mail server connection failed; nested exception is com.sun.mail.util.MailConnectException: Couldn't connect to host, port: smtp.qq.com, 25; timeout -1

## 在本地windows 是可以发送成功的
### 怀疑是端口问题，好吧，我用的是 25 端口，开了之后还是连接超时。
### 那么就很有可能是你的服务器的运营商将25端口封禁了！

### 换其他端口
### 我直接用springboot 的模板发邮件
#### 发邮件可看之前文章
#### 默认的配置如下：
```
spring.mail.host=smtp.qq.com
spring.mail.username=1006059906@qq.com
spring.mail.password=这个是你的授权码
spring.mail.properties.mail.smtp.auth=true
spring.mail.properties.mail.smtp.starttls.enable=true
spring.mail.properties.mail.smtp.starttls.required=true
spring.mail.default-encoding=UTF-8
```
#### 修改端口为465
```
spring.mail.host=smtp.qq.com
spring.mail.username=1006059906@qq.com
spring.mail.password=这个是你的授权码
spring.mail.properties.mail.smtp.auth=true
spring.mail.properties.mail.smtp.starttls.enable=true
spring.mail.properties.mail.smtp.starttls.required=true
spring.mail.default-encoding=UTF-8
spring.mail.port=465
spring.mail.properties.mail.smtp.socketFactory.port = 465
spring.mail.properties.mail.smtp.socketFactory.class = javax.net.ssl.SSLSocketFactory
spring.mail.properties.mail.smtp.socketFactory.fallback = false
```
### 这样就ok了，springboot 发邮件的示例代码：[https://github.com/rstyro/spring-boot/tree/master/springboot-mail](https://github.com/rstyro/spring-boot/tree/master/springboot-mail)

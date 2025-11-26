---
title: SpringBoot集成Jasypt给配置加密
tags: [Spring Boot, Java]
categories: Java
date: 2025-11-26 09:45:46
updated: 2025-11-26 09:45:46
---



## 一、什么是Jasypt？



Jasypt（Java Simplified Encryption）是一个强大的Java加密库，专门用于简化应用程序中的加密操作。在Spring Boot项目中，我们经常需要处理敏感配置信息（如数据库密码、API密钥等），Jasypt可以帮助我们**加密这些敏感配置**，避免明文存储的安全风险。



## 二、为什么需要Jasypt？

##### 传统配置的问题

```yaml
# application.yml - 不安全的方式！
spring:
  datasource:
    driverClassName: com.mysql.cj.jdbc.Driver
    url: jdbc:mysql://localhost:3306/my_db
    username: root # 用户名明文存储
    password: root # 密码明文存储
    
api:
  key: "sk-1234567890abcdef"        # API密钥明文存储
```

##### 使用Jasypt后的安全配置

```yaml
# application.yml - 安全的方式！
spring:
  datasource:
    driverClassName: com.mysql.cj.jdbc.Driver
    url: jdbc:mysql://localhost:3306/my_db
    username: "ENC(AbCdEfGhIjKlMnOpQrStUvWxYz0123456789==)" # 加密后的用户
    password: "ENC(AbCdEfGhIjKlMnOpQrStUvWxYz0123456789==)"  # 加密后的密码

api:
  key: "ENC(ZxYwVuTsRqPoNmLkJiHgFeDcBa9876543210==)"        # 加密后的API密钥
```



- 看到 `ENC(...)` 了吗？这就是被Jasypt加密后的密文。即使日志被打出来，即使代码被泄露，没有秘钥，黑客看到的也只是一串无意义的字符。



## 三、快速开始：Spring Boot集成Jasypt



### 1. 添加依赖

```xml
<properties>
    <jasypt-spring-boot.version>3.0.5</jasypt-spring-boot.version>
</properties>

<dependencies>
    <dependency>
        <groupId>com.github.ulisesbocchio</groupId>
        <artifactId>jasypt-spring-boot-starter</artifactId>
        <version>${jasypt-spring-boot.version}</version>
    </dependency>
</dependencies>
```

### 2. 基础配置

在`application.yml`中添加Jasypt配置：

```yaml
# Jasypt加密配置
jasypt:
  encryptor:
    # 加密密钥（非常重要！）, 优先从环境变量JASYPT_PASSWORD获取,默认：rstyro_#$%66dashun
    password: ${JASYPT_PASSWORD:rstyro_#$%66dashun}
    # 加密算法
    algorithm: PBEWITHHMACSHA512ANDAES_256
    # 随机盐
    salt-generator-classname: org.jasypt.salt.RandomSaltGenerator
    # 向量也是随机的
    iv-generator-classname: org.jasypt.iv.RandomIvGenerator
    property:
      prefix: "ENC("   # 加密值前缀，默认也是ENC(
      suffix: ")"   # 加密值后缀
```



> **安全提醒**：生产环境务必通过环境变量`JASYPT_PASSWORD`设置密钥，避免硬编码！



### 3、实战



#### ①、加密工具类

首先创建一个加密工具类，用于生成加密值：



```java
public class JasyptUtil {
    /**
     * 默认加密秘钥
     */
    private static final String SECRET_KEY = "rstyro_#$%66dashun";

    private static SimpleStringPBEConfig getPBEConfig() {
        SimpleStringPBEConfig config = new SimpleStringPBEConfig();
        // 加密密钥
        config.setPassword(SECRET_KEY);
        // 安全算法
        config.setAlgorithm("PBEWithHMACSHA512AndAES_256");
        // 使用随机IV提升安全性
        config.setIvGeneratorClassName("org.jasypt.iv.RandomIvGenerator");
        return config;
    }

    private static StandardPBEStringEncryptor getEncryptor() {
        StandardPBEStringEncryptor stringEncryptor = new StandardPBEStringEncryptor();
        stringEncryptor.setConfig(getPBEConfig());
        return stringEncryptor;
    }

    public static String encrypt(String data) {
        return getEncryptor().encrypt(data);
    }


    public static String decrypt(String data) {
        return getEncryptor().decrypt(data);
    }

	/**
     * 快速测试加密效果
     */
    public static void main(String[] args) {
        String rawPassword = "your_sensitive_data";
        String encrypted = encrypt(rawPassword);
        System.out.println("原始数据: " + rawPassword);
        System.out.println("加密结果: " + encrypted);
        System.out.println("解密验证: " + decrypt(encrypted));
    }
}
```

- 使用 `encrypt(data)` 进行加密，得到密文，`decrypt(data)` 解密得到明文





#### ②、 配置文件使用加密值



```yaml
spring:
  application:
    name: springboot-jasypt
  datasource:
    type: com.alibaba.druid.pool.DruidDataSource
    driverClassName: com.mysql.cj.jdbc.Driver
    url: jdbc:mysql://localhost:3306/neighbor?useUnicode=true&characterEncoding=utf-8&useSSL=false&serverTimezone=Hongkong&autoReconnect=true&allowPublicKeyRetrieval=true
    username: ENC(WaH05jih3tX0v/orZkYwbXcIIs3yD0VXAKmKn962FSxDhgtGFAj3fBN58Ye/6kZ2)
    password: ENC(WaH05jih3tX0v/orZkYwbXcIIs3yD0VXAKmKn962FSxDhgtGFAj3fBN58Ye/6kZ2)


# Jasypt加密配置
jasypt:
  encryptor:
    # 加密密钥（非常重要！）, 优先从环境变量获取
    password: ${JASYPT_PASSWORD:rstyro_#$%66dashun}
    # 加密算法
    algorithm: PBEWITHHMACSHA512ANDAES_256
    # 随机盐
    salt-generator-classname: org.jasypt.salt.RandomSaltGenerator
    # 向量也是随机的
    iv-generator-classname: org.jasypt.iv.RandomIvGenerator
    property:
      prefix: "ENC("   # 加密值前缀，默认也是ENC(
      suffix: ")"   # 加密值后缀

```



- 如上，我们的数据库用户名和密码都是使用加密值：`ENC()`

#### ③、测试一下配置获取

新建一个controller,`JasyptController`



```java
@RestController
@RequestMapping("/jasypt")
public class JasyptController {

    @Resource
    private Environment environment;

    @GetMapping("/getConfig")
    public Object getConfig(String key){
        // 动态获取配置文件的key
        return environment.getProperty(key);
    }
}
```



- 启动服务请求一下：`http://localhost:8080/jasypt/getConfig?key=spring.datasource.password`
- 验证一下我们是可以得到明文的，对我们的业务不会产生影响



![验证接口](valid.png)



- **验证成功！** Spring Boot自动解密，业务代码无感知使用！



## 四、总结



Jasypt提供的是一种“**低侵入、高收益**”的解决方案。它就像一个忠诚的卫士，用最简单的方式，为你的应用配置筑起了一道坚实的安全防线。

**从此，你再也不用担心配置泄露.**




#### 资源获取：

本文完整代码已上传至 GitHub，欢迎 Star ⭐ 和 Fork

- Gitee地址：https://gitee.com/rstyro/spring-boot/tree/master/springboot-jasypt
- Github地址：https://github.com/rstyro/Springboot/tree/master/springboot-jasypt



**欢迎分享你的经验**：
在实际使用`Jasypt`时，你有哪些独到的见解或踩坑经验？欢迎在评论区交流讨论，让我们一起进步
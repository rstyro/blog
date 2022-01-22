---
title: SpringCloud-Alibaba之Nacos的配置中心
date: 2020-12-04 17:41:20
updated: 2020-12-04 17:41:20
tags: [SpringCloud,SpringCloud-Alibaba,Nacos]
categories: Java
---
## 一、简介
Nacos 提供用于存储配置和其他元数据的 key/value 存储，为分布式系统中的外部化配置提供服务器端和客户端支持。使用 Spring Cloud Alibaba Nacos Config，您可以在 Nacos Server 集中管理你 Spring Cloud 应用的外部属性配置。

Spring Cloud Alibaba Nacos Config 是 Config Server 和 Client 的替代方案，客户端和服务器上的概念与 Spring Environment 和 PropertySource 有着一致的抽象，在特殊的 bootstrap 阶段，配置被加载到 Spring 环境中。当应用程序通过部署管道从开发到测试再到生产时，您可以管理这些环境之间的配置，并确保应用程序具有迁移时需要运行的所有内容。


上面是官方的[wiki](https://github.com/alibaba/spring-cloud-alibaba/wiki/Nacos-config) 的介绍，简单点说：nacos不只能用作注册中心还能用作配置中心。

## 二、快速开始
首先需要启动Nacos

### 1、导入依赖
```
<dependency>
	<groupId>com.alibaba.cloud</groupId>
	<artifactId>spring-cloud-starter-alibaba-nacos-config</artifactId>
</dependency>

<dependency>
	<groupId>org.springframework.boot</groupId>
	<artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```

### 2、添加配置文件
不能使用原来的`application.yml`作为配置文件，而是新建一个`bootstrap.yml`作为配置文件。
spring 配置文件优先级(由高到低): `bootstrap.properties` -> `bootstrap.yml` -> `application.properties` -> `application.yml`。

**bootstrap.yml**如下：
```
spring:
  application:
    name: nacos-config
  profiles:
    active: dev
  cloud:
    nacos:
      config:
        server-addr: 127.0.0.1:8848
        file-extension: yaml
```

这个配置需要和 Nacos上的`Data Id` 保持一致,如下图：

![](config.png)

> 这里还有注意一点，`spring.cloud.nacos.config.server-addr=your.name.com:80` 这里如果是域名的话，也不要漏了端口。


### 3、代码里面的使用

+ 首先在Nacos控制台添加一条默认组，`Data Id`=`nacos-config-dev.yaml`的配置,Data ID 要和配置文件配置的名称一致。
+ 在上面的`nacos-config-dev.yaml`添加如下内容：
```
user:
    name: rstyro-dev
    age: 23
```
+ `spring-cloud-starter-alibaba-nacos-config` 在加载配置的时候，
+ 不仅仅加载了以dataid 为 `${spring.application.name}.${file-extension:properties}` 为前缀的基础配置，
+ 还加载了dataid为 `${spring.application.name}-${profile}.${file-extension:properties}` 的基础配置。
+ 在日常开发中如果遇到多套环境下的不同配置，可以通过Spring 提供的 `${spring.profiles.active}` 这个配置项来配置。
+ 代码里面就可以直接使用`@Value` 进行访问，或者上下文环境获取。如下：

```
@RequestMapping("/config")
@RestController
@RefreshScope
public class TestController {

    @Value("${user.name}")
    private String name;
	
	@Autowired
    private ConfigurableApplicationContext applicationContext;


	@GetMapping("/getName1")
    public String getName1() {
        return applicationContext.getEnvironment().getProperty("user.name");
    }

    @GetMapping("/getName2")
    public String getName2() {
        return this.name;
    }


}
```
+ `@RefreshScope` 支持动态刷新，我们去Nacos控制台修改，再请求发现值变了。


### 4、配置自定义空间（Namespace）
首先看一下 Nacos 的 Namespace 的[概念](https://nacos.io/zh-cn/docs/concepts.html)
> 用于进行租户粒度的配置隔离。不同的命名空间下，可以存在相同的 Group 或 Data ID 的配置。Namespace 的常用场景之一是不同环境的配置的区分隔离，例如开发测试环境和生产环境的资源（如配置、服务）隔离等

+ 在没有明确指定 `${spring.cloud.nacos.config.namespace}` 配置的情况下， 默认使用的是 Nacos 上 `Public` 这个namespae。
+ 如果需要使用自定义的命名空间，可以通过以下配置来实现：
+ `spring.cloud.nacos.config.namespace=aa0e66cf-3907-4944-bed6-7b493ca1eafb`
+ namespace 对应的是 id，id 值可以在 Nacos 的控制台获取。

### 5、配置自定义 Group 
+ 在没有明确指定 `${spring.cloud.nacos.config.group}` 配置的情况下， 
+ 默认使用的是 `DEFAULT_GROUP` 。如果需要自定义自己的 Group，可以通过以下配置来实现：
+ `spring.cloud.nacos.config.group=DEVELOP_GROUP`
+ 该配置必须放在 `bootstrap.properties` 文件中。并且在添加配置时 Group 的值一定要和 `spring.cloud.nacos.config.group` 的配置值一致。


### 6、支持自定义扩展的 Data Id 配置

```
spring.application.name=opensource-service-provider
spring.cloud.nacos.config.server-addr=127.0.0.1:8848

# config external configuration
# 1、Data Id 在默认的组 DEFAULT_GROUP,不支持配置的动态刷新
spring.cloud.nacos.config.extension-configs[0].data-id=ext-config-common01.properties

# 2、Data Id 不在默认的组，不支持动态刷新
spring.cloud.nacos.config.extension-configs[1].data-id=ext-config-common02.properties
spring.cloud.nacos.config.extension-configs[1].group=GLOBALE_GROUP

# 3、Data Id 既不在默认的组，也支持动态刷新
spring.cloud.nacos.config.extension-configs[2].data-id=ext-config-common03.properties
spring.cloud.nacos.config.extension-configs[2].group=REFRESH_GROUP
spring.cloud.nacos.config.extension-configs[2].refresh=true
```

> 多个 `Data Id` 同时配置时，他的优先级关系是 `spring.cloud.nacos.config.extension-configs[n].data-id` 其中 `n` 的值越大，优先级越高。
+ `spring.cloud.nacos.config.extension-configs[n].data-id` 的值必须带文件扩展名，文件扩展名既可支持 properties，又可以支持 yaml/yml。
+ 此时 `spring.cloud.nacos.config.file-extension` 的配置对自定义扩展配置的 `Data Id` 文件扩展名没有影响。

### 7、配置共享的 Data Id 配置
+ 通过自定义扩展的 Data Id 配置，既可以解决多个应用间配置共享的问题，又可以支持一个应用有多个配置文件。
+ 为了更加清晰的在多个应用间配置共享的 Data Id ，你可以通过以下的方式来配置：
```
# 配置支持共享的 Data Id
spring.cloud.nacos.config.shared-configs[0].data-id=common.yaml

# 配置 Data Id 所在分组，缺省默认 DEFAULT_GROUP
spring.cloud.nacos.config.shared-configs[0].group=GROUP_APP1

# 配置Data Id 在配置变更时，是否动态刷新，缺省默认 false
spring.cloud.nacos.config.shared-configs[0].refresh=true
```

## 三、简单的完整配置文件demo
简单的例子如下：
**bootstrap.yml**
```
spring:
  application:
    name: nacos-config
  profiles:
    active: dev
  cloud:
    nacos:
      config:
        server-addr: 127.0.0.1:8848
        file-extension: yaml
        namespace: aa0e66cf-3907-4944-bed6-7b493ca1eafb
        group: DEFAULT_GROUP
        username: nacos
        password: rstyro
        # 共享配置
        shared-configs[0]:
          data-id: share-config.yaml
          group: DEFAULT_GROUP
          refresh: true
        # 自定义扩展配置
        extension-configs[0]:
          data-id: ext-config.yaml
          group: DEFAULT_GROUP
          refresh: true

```

![](config-dev.png)


### 参考官方:[wiki](https://github.com/alibaba/spring-cloud-alibaba/wiki/Nacos-config)
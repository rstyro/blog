---
title: SpringCloud （八）、Zuul 服务网关
date: 2018-05-26 23:20:00
tags: [SpringCloud]
categories: Java
---
**举个栗子，在一个大型的购物网站中，以微服务架构进行拆分，会分为很多种服务，比如购物车、订单服务、评论服务、库存服务、用户服务等等，服务相互之间调用，那么就会产生很多个链接地址，如果有成百上千个服务之间进行调用，那么维护起来是很麻烦的，所以根据环境需要就产生了服务网关。
什么是服务网关，简单的说它就是一个中转站或者叫转发器，我们每次请求只需要去网关即可，而不需要去具体的服务请求，为了方便理解，看下面两张图**
![](14068.png)
下面是加了网关API之后
![](32768.png)

**API 网关负责服务请求路由、组合及协议转换。客户端的所有请求都首先经过 API 网关，然后由它将请求路由到合适的微服务。API 网关经常会通过调用多个微服务并合并结果来处理一个请求。它可以在 web 协议（如 HTTP 与 WebSocket）与内部使用的非 web 友好协议之间转换。**

**API 网关还能为每个客户端提供一个定制的 API。通常，它会向移动客户端暴露一个粗粒度的 API。以产品详情的场景为例，API 网关可以提供一个端点（/productdetails?productid=xxx），使移动客户端可以通过一个请求获取所有的产品详情。API 网关通过调用各个服务（产品信息、推荐、评论等等）并合并结果来处理请求。**

**Netflix API 网关是一个很好的 API 网关实例。Netflix 流媒体服务提供给成百上千种类型的设备使用，包括电视、机顶盒、智能手机、游戏系统、平板电脑等等。**

**最初，Netflix 试图为他们的流媒体服务提供一个通用的 API。然而他们发现，由于各种各样的设备都有自己独特的需求，这种方式并不能很好地工作。如今，他们使用一个 API 网关，通过运行与针对特定设备的适配器代码，来为每种设备提供定制的 API。通常，一个适配器通过调用平均 6 到 7 个后端服务来处理每个请求。Netflix API 网关每天处理数十亿请求。**

#### API 网关的优点和缺点
如你所料，使用 API 网关有优点也有不足。使用 API `网关的最大优点`是，它封装了应用程序的内部结构。客户端只需要同网关交互，而不必调用特定的服务。API 网关为每一类客户端提供了特定的 API，这减少了客户端与应用程序间的交互次数，还简化了客户端代码。

** `API 网关也有一些不足。`它增加了一个我们必须开发、部署和维护的高可用组件。还有一个风险是，API 网关变成了开发瓶颈。为了暴露每个微服务的端点，开发人员必须更新 API 网关。API网关的更新过程要尽可能地简单，这很重要；否则，为了更新网关，开发人员将不得不排队等待。不过，虽然有这些不足，但对于大多数现实世界的应用程序而言，使用 API 网关是合理的。**

**说了那么多来看代码实现吧**

### 代码实现
**老思路...**
### 一、添加依赖
```
<dependency>
	<groupId>org.springframework.cloud</groupId>
	<artifactId>spring-cloud-starter-zuul</artifactId>
</dependency>
```
### 二、添加注解
在启动类添加`@EnableZuulProxy`注解
```java
@SpringBootApplication
@EnableZuulProxy
public class SpringcloudZuulApplication {

	public static void main(String[] args) {
		SpringApplication.run(SpringcloudZuulApplication.class, args);
	}
	
}
```
### 三、配置文件application.yml
下面配置文件中，有12个例子

```
server:
  port: 8980
eureka:
  client:
    service-url:
      defaultZone: http://rstyro:rstyropwd@localhost:8761/eureka
spring:
  application:
    name: springcloud-gateway-zuul   
  profiles:
    active: zuul_demo1
# 例子1，zuul 默认是对所有 eureka 服务 进行反向代理
---  
spring:
  profiles: zuul_demo1


# 例子2，配置服务别名
---  
spring:
  profiles: zuul_demo2
# routes 下的就是配置别名，：格式： 服务名称(service ID): /别名/**,不配的话用默认的服务名称
zuul:
  routes:
    producer: /pro/**
    customer-ribbon: /customer/**
    
# 例子3，`ignoredServices: * `--不反向代理，*代表所有服务，只反向代理 routes 下面配置的服务，如下例子是只代理 customer-ribbon 服务
---
spring:
  profiles: zuul_demo3
zuul:
  ignoredServices: '*'
  routes:
    customer-ribbon: /customer/**
 
# 例子4: ignoredServices:不反向代理指定的服务(多个用逗号隔开)，但是如果routes 下面配置了，可以请求配置后的服务别名
---
spring:
  profiles: zuul_demo4
zuul:
  ignoredServices: producer,customer-ribbon
  routes:
    customer-ribbon: /customer/**

# 例子5,更细粒度的配置，serviceTestName 是随便取的
---
spring:
  profiles: zuul_demo5
zuul:
  routes:   
    serviceTestName:
        path: /pro-serviceid/**
        serviceId: producer
        
# 例子6,可以把serviceId 换成url
---
spring:
  profiles: zuul_demo6
zuul:
  routes:   
    serviceTestName:
        path: /pro-url/**
        url: http://192.168.1.101:7900/
    
# 例子7,配置负载均衡
---
spring:
  profiles: zuul_demo7
zuul:
  routes:   
    serviceTestName:
        path: /pro/**
        serviceId: producer
ribbon:
  eureka:
    enabled: false

producer:
  ribbon:
    listOfServers: http://192.168.1.101:7900/,http://192.168.1.101:7901

# 例子8,访问的时候加前缀 /api, 比如：http://localhost:8980/api/producer/item/1
---
spring:
  profiles: zuul_demo8
zuul:
  prefix: /api

# 例子9.如下配置，如果要访问 http://localhost:7900/item/1 的服务，，应为: http://localhost:8980/item/producer/1
# 全局配置
---
spring:
  profiles: zuul_demo9
zuul:
  prefix: /item
  stripPrefix: false
logging:
  level:
    com.netflix: debug
 
# 例子10
# 局部配置   
---
spring:
  profiles: zuul_demo10
zuul:
  routes:
    producer:
      path: /item/**
      stripPrefix: false
#  prefix: /item
#  stripPrefix: false
logging:
  level:
    com.netflix: debug

# 例子11    
# Strangulation Patterns and Local Forwards,绞杀者模式与本地转发
# forward: 后面接的是本地的转发地址
---
spring:
  profiles: zuul_demo11
zuul:
  routes:
    producer:
      path: /item/**
      url: forward:/item
    customer:
      path: /provider/**
      url: http://localhost:7900/item
    legacy:
      path: /**
      url: http://localhost:7900
logging:
  level:
    com.netflix: debug

# 例子12
# 上传，下面是配置超时时间，通过zuul 代理请求时在服务地址前缀加/zuul ,即可跳过spring 限制上传的大小。比如下面的地址
#  http://192.168.1.101:8980/zuul/file-upload/upload
# 正常是这样子的:http://192.168.1.101:8980/file-upload/upload
---
spring:
  profiles: zuul_demo12
  
hystrix.command.default.execution.isolation.thread.timeoutInMilliseconds: 600000
ribbon:
  ConnectTimeout: 5000
  ReadTimeout: 600000
  
```
完整的[Github代码地址](https://github.com/rstyro/SpringCloud/tree/master/SpringCloud-zuul)


 访问`producer`服务的接口`/producer/vipAddress` 请求地址为 `http://192.168.1.101:8980/producer/vipAddress`，也可以这样`http://192.168.1.101:8980/zuul/producer/vipAddress`
 
 前缀加上`/zuul` 这个可以绕过Spring 的DispatcherServlet，比如上传文件时，绕过文件上传的大小限制。看文档
 ![](97810.png)
 我们可以测试下
 上传的代码如下：
 上传成功后返回成功后的文件路径
 #### 上传项目
 ##### 1、代码片段
 ```java
 @RestController
public class UploadController {

	@PostMapping("/upload")
	public Object uploadFile(@RequestParam(value="file",required=true)MultipartFile file) throws IOException {
		if (file.isEmpty()) {
            return null;
        }
		String filePath  = "E:\\"+System.currentTimeMillis()+"_"+file.getOriginalFilename();
		file.transferTo(new File(filePath));
		return filePath;
	}
}
 ```
##### 2、配置文件
```
server:
  port: 8600
eureka:
  client:
    service-url:
      defaultZone: http://rstyro:rstyropwd@localhost:8761/eureka

spring:
  application:
    name: file-upload
  http:
    multipart:
      max-file-size: 2000MB     #默认1M
      max-request-size: 2000MB  #默认10m
```
##### 完整的上传 [Github代码地址](https://github.com/rstyro/SpringCloud/tree/master/SpringCloud-file-upload)
##### 3、测试
Eureka 服务注册情况，下面的`红字`，代表eureka进入了 `自我保护模式`
![](83215.png)
**准备工作**
需要`curl` 工具，window 可在[https://curl.haxx.se/download.html](https://curl.haxx.se/download.html)进行下载
启动zuul ,使用如上的项目，配置选择 `zuul_demo12` 的 profiles

通过zuul 访问 上传路径为：[http://localhost:8980/file-upload/upload](http://localhost:8980/file-upload/upload)
先上传一个小文件`doc.sql` 发现是可以成功的，
但是上传一个大文件`a11.wnv` 报了` because its size (551282098) exceeds the configured maximum (10485760)` 的错误，
意思是超过文件上传的大小限制 `10485760 b` ，
后面我们在上传的地址前加了 `/zuul` 发现上传成功了。测试过程如下图：
![](26879.png)


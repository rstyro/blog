---
title: SpringCloud （一）、服务注册与发现
date: 2018-05-07 14:51:35
updated: 2018-05-07 14:51:35
tags: [SpringCloud]
categories: Java
---
# 微服务架构
**“微服务架构” 在之前几年久很火爆了，以至于现在关于微服务的文章很多，资料也是海量，社区同样也是很活跃。
	微服务架构 的两大主流 应该就是SpringCloud 与 dubbo 了。
	说了那么多，微服务是什么呢？
	简单的说，微服务架构就是将一个完整的应用垂直拆分成多个不同的服务，每个服务都是一个个体，可以独立部署、独立维护、独立扩展、服务与服务之间
	通过诸如RESTful API 的方式相互调用。**

## Spring Cloud 简介
**Spring Cloud是一个基于Spring Boot实现的云应用开发工具，它为基于JVM的云应用开发中涉及的配置管理、服务发现、断路器、智能路由、微代理、控制总线、全局锁、决策竞选、分布式会话和集群状态管理等操作提供了一种简单的开发方式。**

**Spring Cloud包含了多个子项目（针对分布式系统中涉及的多个不同开源产品），比如：Spring Cloud Config、Spring Cloud Netflix、Spring Cloud0 CloudFoundry、Spring Cloud AWS、Spring Cloud Security、Spring Cloud Commons、Spring Cloud Zookeeper、Spring Cloud CLI等项目。**

**[Github地址](https://github.com/spring-cloud)**


## 服务治理
**假设现在有两个服务接口 ，一个是生产者（producer）,一个是消费者（customer）,customer 现在要调用producer，可以通过RestTemplate 进行调用，比如**
```
@GetMapping("/provider/{id}")
public Object test(@PathVariable("id") String id) {
	//producerServicePath 是生产者服务提供的接口
	return restTemplate.getForObject(producerServicePath+id,Object.class);
}
```

**这样就产生一个问题，我们发现producerServicePath 这个地址是写死的，硬编码了，对后期维护是很不方便的。所以需要一个服务注册中心，我们只需要向服务中心请求具体的服务名即可，不需要知道具体的请求地址。
这服务注册中心怎么实现呢，Springcloud 支持多种的服务治理框架，比如：Eureka、Consul、Zookeeper....，
选一种 那就Eureka 吧。因为啥，因为我喜欢啊。哈哈 
Spring Cloud Eureka是Spring Cloud Netflix项目下的服务治理模块。而Spring Cloud Netflix项目是Spring Cloud的子项目之一，主要内容是对Netflix公司一系列开源产品的包装，它为Spring Boot应用提供了自配置的Netflix OSS整合。通过一些简单的注解，开发者就可以快速的在应用中配置一下常用模块并构建庞大的分布式系统。它主要提供的模块包括：服务发现（Eureka），断路器（Hystrix），智能路由（Zuul），客户端负载均衡（Ribbon）等。**

## 创建服务注册中心
SpringCloud 有几个版本，我现在用的是`Dalston SR5`
### 一、引入依赖

```
	<parent>
		<groupId>org.springframework.boot</groupId>
		<artifactId>spring-boot-starter-parent</artifactId>
		<version>1.5.12.RELEASE</version>
		<relativePath/> <!-- lookup parent from repository -->
	</parent>
	  <dependencyManagement>
	    <dependencies>
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-dependencies</artifactId>
            <version>Dalston.SR5</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
    </dependencies>
	</dependencyManagement>
  <dependencies>

		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-test</artifactId>
			<scope>test</scope>
		</dependency>
	    
	   <dependency>
			<groupId>org.springframework.cloud</groupId>
			<artifactId>spring-cloud-starter-eureka-server</artifactId>
		</dependency>
		
		<!-- 安全认证 -->
		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-security</artifactId>
		</dependency>
		
  </dependencies>

```
### 二、加入注解
**在启动类加入 `@EnableEurekaServer` 注解,如下例子**
```java
@SpringBootApplication
@EnableEurekaServer
public class SpringcloudEurekaApplication {

	public static void main(String[] args) {
		SpringApplication.run(SpringcloudEurekaApplication.class, args);
	}
	
}
```
### 三、配置application.yml
**`eureka.client.registerWithEureka` ：表示是否将自己注册到Eureka Server，默认为true。由于当前这个应用就是Eureka Server，故而设为false。
`eureka.client.fetchRegistry` ：表示是否从Eureka Server获取注册信息，默认为true。因为这是一个单点的Eureka Server，不需要同步其他的Eureka Server节点的数据，故而设为false。
`eureka.client.serviceUrl.defaultZone` ：设置与Eureka Server交互的地址，查询服务和注册服务都需要依赖这个地址。默认是http://localhost:8761/eureka ；多个地址可使用 , 分隔。**

**Eureka的配置类所在类**
```java
org.springframework.cloud.netflix.eureka.EurekaInstanceConfigBean
org.springframework.cloud.netflix.eureka.EurekaClientConfigBean
org.springframework.cloud.netflix.eureka.server.EurekaServerConfigBean
```
```
# security 这个的配置是当访问eureka时需要登陆，不要也是可以的
security:
  basic:
    enabled: true
  user:
    name: rstyro
    password: rstyropwd

server:
  port: 8761

eureka:
  client:
    register-with-eureka: false
    fetch-registry: false
    service-url:
      defaultZone: http://rstyro:rstyropwd@localhost:8761/eureka
```
### 启动
启动，访问: [http://localhost:8761/](http://localhost:8761/)
![](67359.png)
输入用户名（rstyro）密码(rstyropwd) 登陆之后显示如下的界面，说明启动成功
![](87412.png)
看 `Instances currently registered with Eureka` 是空的，当前还没有什么服务注册进来
## 创建生产者
### 一、引入依赖
```
	<parent>
		<groupId>org.springframework.boot</groupId>
		<artifactId>spring-boot-starter-parent</artifactId>
		<version>1.5.12.RELEASE</version>
		<relativePath/> <!-- lookup parent from repository -->
	</parent>
	  <dependencyManagement>
	    <dependencies>
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-dependencies</artifactId>
            <version>Dalston.SR5</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
    </dependencies>
	</dependencyManagement>
	<dependencies>

		<dependency>
			<groupId>org.springframework.cloud</groupId>
			<artifactId>spring-cloud-starter-eureka</artifactId>
		</dependency>

		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-actuator</artifactId>
		</dependency>
		
  </dependencies>
```
### 二、加入注解
**在启动类加入`@EnableEurekaClient`注解**
```java
@SpringBootApplication
@EnableEurekaClient
public class ProducerApplication {
	public static void main(String[] args) {
		SpringApplication.run(ProducerApplication.class, args);
	}
}
```
### 三、配置application
```
# rstyro:rstyropwd 是在eureka 中配置的用户名和密码，如果不配的话，这里不写
eureka:
  client:
    serviceUrl:
      defaultZone: http://rstyro:rstyropwd@localhost:8761/eureka
  instance:
    prefer-ip-address: true
spring:
  application:
    name: producer
    
server:
  port: 7900
 
```

## 创建消费者
**和创建生产者的代码是差不多一样的，这里就不写出来了。
启动 生产者和消费者，刷新Eureka 界面**
![](96537.png)

**发现我们的两个服务已经注册进来了,说明我们的两个服务已经成功注册到Eureka里面去了
接下来讲如何不需要写硬编码，使用Ribbon**

**可以参考：[SpringCloud文档](http://cloud.spring.io/spring-cloud-static/Dalston.SR5/single/spring-cloud.html#_service_discovery_eureka_clients)**

#### [Github代码示例](https://github.com/rstyro/SpringCloud)

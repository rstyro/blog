---
title: SpringCloud （四）、Eureka高可用
date: 2018-05-25 15:35:03
tags: [SpringCloud]
categories: Java
---
# Eureka 高可用
**前面讲的例子，都离不开Eureka服务，如果说eureka 突然宕机了，那是不是所有的服务都没法用了。所以我们怎么也得弄几台才行啊**
我们看看官方文档的例子：
![](07841.png)

[文档地址](http://cloud.spring.io/spring-cloud-static/Dalston.SR5/single/spring-cloud.html#_peer_awareness)

**自己动手来吧**
## 一、导入依赖
```
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
  </dependencies>
```

## 二、添加注解
**给启动类添加`@EnableEurekaServer`注解**
```
@SpringBootApplication
@EnableEurekaServer
public class SpringcloudEurekaPeerApplication {

	public static void main(String[] args) {
		SpringApplication.run(SpringcloudEurekaPeerApplication.class, args);
	}
	
}
```
## 三、修改配置文件application.yml
这里我配置了3个节点
```
spring:
  application:
    name: Eureka-peer
  profiles:
    active: peer1
---
server:
  port: 8761
spring:
  profiles: peer1
eureka:
  instance:
    hostname: peer1
  client:
    serviceUrl:
      defaultZone: http://peer2:8762/eureka/,http://peer3:8763/eureka/

---
server:
  port: 8762
spring:
  profiles: peer2
eureka:
  instance:
    hostname: peer2
  client:
    serviceUrl:
      defaultZone: http://peer1:8761/eureka/,http://peer3:8763/eureka/
---
server:
  port: 8763
spring:
  profiles: peer3
eureka:
  instance:
    hostname: peer3
  client:
    serviceUrl:
      defaultZone: http://peer2:8762/eureka/,http://peer1:8761/eureka/
```

### 四、修改host文件
**添加如下内容**
```
127.0.0.1       peer1 peer2 peer3
```
![](47031.png)

**如果这个不配的话，它们3个是ping不通的**

**启动3个不同的profiles，然后访问：
[http://peer1:8761/](http://peer1:8761/)、
[http://peer2:8762/](http://peer1:8761/)、
[http://peer3:8763/](http://peer1:8761/)**
结果几乎差不多，说明我们已经配置成功了，如果我们再启动一个生产者，生产者的eureka地址只需要写其中3个的一个，访问这3个节点，他们的注册列表都会有这个服务
![](69704.png)

**[Github 代码示例](https://github.com/rstyro/SpringCloud/tree/master/SpringCloud-eurekaserver-peer)**

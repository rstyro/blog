---
title: SpringCloud （三）、Feign使用示例
date: 2018-05-25 14:29:25
tags: [SpringCloud]
categories: Java
---
# Feign

**Feign是一个声明式的Web Service客户端，它使得编写Web Serivce客户端变得更加简单。我们只需要使用Feign来创建一个接口并用注解来配置它既可完成。它具备可插拔的注解支持，包括Feign注解和JAX-RS注解。Feign也支持可插拔的编码器和解码器。Spring Cloud为Feign增加了对Spring MVC注解的支持，还整合了Ribbon和Eureka来提供均衡负载的HTTP客户端实现。**

**Spring Cloud Netflix 的微服务都是以 HTTP 接口的形式暴露的，所以可以用 Apache 的 HttpClient 或 Spring 的 RestTemplate 去调用，而 Feign 是一个使用起来更加方便的 HTTP 客戶端，使用起来就像是调用自身工程的方法，而感觉不到是调用远程方法**

## 代码实现
**结尾有Github地址的代码示例**
## 一、使用SpringMVC注解
### 1、添加依赖
```
<dependency>
	<groupId>org.springframework.cloud</groupId>
	<artifactId>spring-cloud-starter-feign</artifactId>
</dependency>
```
### 2、加注解
在启动类上加注解`@EnableFeignClients`
```
@SpringBootApplication
@EnableEurekaClient
@EnableFeignClients
public class CustomerFeignApplication {
	
    public static void main( String[] args ){
      SpringApplication.run(CustomerFeignApplication.class, args);
    }
    
}
```
### 3、创建服务接口类
定义一个 `producer` 服务的接口类
```
@FeignClient(name="producer")
public interface FeignClientService {

	@RequestMapping(value="/item/{id}",method=RequestMethod.GET)
	public Object detai(@PathVariable("id") String id);
	
	
	@RequestMapping(value="/add",method=RequestMethod.POST)
	public Object add(Item item);
}
```

### 4、控制层调用
```
@RestController
public class TestController {
	
	@Autowired
	private FeignClientService feignClientService;
	
	@GetMapping("/provider/{id}")
	public Object test(@PathVariable String id) {
		return feignClientService.detai(id);
	}
	
	@GetMapping("/add")
	public Object test(Item item) {
		return feignClientService.add(item);
	}
}
```
### 5、配置文件
其实配置文件`application.yml`没什么特殊的
```
server:
  port: 8903
  
eureka:
  client:
    serviceUrl:
      defaultZone: http://rstyro:rstyropwd@localhost:8761/eureka
  instance:
    prefer-ip-address: true
spring:
  application:
    name: customer-feign
```
启动eureka 和两个生产者与feign,查看结果，还是实现了负载均衡
![](/SpringCloud （三）、Feign使用示例/26754.png)
![](/SpringCloud （三）、Feign使用示例/14630.png)
![](/SpringCloud （三）、Feign使用示例/08295.png)

**上面我们用的是`SpringMVC` 的注解,下面我们用feign 默认的注解，查看[Github的地址](https://github.com/OpenFeign/feign) 里面介绍了基本用法**

## 二、使用默认的注解
### 1、自定义一个配置类FeignConfig
```
@Configuration
public class FeignConfig {

	/**
	 * 使用它的默认配置
	 * 
	 * @return
	 */
	@Bean
	public Contract feignContract() {
		return new feign.Contract.Default();
	}
	
	/**
	 * 加日志的
	 * http://cloud.spring.io/spring-cloud-static/Dalston.SR5/single/spring-cloud.html#_feign_logging
	 * @return
	 */
	@Bean
    Logger.Level feignLoggerLevel() {
        return Logger.Level.FULL;
    }

}
```
### 2、自定义一个服务接口类FeignClientService
```
@FeignClient(name="producer",configuration=FeignConfig.class)
public interface FeignClientService {

	//https://github.com/OpenFeign/feign 有例子
	@RequestLine("GET /item/{id}")
	public Object detai(@Param("id") String id);
	
	
	@RequestLine("POST /add")
	public Object add(Item item);
}
```

### 3、调用
```
@RestController
public class TestController {
	
	@Autowired
	private FeignClientService feignClientService;
	
	
	@GetMapping("/provider/{id}")
	public Object test(@PathVariable String id) {
		return feignClientService.detai(id);
	}
	
	@GetMapping("/add")
	public Object test(Item item) {
		return feignClientService.add(item);
	}
	
}
```
### 4、配置文件
如果机子的性能比较差什么的，第一次请求会报一个请求超时异常，解决方案看下面配置文件
```
server:
  port: 8904
  
eureka:
  client:
    serviceUrl:
      defaultZone: http://rstyro:rstyropwd@localhost:8761/eureka
  instance:
    prefer-ip-address: true
spring:
  application:
    name: customer-feign-default
   

logging:
  level:
    top.lrshuai.cloud.springcloud.feign.FeignClientService: DEBUG
    
# 解决第一次请求报超时异常的方案：
hystrix.command.default.execution.isolation.thread.timeoutInMilliseconds: 5000
# 或者：
# hystrix.command.default.execution.timeout.enabled: false
# 或者：
# feign.hystrix.enabled: false ## 索性禁用feign的hystrix

```
##### 超时的issue：https://github.com/spring-cloud/spring-cloud-netflix/issues/768
##### 超时的解决方案： http://stackoverflow.com/questions/27375557/hystrix-command-fails-with-timed-out-and-no-fallback-available
##### hystrix配置： https://github.com/Netflix/Hystrix/wiki/Configuration#execution.isolation.thread.timeoutInMilliseconds


##### 上面的Github代码地址：[demo1](https://github.com/rstyro/SpringCloud/tree/master/SpringCloud-customer-feign)、[demo2](https://github.com/rstyro/SpringCloud/tree/master/SpringCloud-customer-feign-default)



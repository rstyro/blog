---
title: SpringCloud （六）、断路器模式
date: 2018-05-26 12:50:04
updated: 2018-05-26 12:50:04
tags: [SpringCloud]
categories: Java
---
**在微服务架构中，我们将系统拆分成了一个个的服务单元，各单元间通过服务注册与订阅的方式互相依赖。由于每个单元都在不同的进程中运行，依赖通过远程调用的方式执行，这样就有可能因为网络原因或是依赖服务自身问题出现调用故障或延迟，而这些问题会直接导致调用方的对外服务也出现延迟，若此时调用方的请求不断增加，最后就会出现因等待出现故障的依赖方响应而形成任务积压，最终导致自身服务的瘫痪。这就是传说中的`雪崩效应` 或者叫 `级联失败`。**

![](98152.png)

#### 为了解决这种服务之间的级联失败，所以产生了一种模式叫做`断路器模式`

### 什么是断路器

**断路器模式源于Martin Fowler的Circuit Breaker一文。“断路器”本身是一种开关装置，用于在电路上保护线路过载，当线路中有电器发生短路时，“断路器”能够及时的切断故障电路，防止发生过载、发热、甚至起火等严重后果。
在分布式架构中，断路器模式的作用也是类似的，当某个服务单元发生故障（类似用电器发生短路）之后，通过断路器的故障监控（类似熔断保险丝），向调用方返回一个错误响应，而不是长时间的等待。这样就不会使得线程因调用故障服务被长时间占用不释放，避免了故障在分布式系统中的蔓延。**

### Netflix Hystrix

**在Spring Cloud中使用了Hystrix 来实现断路器的功能。[Hystrix](https://github.com/Netflix/hystrix)是Netflix开源的微服务框架套件之一，该框架目标在于通过控制那些访问远程系统、服务和第三方库的节点，从而对延迟和故障提供更强大的容错能力。Hystrix具备拥有回退机制和断路器功能的线程和信号隔离，请求缓存和请求打包，以及监控和配置等功能。**

### 代码实现
上节刚讲ribbon ,所以我们直接在ribbon 的代码基础之上添加hystrix。
### 一、简单的hystrix配置
#### 1、添加依赖
```
<dependency>
	<groupId>org.springframework.cloud</groupId>
	<artifactId>spring-cloud-starter-hystrix</artifactId>
</dependency>
```
#### 2、添加注解
在启动类添加`@EnableCircuitBreaker` 注解
```java
@SpringBootApplication
@EnableEurekaClient
@EnableCircuitBreaker
public class CustomerRibbonHystrixApplication {
	
    public static void main( String[] args ){
      SpringApplication.run(CustomerRibbonHystrixApplication.class, args);
    }
    
    @Bean
    @LoadBalanced
    public RestTemplate restTemlate() {
    	return new RestTemplate();
    }
}
```
#### 3、设置请求回调
##### 3.1 在方法上添加`@HystrixCommand` 注解
##### 3.2 在`@HystrixCommand` 注解中定义回调方法名称，并实现其方法
```java
@RestController
public class TestController {

	@Autowired
	private RestTemplate restTemplate;
	
	@Autowired
	private LoadBalancerClient loadBalancerClient;
	
	@GetMapping("/provider/{id}")
	@HystrixCommand(fallbackMethod="testFallback")
	public Object test(@PathVariable("id") String id) {
		ServiceInstance serverInstance = loadBalancerClient.choose("producer");
		System.out.println("===="+serverInstance.getHost()+":"+serverInstance.getPort());
		return restTemplate.getForObject("http://producer/item/"+id,Object.class);
	}
	
	/**
	 * 请求失败时，调用此返回的方法
	 * @param id
	 * @return
	 */
	public Object testFallback(String id) {
		System.out.println("这个方法里面可以写回调的逻辑，下面是回调的内容，参数和如上的方法参数一致");
		return "请求失败时，返回的数据";
	}
}
```
**这样既可实现断路器功能，可以测试下。
1、启动Eureka服务
2、启动生产者服务
2、启动这个hystrix 项目
访问请求 `/provider/{id}` ,返回结果应该是正常的，然后把生产者服务停掉，再次请求看是否返回我们设置的回调内容。**

![](08632.png)

![](21489.png)

##### [Github代码示例](https://github.com/rstyro/SpringCloud/tree/master/SpringCloud-customer-ribbon-hystrix)

### 二、hystrix 对feign 的支持
#### 1、添加依赖
依赖和上面的示例一 一样
```
<dependency>
	<groupId>org.springframework.cloud</groupId>
	<artifactId>spring-cloud-starter-hystrix</artifactId>
</dependency>
```
#### 2、添加注解
在启动类上添加`@EnableCircuitBreaker` 注解因为是feign 所以也是需要`@EnableFeignClients` 注解
```java
@EnableCircuitBreaker
@EnableEurekaClient
@EnableFeignClients
@SpringBootApplication
public class CustomerFeignHystrixApplication {
	
    public static void main( String[] args ){
      SpringApplication.run(CustomerFeignHystrixApplication.class, args);
    }
    
}
```
#### 3、在feign接口客户端上添加注解
##### 方法一：使用fallback
**1、在feign服务接口的`@FeignClient` 注解添加fallback 参数，后面是一个配置类名**
```java
@FeignClient(name="producer",fallback=MyHystrixFallback.class)
public interface MyFeignClient {

	@RequestMapping(value="/item/{id}",method=RequestMethod.GET)
	public Object detai(@PathVariable("id") String id);
}
```
**2、实现fallback 配置的自定义类**
实现feign 服务接口，重写其所有方法的回调
```java
@Component
public class MyHystrixFallback implements MyFeignClient{

	@Override
	public Object detai(String id) {
		return "自定义Hystrix 返回数据：id="+id;
	}

}
```
##### 方法二：使用fallbackFactory
**1、在feign服务接口的`@FeignClient` 注解添加fallbackFactory 参数，后面是一个配置类名**
```java
@FeignClient(name="producer",fallbackFactory=MyHystrixFallbackFactory.class)
public interface MyFeignClient2 {

	@RequestMapping(value="/item/{id}",method=RequestMethod.GET)
	public Object search(@PathVariable("id") String id);
}
```

**2、实现fallbackFactory 定义的类**
```java
@Component
public class MyHystrixFallbackFactory implements FallbackFactory<MyFeignClient2> {
	private static final Logger log = LoggerFactory.getLogger(MyHystrixFallbackFactory.class);
	@Override
	public MyFeignClient2 create(Throwable e) {
		log.info("throwable = "+e);
		return new MyHystrixFeignClient2Fallback();
	}

}
```
这个MyHystrixFeignClient2Fallback 类是其实现类，fallbackFactory 可以说时fallback 的增加版
```java
public class MyHystrixFeignClient2Fallback implements MyFeignClient2{
	@Override
	public Object search(String id) {
		return "search 方法请求失败，id="+id;
	}

}
```

**验证过程与结果同示例一一致**

##### [Github代码示例](https://github.com/rstyro/SpringCloud/tree/master/SpringCloud-customer-feign-hystrix)


部分参考自：[http://blog.didispace.com/springcloud3/](http://blog.didispace.com/springcloud3/)

---
title: SpringCloud （二）、Ribbon客户端负载均衡
date: 2018-05-25 11:56:20
tags: [SpringCloud]
categories: Java
---
# Ribbon
** 学过Nginx的都知道它是一个服务端负载均衡器，而Ribbon 也是一个负载均衡器，只不过它是基于基于HTTP和TCP的客户端负载均衡器。
**

## 代码实现
### 准备工作
** 1、启动一个eureka服务** 
** 2、一个生产者集群，有两个节点（端口7900、端口7901）** 
** 3、一个ribbon 客户端** 

** 生产者我们用上次的代码即可，下面是ribbon客户端的代码实现。**
### 一、使用默认的负载均衡策略（轮询）

#### 1、导入依赖
** 官方的文档是需要导入`spring-cloud-starter-ribbon` 依赖，如下图** 
![](/SpringCloud （二）、Ribbon客户端负载均衡/38912.png)
**但是呢，我们需要导入的eureka的依赖已经包含了ribbon的依赖**
![](/SpringCloud （二）、Ribbon客户端负载均衡/09761.png)
**所以导入`spring-cloud-starter-eureka`即可**
```
<dependency>
	<groupId>org.springframework.cloud</groupId>
	<artifactId>spring-cloud-starter-eureka</artifactId>
</dependency>
```
#### 2、加上注解
**只需要在客户端的RestTemplate `bean`上加上注解`@LoadBalanced`即可用默认的负载均衡策略（轮询）。**
```
@SpringBootApplication
@EnableEurekaClient
public class CustomerRibbonApplication {
	
    public static void main( String[] args ){
      SpringApplication.run(CustomerRibbonApplication.class, args);
    }
    
    @Bean
    @LoadBalanced
    public RestTemplate restTemlate() {
    	return new RestTemplate();
    }
}
```

#### 3、控制层访问生产者
**常规我们的restTemplate.getForObject()的第一个参数地址是写死的，这里我们写上`服务名称` producer即可**
```
@RestController
public class TestController {

	@Autowired
	private RestTemplate restTemplate;
	
	@GetMapping("/provider/{id}")
	public Object test(@PathVariable("id") String id) {
		Object obj = restTemplate.getForObject("http://producer/item/"+id,Object.class);
		System.out.println("obj="+obj.toString());
		return obj;
	}
```
#### 把生产者和eureka服务与ribbon客户端启之后，我们看看eureka 的服务注册情况
![](/SpringCloud （二）、Ribbon客户端负载均衡/78912.png)

因为我们知道`生产者`有一个片段代码是长这样的：
```
@GetMapping("/item/{id}")
public Object test(@PathVariable("id")String id,HttpServletRequest request) {
	int port = request.getServerPort();
	System.out.println("item---id,port:"+port);
	return new Item(id,port+"");
}
```
然后我们浏览器访问：
[http://localhost:8901/provider/1](http://localhost:8901/provider/1)
刚好调用的是`生产者`的`/item/{id}`这个接口，我们可以观察控制台的打印情况，知道负载均衡是否有效,我们多请求几次，然后看控制台的代码如下：
![](/SpringCloud （二）、Ribbon客户端负载均衡/71435.png)

** 从打印结果知道，我们已经成功实现了负载均衡 **
** 还有就是，这个默认的是轮询的负载均衡，我们怎么自定义自己的负载均衡策略，看下面第二种情况 **

### 二、自定义负载均衡策略
#### 1、创建一个自定义的配置类RuleConfig
> 这个配置类的路径，不要在启动类的包路径之下

```
@Configurable
public class RuleConfig {
	@Bean
	public IRule ribbonRule(IClientConfig config) {
		//RandomRule 是随机策略
		return new RandomRule();
	}
	
}
```

#### 2、启动类加注解
`@RibbonClient`注解给哪个服务启动负载均衡策略，参数中的name 是服务名称，configuration 后面跟着是负载均衡自定义配置类
```
@Configuration
@RibbonClient(name="producer2",configuration=RuleConfig.class)
@SpringBootApplication
@EnableEurekaClient
public class CustomerRibbonApplication {
	
    public static void main( String[] args ){
      SpringApplication.run(CustomerRibbonApplication.class, args);
    }
    
    @Bean
    @LoadBalanced
    public RestTemplate restTemlate() {
    	return new RestTemplate();
    }
}
```
#### 3、测试是否生效
```
@RestController
public class TestController {

	
	@Autowired
	private LoadBalancerClient loadBalancerClient;
		
	@GetMapping("/test")
	public Object test2() {
		//下面是当前的访问请求producer2服务中，具体选择的是哪个服务
		ServiceInstance serverInstance = loadBalancerClient.choose("producer2");
		String result = "===="+serverInstance.getHost()+":"+serverInstance.getPort();
		System.out.println(result);
		return result;
	}
}
```
#### eureka 服务注册情况
![](/SpringCloud （二）、Ribbon客户端负载均衡/41275.png)

多次访问：[http://localhost:8901/test](http://localhost:8901/test)
查看控制台
![](/SpringCloud （二）、Ribbon客户端负载均衡/93257.png)
**可以知道是随机的，还有一种是，如果我想要`producer`服务 是默认的，`producer2`服务是随机的，怎么配置**
** 其实很简单，想要的默认的不需要配置，只配置你想要自定义的即可，如下：随机加轮询**
![](/SpringCloud （二）、Ribbon客户端负载均衡/46308.png)

**[Github代码地址](https://github.com/rstyro/SpringCloud)**

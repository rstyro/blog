---
title: SpringCloud （七）、禁用Feign对Hystrix支持与Hystrix 监控
date: 2018-05-26 17:08:09
updated: 2018-05-26 17:08:09
tags: [SpringCloud]
categories: Java
---
# 禁用单个Feign对Hystrix支持与Hystrix 监控
## 一、配置禁用Feign对Hystrix 的支持
如果现在有两个Feign服务接口，FeignClientService1、FeignClientService2。我们现在想禁用FeignClientService2 的Hystrix支持，而FeignClientService1不变还是启用

### 1、配置FeignClent
这个和启动Hystrix 的配置差不多，主要看的是configuration 后面这个类的内容
```java
@FeignClient(name="test",url="http://localhost:7901/",configuration=FeignConfig2.class,fallback=MyHystrixFallback2.class)
public interface FeignClientService2 {

	@RequestMapping(value="/{serviceName}",method=RequestMethod.GET)
	public Object serverInfo(@PathVariable("serviceName") String serviceName);
	
}
```

### 2、自定义配置类FeignConfig2
因为feign的默认builder 是`HystrixFeign.Builder` 如下图

![](36174.png)

所以主要是重写 feignBuilder 这个方法，返回一个另一个builder即可，可查看官方文档的示例

![](43178.png)

```java

@Configuration
public class FeignConfig2 {
	
	@Bean
	@Scope("prototype")
	public Feign.Builder feignBuilder() {
		return Feign.builder();
	}
}

```
#### 重要的配置就是第二步，这样即可禁用Hystrix 的支持。
可以访问`/hystrix.stream` 链接，查看hystrix的动向数据

![](51493.png)
##### 完整的[Github代码示例](https://github.com/rstyro/SpringCloud/tree/master/SpringCloud-customer-feign-hystrix-disable-single)

 
## 二、Hystrix监控面板Dashboard
 创建一个Dashboard项目很简单
 
### 1、添加依赖
```xml

 <dependency>
	<groupId>org.springframework.cloud</groupId>
	<artifactId>spring-cloud-starter-hystrix-dashboard</artifactId>
</dependency>
```
 
### 2、添加注解
在启动类添加`@EnableHystrixDashboard`注解

```java
@EnableHystrixDashboard
@SpringBootApplication
public class HystrixDashboardApplication {	
    public static void main( String[] args ){
      SpringApplication.run(HystrixDashboardApplication.class, args);
    }
    
}
```
 
### 3、配置配置文件application.yml
下面是修改服务启动的端口，默认是8080，不改也是可以的，按需
 
```
 server:
  port: 8930
  
```
 ### 4、访问
启动之后，访问[http://192.168.1.101:8930/hystrix](http://192.168.1.101:8930/hystrix)即可
在访问页面写上，`hystrix.stream` 的地址即可,比如：[http://192.168.1.101:8904/hystrix.stream](http://192.168.1.101:8904/hystrix.stream)，标题随便写一个即可
![](59074.png)
##### 完整的[Github代码示例](https://github.com/rstyro/SpringCloud/tree/master/SpringCloud-customer-ribbon-hystrix-dashboard)
如果监控集群的，可以配置turbine，也不是很难，可参考官方文档[http://cloud.spring.io/spring-cloud-static/Dalston.SR5/single/spring-cloud.html#_turbine](http://cloud.spring.io/spring-cloud-static/Dalston.SR5/single/spring-cloud.html#_turbine)
 

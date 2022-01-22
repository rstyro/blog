---
title: SpringCloud （十）、Zuul 过滤器
date: 2018-05-27 12:52:07
updated: 2018-05-27 12:52:07
tags: [SpringCloud]
categories: Java
---
## Zuul 过滤器

Zuul大部分功能都是通过过滤器来实现的。Zuul中定义了四种标准过滤器类型，这些过滤器类型对应于请求的典型生命周期。
+  **PRE**：这种过滤器在请求被路由之前调用。我们可利用这种过滤器实现身份验证、在集群中选择请求的微服务、记录调试信息等。
+  **ROUTING**：这种过滤器将请求路由到微服务。这种过滤器用于构建发送给微服务的请求，并使用Apache HttpClient或Netfilx Ribbon请求微服务。
+  **POST**：这种过滤器在路由到微服务以后执行。这种过滤器可用来为响应添加标准的HTTP Header、收集统计信息和指标、将响应从微服务发送给客户端等。
+  **ERROR**：在其他阶段发生错误时执行该过滤器。

**除了默认的过滤器类型，Zuul还允许我们创建自定义的过滤器类型。例如，我们可以定制一种STATIC类型的过滤器，直接在Zuul中生成响应，而不将请求转发到后端的微服务。**


**下面讲的主要是zuul1.x**
#### SpringCloud 启动过滤器，有两个注解`@EnableZuulServer`、`@EnableZuulProxy`
### 一、@EnableZuulServer过滤器
#### 1、pre类型过滤器
+  **ServletDetectionFilter**：该过滤器用于检查请求是否通过`Spring Dispatcher`。检查后，通过`isDispatcherServletRequest`设置布尔值。

+  **FormBodyWrapperFilter**：解析表单数据，并为请求重新编码。

+  **DebugFilter**：顾名思义，调试用的过滤器，可以通过`zuul.debug.request=true `，或在请求时，加上debug=true的参数，例如`$ZUUL_HOST:ZUUL_PORT/path?debug=true` 开启该过滤器。这样，该过滤器就会把`RequestContext.setDebugRouting()` 、`RequestContext.setDebugRequest() `设为true。

#### 2、route类型过滤器

**SendForwardFilter**：该过滤器使用`Servlet RequestDispatcher`转发请求，转发位置存储在`RequestContext.getCurrentContext().get("forward.to")` 中。可以将路由设置成：
```
zuul:
  routes:
    abc: 
      path: /abc/**
      url: forward:/abc
```
然后访问`$ZUUL_HOST:ZUUL_PORT/abc` ，观察该过滤器的执行过程。

#### 3、post类型过滤器
**SendResponseFilter**：将Zuul所代理的微服务的的响应写入当前响应。

#### 4、error类型过滤器
**SendErrorFilter**：如果`RequestContext.getThrowable()` 不为`null`，那么默认就会转发到`/error`，也可以设置`error.path`属性修改默认的转发路径。

### 二、@EnableZuulProxy过滤器

**如果使用注解@EnableZuulProxy，那么除上述过滤器之外，Spring Cloud还会安装以下过滤器：**

#### 一、pre类型过滤器

**PreDecorationFilter**：该过滤器根据提供的`RouteLocator`确定路由到的地址，以及怎样去路由。该路由器也可为后端请求设置各种代理相关的header。

#### 二、route类型过滤器

+  **RibbonRoutingFilter**：该过滤器使用Ribbon，Hystrix和可插拔的HTTP客户端发送请求。`serviceId`在`RequestContext.getCurrentContext().get("serviceId")` 中。该过滤器可使用不同的HTTP客户端，例如
*Apache HttpClient*：默认的HTTP客户端
*Squareup OkHttpClient v3*：如需使用该客户端，需保证`com.squareup.okhttp3`的依赖在classpath中，并设置`ribbon.okhttp.enabled = true` 。
*Netflix Ribbon HTTP client*：设置`ribbon.restclient.enabled = true` 即可启用该HTTP客户端。需要注意的是，该客户端有一定限制，例如不支持PATCH方法，另外，它有内置的`重试机制`。
+  **SimpleHostRoutingFilter**：该过滤器通过Apache HttpClient向指定的URL发送请求。URL在`RequestContext.getRouteHost()` 中。

### 自定义过滤器的代码示例
#### 1、自定义一个过滤器 MyPreZuulFileter
```java
@Component
public class MyPreZuulFileter extends ZuulFilter{

	@Override
	public Object run() {
		System.out.println("这个就是你要过滤的重要方法");
		System.out.println("可以在这里写你的过滤逻辑");
		System.out.println("比如下面的demo");
		RequestContext context = RequestContext.getCurrentContext();
    	HttpServletResponse servletResponse = context.getResponse();
		servletResponse.addHeader("X-Foo", UUID.randomUUID().toString());
		return null;
	}

	/**
	 * 是否使用这个过滤器，true -- 使用
	 */
	@Override
	public boolean shouldFilter() {
		return true;
	}

	/**
	 * 执行顺序，返回的数字越大越靠后
	 */
	@Override
	public int filterOrder() {
		return 7;
	}

	/**
	 * 过滤的类型
	 */
	@Override
	public String filterType() {
		// TODO Auto-generated method stub
		/**
		 * 有4种：
		 * pre
		 * post
		 * route
		 * error
		 * 
		 * 可以看spring-clou-netflix-core-1.3.6RELEASE.jar下的
		 * org.springframework.cloud.netflix.zuul.filters.support.FilterConstants 这个类
		 * 
		 */
		return "pre";
	}
	

}
```
#### 2、加注解
在启动类加`@EnableZuulProxy`注解,并注入上面自定义的bean
```java
@SpringBootApplication
@EnableZuulProxy
public class SpringcloudZuulFilterApplication {

	public static void main(String[] args) {
		SpringApplication.run(SpringcloudZuulFilterApplication.class, args);
	}
	
	@Bean
	public MyPreZuulFileter myPreZuulFileter() {
		return new MyPreZuulFileter();
	}
	
}
```
完整的 [Github代码地址](https://github.com/rstyro/SpringCloud/tree/master/SpringCloud-zuul-filter)
请求服务时，拦截

![](13624.png)
参考链接：
[https://github.com/Netflix/zuul/wiki/How-It-Works](https://github.com/Netflix/zuul/wiki/How-It-Works)、
[http://www.itmuch.com/spring-cloud/zuul/zuul-filter-in-spring-cloud/](http://www.itmuch.com/spring-cloud/zuul/zuul-filter-in-spring-cloud/)

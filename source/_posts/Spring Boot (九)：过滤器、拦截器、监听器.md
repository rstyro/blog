---
title: Spring Boot (九)：过滤器、拦截器、监听器
date: 2017-08-13 12:07:31
tags: [Spring Boot]
categories: Java
---
# springboot 的过滤器、监听器、拦截器 demo

## 一、添加依赖
```
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
</dependency>
```
## 二、过滤器 的创建
#### (1)、创建自己的过滤器类实现javax.servlet.Filter接口
#### (2)、重写doFilter 的方法，在此方法里写过滤操作
#### (3)、在类上使用注解@WebFilter(filterName="myFilter",urlPatterns={"/*"})

## 三、监听器 的创建
#### (1)、创建自己的监听类实现 ServletContextListener 接口，这个是监听servlet的
#### (2)、创建自己的监听类实现 HttpSessionListener 接口，这个是监听session 的
#### (3)、记得在自定义的监听类上添加注解@WebListener

## 四、拦截器 的创建
#### (1)、创建自己的拦截器类，实现HandlerInterceptor 接口
#### (2)、创建一个配置类，继承自WebMvcConfigurerAdapter ，并在类上添加注解@Configuration
#### (3)、重写addInterceptors方法，把自定义的拦截类注册进去。

## 五、代码示例
### (1)、过滤器
```java
/**
 * 
 * 使用注解标注过滤器
 * @WebFilter将一个实现了javax.servlet.Filter接口的类定义为过滤器
 * 属性filterName 声明过滤器的名称,可选
 * 属性urlPatterns指定要过滤 的URL模式,这是一个数组参数，可以指定多个。也可使用属性value来声明.(指定要过滤的URL模式是必选属性)
 */
@WebFilter(filterName="myFilter",urlPatterns={"/*"})
public class MyFilter implements Filter{
 
    @Override
    public void destroy() {
        System.out.println("myfilter 的 销毁方法");
    }
 
    @Override
    public void doFilter(ServletRequest arg0, ServletResponse arg1, FilterChain chain)
            throws IOException, ServletException {
        System.out.println("myfilter 的 过滤方法。这里可以执行过滤操作");
        //继续下一个拦截器
        chain.doFilter(arg0, arg1);
    }
 
    @Override
    public void init(FilterConfig arg0) throws ServletException {
        System.out.println("myfilter 的 初始化方法");
    }
 
}
```

### (2)、拦截器
##### a)、自定义拦截器
```java
public class MyInterceptor implements HandlerInterceptor{
 
    @Override
    public void afterCompletion(HttpServletRequest arg0, HttpServletResponse arg1, Object arg2, Exception arg3)
            throws Exception {
        System.out.println("MyInterceptor 在整个请求结束之后被调用，也就是在DispatcherServlet 渲染了对应的视图之后执行");
    }
 
    @Override
    public void postHandle(HttpServletRequest arg0, HttpServletResponse arg1, Object arg2, ModelAndView arg3)
            throws Exception {
        System.out.println("MyInterceptor  请求处理之后进行调用，但是在视图被渲染之前（Controller方法调用之后）");    
    }
 
    @Override
    public boolean preHandle(HttpServletRequest arg0, HttpServletResponse arg1, Object arg2) throws Exception {
        System.out.println("MyInterceptor 在请求处理之前进行调用（Controller方法调用之前）这里是拦截的操作");
        return true;
    }
 
}
```
##### b)、注册拦截器 继承 WebMvcConfigurerAdapter
```java
@Configuration
public class WebConfigurer extends WebMvcConfigurerAdapter {
 
    @Override
    public void addInterceptors(InterceptorRegistry registry) {
         // addPathPatterns 用于添加拦截规则
        // excludePathPatterns 排除拦截
        registry.addInterceptor(new MyInterceptor()).addPathPatterns("/**").excludePathPatterns("/login");
        super.addInterceptors(registry);
    }
}
```

### (3)、监听器
```java
@WebListener
public class SessionListener implements HttpSessionListener{
 
    @Override
    public void sessionCreated(HttpSessionEvent arg0) {
        System.out.println("监听 创建session");
    }
 
    @Override
    public void sessionDestroyed(HttpSessionEvent arg0) {
        System.out.println("监听 销毁session");
    }
 
}
```
### (4)、启动类
```java
/**
 * @ServletComponentScan 扫描我们自定义的servlet
 * @author tyro
 *
 */
@ServletComponentScan
@SpringBootApplication
public class SpringbootFilterListenerInterceptorApplication {
 
    public static void main(String[] args) {
        SpringApplication.run(SpringbootFilterListenerInterceptorApplication.class, args);
    }
}
```


> Github 代码示例地址：[https://github.com/rstyro/spring-boot](https://github.com/rstyro/spring-boot)
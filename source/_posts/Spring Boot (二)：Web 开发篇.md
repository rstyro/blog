---
title: Spring Boot (二)：Web 开发篇
date: 2017-07-27 22:28:47
tags: [Spring Boot]
categories: Java
---
# Springboot之Web 开发篇

## 1、静态资源访问
在我们开发Web应用的时候，需要引用大量的js、css、图片等静态资源。

## 2、默认配置
Spring Boot默认提供静态资源目录位置需置于classpath下，目录名需符合如下规则：

```
/static
/public
/resources
/META-INF/resources
```

#### springboot 的源码如下：
```Java
private static final String[] CLASSPATH_RESOURCE_LOCATIONS = {  
        "classpath:/META-INF/resources/", "classpath:/resources/",  
        "classpath:/static/", "classpath:/public/" };
```

##### 举例：我们可以在src/main/resources/目录下创建static文件夹，在该位置放置一个图片文件（demo.jpg）。启动程序后，尝试访问http://localhost:8080/demo.jpg
##### 如果能显示图片说明配置成功。

## 3、渲染Web页面

##### 在之前的示例中，我们都是通过@RestController来处理请求，所以返回的内容为json对象。那么如果需要渲染html页面的时候，要如何实现呢？
> 和spring mvc 一样，我们用@Controller 和 @RequestMapping

## 4、模板引擎
##### 在动态HTML实现上Spring Boot依然可以完美胜任，并且提供了多种模板引擎的默认配置支持，所以在推荐的模板引擎下，我们可以很快的上手开发动态网站。

#### Spring Boot提供了默认配置的模板引擎主要有以下几种：
+ Thymeleaf
+ FreeMarker
+ Velocity
+ Groovy
+ Mustache

#### Spring Boot建议使用这些模板引擎，避免使用JSP，
##### 当你使用上述模板引擎中的任何一个，它们默认的模板配置路径为：src/main/resources/templates。当然也可以修改这个路径，在application.properties中配置 ```spring.thymeleaf.prefix=classpath:/templates/```

#### 更多的配置参数如下：

```xml
# Enable template caching.
spring.thymeleaf.cache=true 
# Check that the templates location exists.
spring.thymeleaf.check-template-location=true 
# Content-Type value.
spring.thymeleaf.content-type=text/html 
# Enable MVC Thymeleaf view resolution.
spring.thymeleaf.enabled=true 
# Template encoding.
spring.thymeleaf.encoding=UTF-8 
# Comma-separated list of view names that should be excluded from resolution.
spring.thymeleaf.excluded-view-names= 
# Template mode to be applied to templates. See also StandardTemplateModeHandlers.
spring.thymeleaf.mode=HTML5 
# Prefix that gets prepended to view names when building a URL.
spring.thymeleaf.prefix=classpath:/templates/ 
# Suffix that gets appended to view names when building a URL.
spring.thymeleaf.suffix=.html 
# Order of the template resolver in the chain. 
spring.thymeleaf.template-resolver-order= 
# Comma-separated list of view names that can be resolved.
spring.thymeleaf.view-names=
```
#### Demo 示例

##### html页面

```html
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8"/>
<title>index</title>
</head>
<body>
<h1 th:text="${title}">Hello World</h1>
<h1><a href="http://www.thymeleaf.org"  th:href="@{http://www.lrshuai.top}" th:text="${atext}">Thymeleaf</a></h1>
</body>
</html>
```

##### java 代码

```Java
@Controller
public class HelloController {

	@RequestMapping(value={"/index","/","/hello"})
	public String index(Model model){
		model.addAttribute("title", "测试");
		model.addAttribute("atext", "这个冬天不太Cool");
		return "index";
	}
}
```
> Github 代码示例：https://github.com/rstyro/spring-boot/tree/master/springboot-web

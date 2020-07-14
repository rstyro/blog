---
title: Spring 之 跨越问题解决
date: 2017-07-14 20:28:59
tags: [Spring Boot, Spring, Java]
categories: Java
---
# spring 之 跨域问题解决方案
## springboot 的跨域问题和它是一样的
> 之前因为ajax跨越的问题，弄得头大，有用过jsonp 来解决的。可惜就是jsonp 只能是get请求，不能post请求。你虽然写的是post 请求，但底层还是用get请求。

### 现在好了，spring 4.2版本 之后开始增加了对CORS的支持
##### 在Spring MVC 中增加CORS支持非常简单，可以配置全局的规则，也可以使用@CrossOrigin 注解进行细粒度的配置。

## 解决方案：
### 1、在Controller上使用@CrossOrigin注解，这样所有这个控制层下的接口都是可以跨越了。
![](1499329874919053972.png)

### 2、在方法上使用注解。
![](1499329948525000219.png)

## 具体 @CrossOrigin 参数如下图：

![](1499330537916012209.png)

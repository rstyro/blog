---
title: Springboot 报错Whitelabel Error Page This application
date: 2017-07-26 22:16:35
tags: [Spring Boot]
categories: Java
---
# Spring boot 请求报错如下：
##### springboot 入门级错误
> Whitelabel Error Page
This application has no explicit mapping for /error, so you are seeing this as a fallback.
Tue Jul 25 16:07:38 CST 2017
There was an unexpected error (type=Not Found, status=404).
No message available

## 报错原因：Application启动类放的位置不对



### 解决方案:
#### 要将Application放在最外层，也就是要包含所有子包。
##### 比如你的groupId是top.lrshuai.demo,子包就是所谓的top.lrshuai.demo.xxx,所以要将 Application类要放在top.lrshuai.demo包下。

#### springboot会自动加载启动类所在包下及其子包下的所有组件.

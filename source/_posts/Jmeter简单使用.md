---
title: Jmeter简单使用
date: 2021-06-09 16:41:59
updated: 2021-06-09 16:41:59
tags: [JMeter]
categories: 开发工具
---

### 一、Jmeter下载
+ **官网地址:**[https://jmeter.apache.org/download_jmeter.cgi](https://jmeter.apache.org/download_jmeter.cgi)
+ 直接选择`Binaries` 下面的地址下载即可。
+ 目前(2021-06)最新的版本是：[5.4.1](https://mirrors.tuna.tsinghua.edu.cn/apache//jmeter/binaries/apache-jmeter-5.4.1.zip)

### 二、启动
+ windows 下载解压后
+ 执行jmeter根目录下的bin文件夹下的`jmeter.bat`即可

#### 1、修改语言
+ 默认是英文版的，可以选择`Option`->`Choose Language`-> `Chinese` 修改为中文

![](lang.png)

### 三、简单使用
+ 文件-> 新建
+ 右键添加线程组，可以配置线程数，循环次数这些

![](thead.png)

+ 添加取样器->HTTP请求，这样就可以简单的请求了。

![](http.png)

+ 然后在添加一个`察看结果树`，查看返回结果

![](listener.png)

+ 如果是body是json参数可以添加 `Http信息头管理器`，添加：`Content-Type:application/json`
+ 然后在消息体数据那里添加json数据，否则在参数那里添加即可

![](header.png)
![](body.png)
![](result.png)

+ 普通的请求一般就这些，当然不只上面的功能。
+ 看需求添加元件，比如随机参数、聚合报告、断言等等
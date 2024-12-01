---
title: 安装Go语言环境
date: 2021-07-20 10:04:54
updated: 2021-07-20 10:04:54
tags: [Go]
categories: Go
---

### 一、下载Go安装包
Go支持的系统有：
+ Linux
+ FreeBSD
+ Mac OS X（也称为 Darwin）
+ Windows
<!--more-->

**安装包下载地址：**
+ 官网(需要翻墙)：[https://golang.org/dl/](https://golang.org/dl/)
+ Google镜像（不需要翻墙）：[https://golang.google.cn/dl/](https://golang.google.cn/dl/)

![](download.png)


### 二、安装
+ 安装很简单

**1、Windows安装**
+ windows安装很简单，一路下一步到完成即可。
+ 然后可以把安装路径配到你的环境变量(`path`),不配得话，就需要到安装bin目录执行go命令

**2、Linux安装**
+ 这个也简单，把上面下载的压缩包解压即可。

```
tar -zxvf go1.16.6.linux-amd64.tar.gz -C /usr/local/
```
+ 然后在`/usr/local`就有一个Go目录
+ 可以把go配到环境变量，
+ 在`/etc/profile`最后添加：`export PATH=$PATH:/usr/local/go/bin`
+ 执行：`source /etc/profile`即可
+ 执行：`go version`显示go版本则成功！

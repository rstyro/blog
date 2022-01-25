---
title: SpringBoot热部署JRebel
date: 2022-01-25 11:14:16
updated: 2022-01-25 11:14:16
tags: [Spring Boot]
categories: Java
---


### 一、SpringBoot 热部署

- 常用的热部署一般就是：`spring-boot-devtools` 与 `JRebel插件`


**spring-boot-devtools 与 JRebel 对比**
- 使用spring-boot-devtools，需要引入jar包，添加Maven依赖,
- 新增一个方法或修改方法的参数，就不生效，速度上也没有JRebel快
- 毕竟JRebel是收费的嘛，金钱的魅力
- spring-boot-devtools 的使用方法就不讲，基本上大部分都会，本文重点是 JRebel的使用

### 二、JRebel安装与激活
- 在IDEA中依次点击 File -》 Settings -》 Plugins -》 Marketplace，然后第一个就是，安装即可
- 安装之后，重启 IDEA 

![](jrebel.png)

- 因为JRebel是收费的，可以免费使用14天，但是14天一点用都没，有钱的可以支持下
- 没钱只能破解了，激活有3种方式：1、许可服务器，2、许可文件，3、激活码
- 我们选择的是 `licensing service`(许可服务器)

#### 1、破解方式一
- 自己启动一个许可服务器
- 去Github下载对应版本的：[https://github.com/ilanyu/ReverseProxy/releases/tag/v1.4](https://github.com/ilanyu/ReverseProxy/releases/tag/v1.4)
- 我这边是windows版本的，直接双击打开,它默认就是转发到:`http://idea.lanyus.com:80`
- 也可以以参数的形式启动，如：`./ReverseProxy_windows_amd64.exe -l "0.0.0.0:8081" -r "http://idea.lanyus.com:80"`

![](exe.png)

![](server.png)

- 然后就可以在IDEA上进行激活了，格式：`http://127.0.0.1:8888/{guid}`
- 这个GUID 可以自己写代码生成，或者去[https://www.guidgen.com/](https://www.guidgen.com/)网站生成复制一下
- IDEA第一个就是激活地址，第二个是邮箱可以随意写但要符合邮箱格式即可

![](active.png)

![](active2.png)

- 我们激活是通过本地代理的方式，但是这个代理不会一直打开，所以我们设置JRebel为离线工作
- 使用离线的方式，可以180天不用再次激活

![](off.png)

#### 2、破解方式二

- 方式二与方式一，差不多，就是我们不用下代理服务了，直接使用某大佬搭建好的
- 直接访问：[https://jrebel.qekang.com/](https://jrebel.qekang.com/)
- 然后复制下面的地址，接下来的操作和方式一一样

![](url.png)


### 三、JRebel使用

- 设置IDEA自动编译项目，将Build project automatiacally这个选下勾选上。
- 按住`ctrl + shift + alt +/` 这四个键, 点击`registry`,将`compiler.automake.allow.when.app.running`这个选项勾选上



![](conf1.png)

![](conf2.png)

- 在IDEA左下角有一个JRebel的图标，选择要使用JRebel的项目，打勾即可。
- 然后会在每个项目下面生成一个`rebel.xml`文件,这个文件可以忽略掉不用管。
- 然后启动项目的时候，选择IDE右上角的 JRebel 的debug模式启动即可。

![](use.png)

![](debug.png)

**完结撒花 ❀**
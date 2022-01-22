---
title: Spring Boot （一）：初识之入门篇
date: 2017-07-25 22:06:41
updated: 2017-07-25 22:06:41
tags: [Spring Boot]
categories: Java
---
# Spring Boot入门
## 一、简介与特点
```
是由Pivotal团队提供的全新框架，其设计目的是用来简化新Spring应用的初始搭建以及开发过程。该框架使用了特定的方式来进行配置，从而使开发人员不再需要定义样板化的配置。通过这种方式，Spring Boot致力于在蓬勃发展的快速应用开发领域（rapid application development）成为领导者。
Java开发者喜好的框架当属Spring，Spring也成为了在Java EE开发中真正意义上的标准，但是随着新技术的发展，脚本语言大行其道的时代（Node JS，Ruby，Groovy，Scala等），Java EE使用Spring逐渐变得笨重起来，大量的XML文件存在与项目中，繁琐的配置，整合第三方框架的配置问题，低下的开发效率和部署效率等等问题，所以Spring Boot 诞生了。
```
### Spring Boot 的特点：
+ 遵循“习惯优于配置”的原则，使用Spring Boot只需要很少的配置，大部分的时候我们直接使用默认的配置即可；
+ 项目快速搭建，可以无需配置的自动整合第三方的框架；
+ 可以完全不使用XML配置文件，只需要自动配置和Java Config；
+ 内嵌Servlet容器，降低了对环境的要求，可以使用命令直接执行项目，应用可用jar包执行：java -jar；
+ 提供了starter POM, 能够非常方便的进行包管理, 很大程度上减少了jar hell或者dependency hell；
+ 运行中应用状态的监控；
+ 对主流开发框架的无配置集成；
+ 与云计算的天然继承；
### Spring Boot 的核心功能：
+ 独立运行的Spring项目
+ 内嵌的Servlet容器
+ 提供starter简化Manen配置
+ 自动配置Spring
+ 应用监控
+ 无代码生成和XML配置


## 二、快速创建项目
#### （1）、浏览器打开 http://start.spring.io/

#### （2）、选择maven Project 、和Spring Boot 的版本。（现在出到2.0.0了）

#### （3）、填写项目的基本信息，快捷键ALT + 回车，下载压缩版。或者点击 Gennerate Project 中间绿色按钮

#### （4）、解压，eclipse 导入maven 项目

![](1500971970431043107.png)

> Eclipse 导入流程：File -- >Import -> Existing Maven Projects -> Next ->选择解压后的文件夹(Browse)-> Finsh，OK done! 

![](1500972415955079430.png)

### 后面有一篇，eclipse 装springboot 插件的文章

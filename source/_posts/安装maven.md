---
title: 安装maven
date: 2017-08-22 12:17:01
tags: [Maven, 开发工具]
categories: 开发工具
---
# 安装Maven

## 一、linux 安装Maven
#### 官网下载：http://apache.fayea.com/maven/maven-3/3.5.0/binaries/apache-maven-3.5.0-bin.tar.gz
```
#解压到/opt/下
tar -zxvf apache-maven-3.5.0-bin.tar.gz -C /opt/
 
#为了方便配置环境，改名
mv /opt/apache-maven-3.5.0 maven
 
#修改/etc/profile 文件
vim /etc/profile
 
#在最后添加
M2_HOME=/opt/maven
export PATH=${M2_HOME}/bin:${PATH}
 
#让它立即生效
source /etc/profile
 
#验证是否安装成功,查看版本
mvn -v
```
## 二、windows 安装Maven
#### 1、官网：http://maven.apache.org/download.cgi 下载
#### 2.解压下载的文件
##### 我的Maven的解压路径是D盘根目录，Maven路径为 E:\installPath\maven\apache-maven-3.3.9
#### 3、新建系统变量MAVEN_HOME，变量值为 E:\installPath\maven\apache-maven-3.3.9
#### 4、需要在Path前面加上%MAVEN_HOME%\bin;
#### 5、验证是否配置成功：如果显示如下，说明成功，需要注意的是要先配置好JDK的路径。
![](/安装maven/1499321122690022124.png)

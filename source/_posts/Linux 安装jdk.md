---
title: Linux 安装jdk
date: 2017-05-13 22:16:30
tags: [Linux, Java]
categories: Java
---
## 1.判断是否安装了jdk
```
rpm -qa | grep jdk  或者 rpm -qa | grep openjdk

#有则卸载，-nodeps 是强制卸载
rpm -e  --nodeps  jdk-xxx
```
## 2.下载jdk包
####官网：[http://www.oracle.com/technetwork/java/javase/downloads/index.html](http://www.oracle.com/technetwork/java/javase/downloads/index.html)
```
wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.tar.gz
```
## 3.解压
```
tar -zxvf jdk-8u131-linux-x64.tar.gz -C /usr/local/ 
```
## 4.重命名
```
cd /usr/local
mv jdk-8u131-linux-x64 jdk
```
## 5.配置环境变量
#### (1)、编辑配置文件
```
vim /etc/profile
```
#### (2)、在文件最后添加如下：
```
export JAVA_HOME=/usr/local/jdk
export JRE_HOME=${JAVA_HOME}/jre
export CLASSPATH=.:$JAVA_HOME/lib:${JRE_HOME}/lib
export PATH=$JAVA_HOME/bin:$PATH
```
#### (3)、使配置文件直接生效
```
source /etc/profile
```
#### (4)、测试是否配置成功
```
java -version
```

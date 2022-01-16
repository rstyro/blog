---
title: 安装maven
date: 2017-08-22 12:17:01
updated: 2017-08-22 12:17:01
tags: [Maven, 开发工具]
categories: 开发工具
---
# 安装Maven

## 一、linux 安装Maven
+ 官网下载：http://apache.fayea.com/maven/maven-3/3.5.0/binaries/apache-maven-3.5.0-bin.tar.gz

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
+ 1、官网：`http://maven.apache.org/download.cgi` 下载
+ 2.解压下载的文件
+ 我的Maven的解压路径是D盘根目录，Maven路径为 `E:\installPath\maven\apache-maven-3.3.9`
+ 3、新建系统变量`MAVEN_HOME`，变量值为 `E:\installPath\maven\apache-maven-3.3.9`
+ 4、需要在Path前面加上`%MAVEN_HOME%\bin`;
+ 5、验证是否配置成功：如果显示如下，说明成功，需要注意的是要先配置好JDK的路径。

![](1499321122690022124.png)

##### 2、修改镜像地址
+ 我的maven 安装路径为： `E:\installPath\maven\apache-maven-3.3.9\`
+ 找到：`E:\installPath\maven\apache-maven-3.3.9\conf` 下的`settings.xml`  复制一个 命名为`mysetting.xml`(名字任取)
#### 编辑 mysetting.xml
> 在mirrors 标签中加入

```xml
 <!-- 阿里云Maven镜像 你有更好更快的镜像地址更好 -->
   <mirror>
      <id>nexus-aliyun</id>
      <mirrorOf>*</mirrorOf>
      <name>Nexus aliyun</name>
      <url>http://maven.aliyun.com/nexus/content/groups/public</url>
    </mirror>
	<!-- 下面还有两个 我忘记是哪里的了，其实调上面那个就够了-->
	<mirror>
        <id>nexus-osc</id>
        <mirrorOf>central</mirrorOf>
        <name>Nexus osc</name>
        <url>http://maven.oschina.net/content/groups/public/</url>
    </mirror>
    
    <mirror>
        <id>nexus-osc-thirdparty</id>
        <mirrorOf>thirdparty</mirrorOf>
        <name>Nexus osc thirdparty</name
		<url>http://maven.oschina.net/content/repositories/thirdparty/</url>
    </mirror>
```

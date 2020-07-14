---
title: 修改eclipse 默认的maven配置
date: 2017-07-13 17:16:57
tags: [Maven, 开发工具]
categories: 开发工具
---
## 一、安装maven
#### 搜索maven 安装即可
## 二、修改配置文件
#### 我的maven 安装路径为： E:\installPath\maven\apache-maven-3.3.9\
#### 找到：E:\installPath\maven\apache-maven-3.3.9\conf 下的settings.xml  复制一个 命名为mysetting.xml(名字任取)
#### 编辑 mysetting.xml
##### 1、修改仓库地址。
> 默认是在用户文件夹下的.m2/repository 文件夹。我不希望放在那里，所以修改它
> 在标签 settings 里加入如下代码,如下图所示    E:\lrs_repe（这个地址是你的仓库新地址）

![](1499321650598078817.png)

##### 2、修改镜像地址
> 在mirrors 标签中加入

```
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
![](1499321779916044850.png)

##### 3、替换eclipse 的配置文件
> 打开eclipse--->window-->preferences-->Maven--->User Settings,选择我们刚才更改的文件（mysettings.xml）。

![](1499321872747070615.png)

![](1499321966329044703.png)

> 同时你也可以把eclipse自带的换成我们自己安装的

![](1499322192285088904.png)

![](1499322261803052089.png)

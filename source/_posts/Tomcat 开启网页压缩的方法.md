---
title: Tomcat 开启网页压缩的方法
date: 2017-06-01 14:35:53
tags: [开发工具, 干货]
categories: 开发工具
---
##我曾在站长工具（http://seo.chinaz.com/lrshuai.top） 看到别人的网页都是压缩的，我就想着 这怎么弄的。

##压缩可以大大提高浏览网站的速度，它的原理是，在客户端请求网 页后，从服务器端将网页文件压缩，再下载到客户端，由客户端的浏览器负责解 压缩并浏览。相对于普通的浏览过程HTML ,CSS,Javascript , Text ，它可以节省40%左右的流量

###然后百度，看到的是打开 Internet信息服务管理器，没有这东西，又继续找，找到了，很简单，修改tomcat 的conf文件夹下的 server.xml 文件

> 修改如下图所示： 添加4行代码

![](1498817461236027397.png)

```
compression="on"
compressionMinSize="2048"
noCompressionUserAgents="gozilla, traviata"
compressableMimeType="text/html,text/xml,text/javascript,text/css,text/plain"
```
> 保存退出，重启tomcat，然后去 http://seo.chinaz.com/lrshuai.top 检测检测

![](1498817628605091457.png)


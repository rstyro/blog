---
title: Fiddle简单抓包使用
date: 2023-07-25 17:23:32
updated: 2023-07-25 17:23:32
tags: [Fiddler]
categories: 开发工具
---

### 一、Fiddler下载与安装
- 官网:[https://www.telerik.com/fiddler](https://www.telerik.com/fiddler)
- 下载经典版的：[Fiddler Classic](https://www.telerik.com/download/fiddler)
- 下载之后双击安装即可。

<!--more-->

### 二、Fiddler配置https证书
- 选择Tools->Options->https->Decrypt HTTPS traffic 如下图所示

![](https1.png)

![](https2.png)

![](https3.png)

![](https4.png)

- 有Yes选YES就可以了。
- Fiddler会自动帮我们设置代理，如果没有设置，可自行设置，如下：

![](proxy.png)

- 允许远程连接

![](conn.png)

- 配置完之后，重启Fiddler
- 启动之后，访问网站发现我们已经能抓到数据了
- 网站太多可以进行过滤某个域名，如下：

![](filter.png)

### 三、Fiddler抓PC微信小程序
- 登录微信时，打开代理，如下：

![](wx-proxy.png)

- 删除微信WMPFRuntime 文件夹里面的的所有缓存数据，
- 目录例：`C:\Users\你的用户名\AppData\Roaming\Tencent\WeChat\XPlugin\Plugins\WMPFRuntime`
- 如下

![](cache.png)

> 要退出微信才能删除成功

- 删除数据，重新登录微信，然后我们来试试抓 王者荣耀 小程序如下：

![](hero.png)

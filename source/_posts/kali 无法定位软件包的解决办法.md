---
title: kali 无法定位软件包的解决办法
date: 2017-07-17 21:07:29
tags: [干货, Linux]
categories: 网络运维
---
# kali 无法定位软件包的解决办法

### 挺说kali 有多牛逼多牛逼，然后就装了。想装个拼音就报个 无法定位软件包错误，，
![](1499924551612055201.png)

## 解决方案如下：更新apt 的源
#### 1、修改apt源的文件，路径为 /etc/apt/sources.list
```
vim /etc/apt/sources.list
```
#### 2、apt-get update  更新一下
```
apt-get update
```
> 图如下：

![](1499925249090014886.png)


## Kali 2.0 更新源
```
#中科大
deb http://mirrors.ustc.edu.cn/kali kali-rolling main non-free contrib
deb-src http://mirrors.ustc.edu.cn/kali kali-rolling main non-free contrib
 
#阿里云
#deb http://mirrors.aliyun.com/kali kali-rolling main non-free contrib
#deb-src http://mirrors.aliyun.com/kali kali-rolling main non-free contrib
 
#清华大学
#deb http://mirrors.tuna.tsinghua.edu.cn/kali kali-rolling main contrib non-free
#deb-src https://mirrors.tuna.tsinghua.edu.cn/kali kali-rolling main contrib non-free
 
#浙大
#deb http://mirrors.zju.edu.cn/kali kali-rolling main contrib non-free
#deb-src http://mirrors.zju.edu.cn/kali kali-rolling main contrib non-free
 
#东软大学
#deb http://mirrors.neusoft.edu.cn/kali kali-rolling/main non-free contrib
#deb-src http://mirrors.neusoft.edu.cn/kali kali-rolling/main non-free contrib
 
#官方源
#deb http://http.kali.org/kali kali-rolling main non-free contrib
#deb-src http://http.kali.org/kali kali-rolling main non-free contrib
 
#重庆大学
#deb http://http.kali.org/kali kali-rolling main non-free contrib
#deb-src http://http.kali.org/kali kali-rolling main non-free contrib
```

## Kali 1.0--更新源
```
#官方源
deb http://http.kali.org/kali kali main non-free contrib
deb-src http://http.kali.org/kali kali main non-free contrib
deb http://security.kali.org/kali-security kali/updates main contrib non-free
 
#中科大kali源
deb http://mirrors.ustc.edu.cn/kali kali main non-free contrib
deb-src http://mirrors.ustc.edu.cn/kali kali main non-free contrib
deb http://mirrors.ustc.edu.cn/kali-security kali/updates main contrib non-free
 
#新加坡kali源
deb http://mirror.nus.edu.sg/kali/kali/ kali main non-free contrib
deb-src http://mirror.nus.edu.sg/kali/kali/ kali main non-free contrib
deb http://security.kali.org/kali-security kali/updates main contrib non-free
deb http://mirror.nus.edu.sg/kali/kali-security kali/updates main contrib non-free
deb-src http://mirror.nus.edu.sg/kali/kali-security kali/updates main contrib non-free
 
#阿里云kali源
deb http://mirrors.aliyun.com/kali kali main non-free contrib
deb-src http://mirrors.aliyun.com/kali kali main non-free contrib
deb http://mirrors.aliyun.com/kali-security kali/updates main contrib non-free
 
#163 Kali源
deb http://mirrors.163.com/debian wheezy main non-free contrib 
deb-src http://mirrors.163.com/debian wheezy main non-free contrib 
deb http://mirrors.163.com/debian wheezy-proposed-updates main non-free contrib 
deb-src http://mirrors.163.com/debian wheezy-proposed-updates main non-free contrib 
deb-src http://mirrors.163.com/debian-security wheezy/updates main non-free contrib 
deb http://mirrors.163.com/debian-security wheezy/updates main non-free contrib
 
 
#上海交大 Kali源 (比较慢，直接忽略)
#deb http://ftp.sjtu.edu.cn/debian wheezy main non-free contrib
#deb-src http://ftp.sjtu.edu.cn/debian wheezy main non-free contrib 
#deb http://ftp.sjtu.edu.cn/debian wheezy-proposed-updates main non-free contrib 
#deb-src http://ftp.sjtu.edu.cn/debian wheezy-proposed-updates main non-free contrib 
#deb http://ftp.sjtu.edu.cn/debian-security wheezy/updates main non-free contrib 
#deb-src http://ftp.sjtu.edu.cn/debian-security wheezy/updates main non-free contrib
```

> 原文出自：http://www.cnblogs.com/dunitian/p/6264806.html

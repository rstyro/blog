---
title: Linux安装最新版Git
date: 2019-05-05 11:42:47
tags:
---

## 安装Git
在linux中，安装Git 一般一条命令即可，如下：  

+ Debian/Ubuntu
`apt-get install git`
+ 或者先更新
`apt update; apt install git`

+ Fedora 系列
`yum install git`
`dnf install git`

+ Gentoo 系列
`emerge --ask --verbose dev-vcs/git`

+ Arch Linux 系列
`pacman -S git`

+ openSUSE 系列
`zypper install git`

+ Mageia 系列
`urpmi git`

+ Nix/NixOS 系列
`nix-env -i git`

+ FreeBSD 系列
`pkg install git`

+ Solaris 9/10/11  (OpenCSW) 系列
`pkgutil -i git`


> 但是有时安装的版本比较旧。不是我们想要的  

## 最新版安装
在Github,[https://github.com/git/git/releases](https://github.com/git/git/releases) 下载最新版本。  
在2019-5-5，最新版本为：`v2.21.0`  
![](/Linux安装最新版Git/git0.png)

+ 下载v2.21.0版本  
`wget https://github.com/git/git/archive/v2.21.0.tar.gz`
+ 安装依赖  
`yum -y install curl-devel expat-devel gettext-devel openssl-devel zlib-devel gcc perl-ExtUtils-MakeMaker`
+ 解压  
`tar -zxvf v2.21.0.tar.gz`
+ 进入解压目录  
`cd git-2.21.0/`
+ 编译  
`make prefix=/usr/local/git all`
+ 安装Git在/usr/local/git路径  
`make prefix=/usr/local/git install`

+ 配置环境变量    

```
# 编辑环境配置文件
vim /etc/profile

# 末尾添加
export PATH=/usr/local/git/bin:$PATH

# 立马生效
source /etc/profile
```


> git version 查看安装的git版本，校验通过，安装成功。

![](/Linux安装最新版Git/git1.png)
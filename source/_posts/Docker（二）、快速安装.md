---
title: Docker（二）、快速安装
date: 2018-01-11 01:14:08
updated: 2018-01-11 01:14:08
tags: [Docker]
categories: 开发工具
---
# Docker的安装
```
$ uname -r
```
> 检查内核版本，返回的值大于3.10即可。

## 一、在Ubuntu中安装Docker
### 官网文档地址：[https://docs.docker.com/install/linux/docker-ce/ubuntu/#prerequisites](https://docs.docker.com/install/linux/docker-ce/ubuntu/#prerequisites)

### 1、安装Ubuntu维护的版本
```
$sudo apt-get install docker.io
$source /etc/bash_completion.d/docker.io
```
然后查看版本，检测是否安装成功：
```
$sodu docker.io version
```
### 2、安装Docker维护的版本
#### 这里也分为二种方式
#### 方法一（推荐）
```
$ sudo apt-get update
$ sudo apt-get install docker-ce
```
#### 方法二
下载docker 写好的安装脚本，直接运行即可
```
$ sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
```


## 二、在Windows中安装Docker
因为docker 依赖与Linux 内核的Namespaceh和Cgroups，所以需要一种虚拟机来实现
下载页面：https://store.docker.com/editions/community/docker-ce-desktop-windows
下载地址：https://download.docker.com/win/stable/Docker%20for%20Windows%20Installer.exe


## 三、在Mac中安装Docker
下载页面：https://store.docker.com/editions/community/docker-ce-desktop-mac
下载地址:https://download.docker.com/mac/stable/Docker.dmg

## 四、在Centos 中
嘿嘿，我比较熟Centos ，只有这个是亲测的，其他的都是官方的文档
### 官网文档地址：[https://docs.docker.com/install/linux/docker-ee/centos/#package-install-and-upgrade](https://docs.docker.com/install/linux/docker-ee/centos/#package-install-and-upgrade)
#### 1、卸载旧版本(如果安装过旧版本的话)
```
$ sudo yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-selinux \
                  docker-engine-selinux \
                  docker-engine \
                  docker-ce
```
#### 2、下载官方的安装脚本并运行
```
# 方法一 
yum install -y docker

# 方法二
curl -sSL https://get.docker.com | sh
```
#### 3、启动docker
```
# centos 7 启动命令 
$ sudo systemctl start docker


# 开启自启动
systemctl enable docker
```
#### 4、查看版本
```
$ docker version

# 查看docker 的信息
$ docker info
```
![](90816.png)

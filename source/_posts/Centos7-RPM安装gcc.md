---
title: Centos7-RPM安装gcc
date: 2018-11-03 17:03:47
updated: 2018-11-03 17:03:47
tags: [Linux,开发工具]
categories: 网络运维
---

### 一、前言
有时yum用不了，比如没联网，本地也没有镜像。缺好多依赖很烦

### 二、下载RMP镜像
+ 下载地址：[http://mirrors.163.com/centos/7/os/x86_64/Packages/](http://mirrors.163.com/centos/7/os/x86_64/Packages/)
+ 下载以下镜像：
```
cpp-4.8.5-44.el7.x86_64.rpm
gcc-4.8.5-44.el7.x86_64.rpm
glibc-2.17-317.el7.x86_64.rpm
glibc-common-2.17-317.el7.x86_64.rpm
glibc-devel-2.17-317.el7.x86_64.rpm
glibc-headers-2.17-317.el7.x86_64.rpm
glibc-static-2.17-317.el7.x86_64.rpm
glibc-utils-2.17-317.el7.x86_64.rpm
kernel-headers-3.10.0-1160.el7.x86_64.rpm
libmpc-1.0.1-3.el7.x86_64.rpm
mpfr-3.1.1-4.el7.x86_64.rpm

```
**放在同一目录**

### 三、安装
进入上面包含镜像的目录执行安装命令
```js
// 运行此命令会根据依赖按照顺序安装rpm
// --nodeps rpm在安装包时，不检查依赖关系，例如安装B，B依赖C导致无法安装，使用--nodeps就可以安装成功 
rpm -Uvh *.rpm --nodeps --force
```

**校验版本**
```
gcc -v
```

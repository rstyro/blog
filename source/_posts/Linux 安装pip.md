---
title: Linux 安装pip
date: 2017-11-30 11:34:51
tags: [Linux]
categories: 网络运维
---
## 1.YUM安装
联网情况下，
```
yum -y install epel-release
yum -y install python-pip
 ```


## 2、要安装或升级pip，需要下载 get-pip.py.
地址：[https://bootstrap.pypa.io/get-pip.py](https://bootstrap.pypa.io/get-pip.py)
然后运行以下命令
```
python get-pip.py
```
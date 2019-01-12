---
title: MongoDB (二)：搭建MongoDB 服务
date: 2017-10-23 11:09:16
tags: [MongoDB]
categories: 数据库
---
# 上次已经讲了安装，且启动了默认的配置
## 现在我们就来手动的配置下
## 一、创建服务器所在目录
```
mkdir -p /data/mongodb
```
## 二、创建数据所在目录
```
# 数据存放目录
mkdir -p /data/mongodb/data
# 生成log目录
mkdir -p /data/mongodb/log
# 配置文件目录
mkdir -p /data/mongodb/conf
```
## 三、创建配置文件
```
vim /data/mongodb/conf/mongod.conf
```
#### 添加如下内容：
```
# 启动端口 27017 是默认的端口，可以改
port = 27017
dbpath = /data/mongodb/data
logpath=/data/mongodb/log/mongo.log
# 是否后台启动
fork = true

```
## 四、启动
```
# 我这是配过环境变量的，所以可以在什么地方都可以执行，没有配，请到mongodb 的bin目录下执行
mongod -f /data/mongodb/conf/mongod.conf
```

## 五、添加自启动
##### 服务器重启每次都要手动启动mongodb，很麻烦，那就给它自启动吧
##### 编辑 `/etc/rc.local` 在最后加上：
```
/usr/local/mongodb/bin/mongod -f /data/mongodb/conf/mongod.conf
```

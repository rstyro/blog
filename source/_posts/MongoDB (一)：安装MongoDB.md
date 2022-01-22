---
title: MongoDB (一)：安装MongoDB
date: 2017-10-23 10:20:04
updated: 2017-10-23 10:20:04
tags: [MongoDB]
categories: 数据库
---
# Linux 简单搭建mongodb
> 我以 centos 为例


## 一、下载源码包
### 去官网下载源码包：[https://www.mongodb.com/download-center#community](https://www.mongodb.com/download-center#community)
```
# 下载对应你版本号的包，我这个是红帽的
wget https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-rhel70-3.4.9.tgz
```
## 二、解压
### 我直接解压到 /usr/local 下
```
tar -zxvf mongodb-linux-x86_64-rhel70-3.4.9.tgz -C /usr/local/
# 重命名为 mongodb
mv mongodb-linux-x86_64-rhel70-3.4.9 mongodb
```
## 三、配置环境变量（可选）
### 配置环境变量是为了启动的时候，都不用去mongodb 的bin 目录下启动。在 `/etc/profile` 加入如下代码：
```
# MONGODB_HOME 就是你解压到的地方路径
MONGODB_HOME=/usr/local/mongodb
# 添加进 path 路径
export PATH=${MONGODB_HOME}/bin:$PATH
```

## 四、创建数据存贮 目录
### MongoDB的数据存储在data目录的db目录下，但是这个目录在安装过程不会自动创建，所以你需要手动创建data目录，并在data目录中创建db目录。
### 以下实例中我们将data目录创建于根目录下(/)。
### 注意：/data/db 是 MongoDB 默认的启动的数据库路径(--dbpath)。
```
# -p 递归创建目录
mkdir -p /data/db
```

## 五、启动
```
# 如果按上面的配置，--dbpath 这个参数可不加。
mongod --dbpath=/data/db &
# 连接 mongodb
mongo
```

#### 顺便说一下，就是启动的时候有几个警告
```
1、  读写没有限制
2、  使用root用户
3、  建议使用 numactl –interleave选项
```
#### 一般开启权限认证和创建用户，这些警告就都消失了。比如下方的连接方式
```
//对admin 数据库进行权限认证
mongo -port 27017 -u "yourUsername" -p "youPassword" --authenticationDatabase "admin"

```

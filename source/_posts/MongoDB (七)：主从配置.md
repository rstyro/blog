---
title: MongoDB (七)：主从配置
date: 2017-10-26 18:13:01
updated: 2017-10-26 18:13:01
tags: [MongoDB]
categories: 数据库
---
# mongodb 主从复制配置
## 主从复制也是挺常见数据备份了。
### 可以配置一主一从，或一主多从。明确一点就是只有一个主，我这里演示一主多从
## 一、环境
#### 3台主机：（当然你在一台机器上启动多个服务端也是可以的）
+ 主 ip： 192.168.12.132
+ 从 ip： 192.168.12.133
+ 从 ip： 192.168.12.134

## 二、配置

### 准备工作：
#### (a)、创建mongodb 的数据存储目录
#### (b)、创建mongodb 的log目录
#### (c)、创建mongodb 的配置文件目录
```
mkdir -p /usr/local/mongodb/data
mkdir -p /usr/local/mongodb/logs
mkdir -p /usr/local/mongodb/conf
```
### 上面的命令3台都要执行
 
### 1、在(主)192.168.12.132 创建配置文件,`vim /usr/local/mongodb/conf/22222.cnf` 添加如下内容:
```
port=22222
# mongodb 数据存储位置
dbpath=/usr/local/mongodb/data
# log 生成位置
logpath=/usr/local/mongodb/logs/mongo.log
fork=true
# auth=true
# 这是绑定主机ip
bind_ip=192.168.12.132
# master 来确定哪个是主
master=true
```

### 2、在(从)192.168.12.133 创建配置文件,`vim /usr/local/mongodb/conf/33333.cnf` 添加如下内容:
```
port=33333
fork=true
dbpath=/usr/local/mongodb/data
logpath=/usr/local/mongodb/logs/33333.log
bind_ip=192.168.12.133
# 来指定 主 的数据来源
source=192.168.12.132:22222
# slave 来确定是从
slave=true

```

###3、在(从)192.168.12.134 创建配置文件,`vim /usr/local/mongodb/conf/44444.cnf` 添加如下内容:
```
port=44444
fork=true
dbpath=/usr/local/mongodb/data
logpath=/usr/local/mongodb/logs/44444.log
bind_ip=192.168.12.134
# 来指定 主 的数据来源
source=192.168.12.132:22222
# slave 来确定是从
slave=true
```

> 小结： 由master 来确定主服务器，slave 与source 来确定从服务器

## 三、启动
### 我已经配置好了环境变量
```
# 在主192.168.12.132服务器上运行
mongod -f /usr/local/mongodb/conf/22222.conf

# 在从192.168.12.133服务器上运行
mongod -f /usr/local/mongodb/conf/33333.conf

# 在从192.168.12.134服务器上运行
mongod -f /usr/local/mongodb/conf/33333.conf
```
## 四、连接
```
# 连接主服务器
mongo 192.168.12.132:22222

# 测试 是否是主
rs.isMaster()
```


### 在主中插入数据，从也是可以找到的。就ok了


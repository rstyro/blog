---
title: Redis 主从复制
date: 2017-06-18 21:30:13
updated: 2017-06-19 21:30:13
tags: [Redis]
categories: 网络运维
---
# Redis 集群
## 一、准备工作
+ 安装redis
+ 创建3个不同端口的配置文件

## 二、配置文件
在redis 的所在目录下创建一个 config 文件夹，并复制3份redis 的默认配置文件redis.conf 到里面。

<!--more-->

```
mkdir config

# 复制默认的配置文件到/usr/local/redis/config/ 下并重命名未redis6379.conf
cp /opt/redis-3.2.1/redis.conf /usr/local/redis/config/redis6379.conf
# 复制其他两份
cp redis6379.conf redis6380.conf
cp redis6379.conf redis6381.conf
```
上面的配置文件后面的数字代表的是启动的端口，
vim 修改3个配置文件只需要修改 `port`,`pidfile`,`daemonize`,`logfile`,`dbfilename`这5个值

|配置|说明|
|--|-- |
|port|启动的端口|
|pidfile|PID 的文件位置|
|daemonize|是否后台启动|
|logfile|产生log的文件位置|
|dbfilename|rdb 文件配置的位置|

都很简单，而且文件很长，就不粘贴了
## 三、启动redis 服务
```
bin/redis-server config/redis6379.conf
bin/redis-server config/redis6380.conf
bin/redis-server config/redis6381.conf
```
**开启3个客户端连接各个不同端口的服务器，身份都是master**
![](63519.png)
## 四、配置主从关系
**通过`slaveof ip 端口` 的命令，把6380和6381当slave的身份。
在两台从服务器上运行如下命令：**
```
SLAVEOF 127.0.0.1 6379
```
如下图：
![](04687.png)
> 除了手动写命令连接之外，也可以在redis6380.conf(和redis6381.conf)文件中配置:  `slaveof <masterip> <masterport>` 
> `SLAVEOF 127.0.0.1 6379`
> 如果redis 是设置密码的话就加：`masterauth yourPassword`

**现在在6379端口设置值，我们测试在6380和6381端口能不能获取值**
![](12938.png)

+ 如果master 宕机了，slave 还是slave
+ 如果master 又重新启动了，它还是会变成原来的master
+ 如果slave 宕机了，启动之后不会变成slave,除非写进配置文件，不然它就会变成一个单机的服务器
+ 如果我们想让slave 可以上位的话，可以看下面的哨兵模式。

## 五、哨兵模式
**哨兵模式简单的说呢，就是反客为主，就是主机死了，从所有从机中选出一个主机。**
**哨兵模式就是在主从复制的情况下，保证服务高可用，slave是没有写入操作的只有master可以。**
#### 1、配置哨兵文件
我们在redis6379.conf 的同目录下创建一个`sentinel.conf`，或复制一份默认的 `sentinel.conf` 在其基础上更改。
编辑内容如下：
```
# 这个端口和redis的启动端口不一样
port 26379
daemonize yes
bind 0.0.0.0
logfile "/usr/local/redis/logs/sentinel.log"

# masterName是我随便取的一个主机的名字
# 后面的数字1 是有多少个哨兵节点选举才生效，建议哨兵节点数 一半加1
# 如果哨兵节点有多个，然后数字是1就会有bug。master节点一直在变
sentinel monitor masterName  127.0.0.1 6379 1
# 需要密码的时候，可以加下面这行
sentinel auth-pass masterName yourPassword
```
**上面的意思：就是监控6379这主机挂了的时候，从机来投票，谁得票数多谁就是主机！**
> 上面的sentinel.conf 也是有默认的配置文件，也可以复制默认的配置文件，然后根据自己的需求来修改即可。

#### 2、启动哨兵模式
```
bin/redis-sentinel config/sentinel.conf
```
#### 3、监听测试
**现在我们让6379死机，看一下哨兵会发生什么**
![](39624.png)

**看看哨兵的情况，是否发生变化**
![](72549.png)

**看上面的日志，我们可以看到6381变成主机了，如下图：**
![](72583.png)

**然后当6379启动的时候，变成了从机，而不是主机了**
![](38065.png)


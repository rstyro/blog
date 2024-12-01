---
title: Rocketmq 配置双主双从
date: 2017-09-25 16:32:27
updated: 2017-09-25 16:32:27
tags: [MQ]
categories: MQ
---
# Rocketmq 配置双Master双Slave
> 这个配置基本流程和Rocketmq 配置双master 是一样的。
> 具体可参考：http://www.lrshuai.top/atc/show/48  只需要修改第三步骤的配置文件就可。

## 1、环境
#### 4台电脑
+ 192.168.12.132  主（broker-a）,开启nameserver
+ 192.168.12.133  主（broker-b）,开启nameserver
+ 192.168.12.134  从（broker-a）
+ 192.168.12.135  从（broker-b）

<!--more-->

## 2、修改配置文件
### 注意： 比如　编译什么的和配置双master 一样我就不重复了。

### rocketmq/conf 下的文件说明：
+ 2m-2s-async     -----------   异步复制
+ 2m-2s-sync	 ------------  同步双写
+ 2m-noslave      ------------  多master模式

#### 我今天演示的是同步双写，所以修改 2m-2s-sync 目录下的配置文件

##### broker-a.properties
```
#所属集群名字
brokerClusterName=rocketmq-cluster
#broker名字，注意此处不同的配置文件填写的不一样，如果是broker-a.properties 这里就写broker-a,broker-b.properties 这里就写broker-b,以此类推
brokerName=broker-a
#强制指定本机IP，需要根据每台机器进行修改。官方介绍可为空，系统默认自动识别，但多网卡时IP地址可能读取错误
brokerIP1=192.168.12.132
#0 表示 Master， >0 表示 Slave
brokerId=0
#nameServer地址，分号分割
namesrvAddr=192.168.12.132:9876;192.168.12.133:9876
#在发送消息时，自动创建服务器不存在的topic，默认创建的队列数
defaultTopicQueueNums=4
#是否允许 Broker 自动创建Topic，建议线下开启，线上关闭
autoCreateTopicEnable=true
#是否允许 Broker 自动创建订阅组，建议线下开启，线上关闭
autoCreateSubscriptionGroup=true
#Broker 对外服务的监听端口
listenPort=10911
#删除文件时间点，默认凌晨 0点
deleteWhen=00
#文件保留时间，默认 48 小时
fileReservedTime=120
#commitLog每个文件的大小默认1G
mapedFileSizeCommitLog=1073741824
#ConsumeQueue每个文件默认存30W条，根据业务情况调整
mapedFileSizeConsumeQueue=300000
#destroyMapedFileIntervalForcibly=120000
#redeleteHangedFileInterval=120000
#检测物理文件磁盘空间
diskMaxUsedSpaceRatio=88
#存储路径
storePathRootDir=/usr/local/rocketmq/data
#commitLog 存储路径
storePathCommitLog=/usr/local/rocketmq/data/commitlog
#消费队列存储路径存储路径
storePathConsumeQueue=/usr/local/rocketmq/data/consumequeue
#消息索引存储路径
storePathIndex=/usr/local/rocketmq/data/index
#checkpoint 文件存储路径
storeCheckpoint=/usr/local/rocketmq/data/checkpoint
#abort 文件存储路径
abortFile=/usr/local/rocketmq/data/abort
#限制的消息大小
maxMessageSize=65536
#flushCommitLogLeastPages=4
#flushConsumeQueueLeastPages=2
#flushCommitLogThoroughInterval=10000
#flushConsumeQueueThoroughInterval=60000
#Broker 的角色
#- ASYNC_MASTER 异步复制Master
#- SYNC_MASTER 同步双写Master
#- SLAVE
brokerRole=SYNC_MASTER
#刷盘方式
#- ASYNC_FLUSH 异步刷盘
#- SYNC_FLUSH 同步刷盘
flushDiskType=SYNC_FLUSH
#checkTransactionMessageEnable=false
#发消息线程池数量
#sendMessageThreadPoolNums=128
#拉消息线程池数量
#pullMessageThreadPoolNums=128
```
##### broker-a-s.properties
```
#所属集群名字
brokerClusterName=rocketmq-cluster
#broker名字，注意此处不同的配置文件填写的不一样，如果是broker-a.properties 这里就写broker-a,broker-b.properties 这里就写broker-b,以此类推
brokerName=broker-a
#强制指定本机IP，需要根据每台机器进行修改。官方介绍可为空，系统默认自动识别，但多网卡时IP地址可能读取错误
brokerIP1=192.168.12.134
#0 表示 Master， >0 表示 Slave
brokerId=1
#nameServer地址，分号分割
namesrvAddr=192.168.12.132:9876;192.168.12.133:9876
#在发送消息时，自动创建服务器不存在的topic，默认创建的队列数
defaultTopicQueueNums=4
#是否允许 Broker 自动创建Topic，建议线下开启，线上关闭
autoCreateTopicEnable=true
#是否允许 Broker 自动创建订阅组，建议线下开启，线上关闭
autoCreateSubscriptionGroup=true
#Broker 对外服务的监听端口
listenPort=10911
#删除文件时间点，默认凌晨 0点
deleteWhen=00
#文件保留时间，默认 48 小时
fileReservedTime=120
#commitLog每个文件的大小默认1G
mapedFileSizeCommitLog=1073741824
#ConsumeQueue每个文件默认存30W条，根据业务情况调整
mapedFileSizeConsumeQueue=300000
#destroyMapedFileIntervalForcibly=120000
#redeleteHangedFileInterval=120000
#检测物理文件磁盘空间
diskMaxUsedSpaceRatio=88
#存储路径
storePathRootDir=/usr/local/rocketmq/data
#commitLog 存储路径
storePathCommitLog=/usr/local/rocketmq/data/commitlog
#消费队列存储路径存储路径
storePathConsumeQueue=/usr/local/rocketmq/data/consumequeue
#消息索引存储路径
storePathIndex=/usr/local/rocketmq/data/index
#checkpoint 文件存储路径
storeCheckpoint=/usr/local/rocketmq/data/checkpoint
#abort 文件存储路径
abortFile=/usr/local/rocketmq/data/abort
#限制的消息大小
maxMessageSize=65536
#flushCommitLogLeastPages=4
#flushConsumeQueueLeastPages=2
#flushCommitLogThoroughInterval=10000
#flushConsumeQueueThoroughInterval=60000
#Broker 的角色
#- ASYNC_MASTER 异步复制Master
#- SYNC_MASTER 同步双写Master
#- SLAVE
brokerRole=SLAVE
#刷盘方式
#- ASYNC_FLUSH 异步刷盘
#- SYNC_FLUSH 同步刷盘
flushDiskType=SYNC_FLUSH
#checkTransactionMessageEnable=false
#发消息线程池数量
#sendMessageThreadPoolNums=128
#拉消息线程池数量
#pullMessageThreadPoolNums=128
```
#### 区别在哪呢
##### 总修改的地方有：
+ 1、brokerName （broker-a 和broker-b 不一样而已）
+ 2、brokerId
+ 3、brokerRole
+ 4、brokerIP1     （这个配置可选）

### broker-b.properties 与 broker-a.properties 类似。
### broker-b-s.properties 与 broker-a-s.properties 类似
## 我就不弄出来了。
#### (a)、broker-b.properties 就是在broker-a.properties 的基础上改 `brokerName` 就可了
#### (b)、broker-b-s.properties 就是在broker-a-s.properties 的基础上改 `brokerName` 就可了

## 3、启动
#### 和配置双master的方法启动一样
> 我这里只有两台namesrv,你弄4台更好
> 注意： 开放端口
> 9876 （nameserver 端口）
> 10909（主要是fastRemotingServer服务使用）
> 10911（Broker 对外服务的监听端口）
> 10912 (Master 和Slave同步的数据的端口，)

![](1504513028537098743.png)


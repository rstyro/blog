---
title: MongoDB (八)：副本集配置
date: 2017-10-27 16:19:23
tags: [MongoDB]
categories: 数据库
---
# mongodb 副本集配置
## 副本集概念：就我的理解就是和主从复制 差不多，就是在主从复制的基础上多加了一个选举的机制。
### 复制集 特点：
#### 数据一致性
+ 主是唯一的，没有Mysql 那样的双主结构
+ 大多数原则，集群存活节点小于二分之一是集群不可写，只可读
+ 从库无法写入数据
+ 自动容灾
## 通过下面的一个图来简单的了解下
![](/MongoDB (八)：副本集配置/78092.png)

# 配置过程：
## 一、安装mongodb
#### 安装过程略，不懂得可以看前面的教程

## 二、创建存储目录与配置文件
#### 创建如下文件，结构图如下： 
![](/MongoDB (八)：副本集配置/68435.png)
#### 22222.conf 文件内容如下：
```
dbpath=/data/mongodb1/dbdata
logpath=/data/mongodb1/logs/mongodb.log
port=22222
bind_ip=127.0.0.1
replSet=copydb/127.0.0.1:33333
fork=true
```
##### 33333.conf 文件内容如下：
```
dbpath=/data/mongodb2/dbdata
logpath=/data/mongodb2/logs/mongodb.log
port=33333
bind_ip=127.0.0.1
replSet=copydb/127.0.0.1:44444
fork=true
```
##### 44444.conf 文件内容如下：
```
dbpath=/data/mongodb3/dbdata
logpath=/data/mongodb3/logs/mongodb.log
port=44444
bind_ip=127.0.0.1
replSet=copydb/127.0.0.1:22222
fork=true
```

#### 配置常用参数说明：
|参数|说明|
|---|---|
|dbpath|存储路径|
|logpath|log 生成的路径|
|port|端口|
|bing_ip|绑定的ip，所在服务器的ip|
|replSet|copydb 这个可以说是复制集的名字随意改，这个连接在复制集中形成一个闭环就可以了|
|auth|是否启动认证|
|fork|true 已守护进程运行|
|keyFile|集群的私钥的完整路径|
|pidfilepath| PID File 的完整路径，如果没有设置，则没有PID文件|
|journal|启用日志选项，MongoDB的数据操作将会写入到journal文件夹的文件里|
|logappend|是否追加|
|oplogSize|指定oplog大小，单位MB，建议设大点|
## 三、启动
```
mongod -f /data/mongodb1/conf/22222.conf
mongod -f /data/mongodb2/conf/33333.conf
mongod -f /data/mongodb3/conf/44444.conf
```
![](/MongoDB (八)：副本集配置/97834.png)
## 四、初始化副本集
#### 随便连接一个，然后初始化副本集
```
# 连接
mongo -port 22222
# 选择admin数据库
use admin
# 初始化副本集，_id:copydb 就是上面配置中 的replSet 的 copydb 
db.runCommand({"replSetInitiate":{_id:"copydb",members:[{_id:1,host:"127.0.0.1:22222"},{_id:2,host:"127.0.0.1:33333"},{_id:3,host:"127.0.0.1:44444"}]}})

```
![](/MongoDB (八)：副本集配置/32940.png)

![](/MongoDB (八)：副本集配置/45970.png)

### 初始化副本集的参数说明
|_id|整数|id:0|
|--|---|
|host|字符串|地址|
|arbiterOnly  |布尔值|默认为false,如果是true 只作为选举节点，不进行备份|
|priority |整数型|  权重默认是1，取值范围0-1000 ，如果为0永远不能为主节点。|
|hidden   |布尔值|  当前从节点对程序不可见，|
|votes  |整数型  | 投票数 0/1|
|slaveDelay	|整数型 | 默认 0， 从节点为延迟节点例如，slaveDelay=3600 延迟3600 秒，进行数据同步|
|buildIndexes  |布尔值| 默认为true, 从节点是否创建索引|

#### 可通过 `rs.config()` 来查看配置信息


#### 这样就算配置成功了。是不是很简单。。。可以自己测试数据，我这里就不操作了.....


#### 注意： 没有初始化副本集之前最好不要执行 插入之类的操作，节点不是PRIMARY 的，一般在shell是不能查询操作的，但可以执行` rs.slaveOk()` 就可以查询了。

> 官方的说明：
> db.getMongo().setSlaveOk()
This allows the current connection to allow read operations to run on secondary members. See the readPref() method for more fine-grained control over read preference in the mongo shell.

## 五、关于副本集的工作流程
> 图片来自慕客网视频

![](/MongoDB (八)：副本集配置/32847.png)
#### oplog的工作流程
![](/MongoDB (八)：副本集配置/71695.png)


#### oplog 是异步的，每个节点都有
#### Oplog 的结构参数说明：
|参数|说明|
|--|--|
|ts|操作发生时的时间戳|
|h|此操作的独一无二的ID|
|v|oplog 的版本|
|op|操作类型：i --- insert,u --- upadte d---delete，c--cmd ,n -- null|
|ns|操作所处的命名空间 db_name,coll_name|
|o|操作对应的文档|
|o2|仅update 操作时有，更新操作的变更条件|

### oplog 的特点： 利用封顶表 capped collection 滚动覆盖写入，固定大小或固定条数（不推荐）

### oplog 是在local 数据库中
```
use local

# 查看状态
db.oplog.rs.stats()

# 查询最后一条的记录
db.oplog.rs.find().sort({$natural:-1}).limit(1).pretty()
```
![](/MongoDB (八)：副本集配置/65207.png)


---
title: Redis 笔记总结
date: 2017-06-18 18:30:03
tags: [Redis]
categories: 笔记
---
**很早之前就使用redis 了，但都没有好好总结过，来一次吧**
## 一、Redis 事务
### 1、redis 与mysql事务的对比
||mysql|redis|
|--|--|--|
|开启|start transaction|multi|
|语句|普通的sql语句|普通的命令|
|失败|rollback 回滚|discard 取消|
|成功|commit|exec|

##### 注意一: rollback与discard 的区别
如果已经成功执行了2条语句, 第3条语句出错.
Rollback后,前2条的语句影响消失.
Discard只是结束本次事务,前2条语句造成的影响仍然还在

##### 注意二:在multi后面的语句中, 语句出错可能有2种情况
+ 1: 语法就有问题, 
这种,exec时,报错, 所有语句得不到执行

+ 2: 语法本身没错,但适用对象有问题. 比如 zadd 操作list对象
Exec之后,会执行正确的语句,并跳过有不适当的语句.

> (如果zadd操作list这种事怎么避免? 这一点,由程序员负责)

### 2、watch命令
Redis的事务中,启用的是乐观锁,只负责监测key没有被改动。所以我们有需要的可以`watch`监听某个值是否发生了变化。
例: 
```
redis 127.0.0.1:6379> watch ticket
OK
redis 127.0.0.1:6379> multi
OK
redis 127.0.0.1:6379> decr ticket
QUEUED
redis 127.0.0.1:6379> decrby money 100
QUEUED
redis 127.0.0.1:6379> exec
(nil)   // 返回nil,说明监视的ticket已经改变了,事务就取消了.
redis 127.0.0.1:6379> get ticket
"0"
redis 127.0.0.1:6379> get money
"200"
```

`watch key1 key2  ... keyN`
作用:监听key1 key2..keyN有没有变化,如果有变, 则事务取消

`unwatch `
作用: 取消所有watch监听

## 二、redis 持久化
**Redis的持久化有2种方式   1快照  2是日志**

#### 1、Rdb快照的配置选项
每隔N秒或N次写操作后, 从内存dump数据形成rdb文件
```
save 900 1      # 900内,有1条写入,则产生快照 
save 300 1000   # 如果300秒内有1000次写入,则产生快照
save 60 10000  # 如果60秒内有10000次写入,则产生快照
# (这3个选项都屏蔽,则rdb禁用)

stop-writes-on-bgsave-error yes  # 后台备份进程出错时,主进程停不停止写入?
rdbcompression yes    # 导出的rdb文件是否压缩
Rdbchecksum   yes # 导入rbd恢复时数据时,要不要检验rdb的完整性
dbfilename dump.rdb  #导出来的rdb文件名
dir ./  #rdb的放置路径
```
##### 可以手动保存dump文件，使用命令：`save` 或者`bgsave`命令
两者的区别：
save只管保存，其他不管，全部阻塞，bgsave 会在后台异步进行快照操作，还可以响应客户端请求

#### 2、Aof 的配置
**把所有可写的操作都记录下来**
```
appendonly no # 是否打开 aof日志功能
appendfsync always   # 每1个命令,都立即同步到aof. 安全,速度慢
appendfsync everysec # 折衷方案,每秒写1次
appendfsync no      # 写入工作交给操作系统,由操作系统判断缓冲区大小,统一写入到aof. 同步频率低,速度快,
no-appendfsync-on-rewrite  yes: # 正在导出rdb快照的过程中,要不要停止同步aof
auto-aof-rewrite-percentage 100 #aof文件大小比起上次重写时的大小,增长率100%时,重写
auto-aof-rewrite-min-size 64mb #aof文件,至少超过64M时,重写
```
##### 可以手动重写使用命令：`bgrewriteaof `命令


**如果aof 文件出现异常，可以使用bin目录下的`redis-check-aof` 来修复，命令：`redis-check-aof -fix test.aof`.
同理，如果 dump 文件出现异常也可以使用`redis-check-dump`来修复。**
#### 3、常见问题
```
问: 在dump rdb过程中,aof如果停止同步,会不会丢失?
答: 不会,所有的操作缓存在内存的队列里, dump完成后,统一操作.

问: aof重写是指什么?
答: aof重写是指把内存中的数据,逆化成命令,写入到.aof日志里.
以解决 aof日志过大的问题.

bgrewriteaof 命令就是手动重写。如果,flushall之后,系统恰好bgrewriteaof了,那么aof就清空了,数据丢失.

问: 如果rdb文件,和aof文件都存在,优先用谁来恢复数据?
答: aof

问: 2种是否可以同时用?
答: 可以,而且推荐这么做

问: 恢复时rdb和aof哪个恢复的快
答: rdb快,因为其是数据的内存映射,直接载入到内存,而aof是命令,需要逐条执行

问: 如果不小心运行了flushall, 怎么办？
答：立即 shutdown nosave ,关闭服务器，然后 手工编辑aof文件, 去掉文件中的 “flushall ”相关行, 然后开启服务器,就可以导入回原来数据.


问:多慢才叫慢? 
答: 由slowlog-log-slower-than 10000 ,来指定,(单位是微秒)

问：服务器储存多少条慢查询的记录?
答: 由 slowlog-max-len 128 ,来做限制
```
## 三、消息订阅与发布

#### 1、消息的订阅
```
# 订阅频道channel1
subscribe channel1

# 订阅多个频道
subscribe channel1 channel2 channel3

# 订阅多个，通配符*
subscribe new*
```

#### 2、发布消息
```
# 往通道chanel1 发布内容
publish chanel1 发布的消息内容

# 往通道news 发布消息
publish news xxxxx
```
**慢慢更新吧**
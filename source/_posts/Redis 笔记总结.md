---
title: Redis 笔记总结
date: 2017-06-18 18:30:03
updated: 2017-06-18 18:30:03
tags: [Redis]
categories: 开发工具
---
## 前言
**很早之前就使用redis 了，但都没有好好总结过，来一次吧**

## 一、基础概述
+ Redis 是一个开源（BSD许可）的，内存中的数据结构存储系统，它可以用作数据库、缓存和消息中间件。

<!--more-->

#### 1、Redis支持的数据结构
+ strings（字符串）
+ hashes（散列）
+ lists（列表）
+ sets（集合）
+ zset （sorted sets有序集合） 
+ bitmaps （位图）
+ hyperloglogs （日志）
+ geospatial（地理空间）
+ streams （流）


## 二、redis 持久化

**Redis的持久化有2种方式**
+ 快照（RDB）  
+ 日志(AOF)

#### 1、Rdb快照的配置选项
+ RDB的配置如下：

```bash
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

+ 每隔N秒或N次写操作后, 从内存dump数据形成rdb文件
+ 可以手动保存dump文件，使用命令：`save` 或者`bgsave`命令
+ 两者的区别：
+ save只管保存，其他不管，全部阻塞，bgsave 会在后台异步进行快照操作，还可以响应客户端请求

#### 2、AOF 的配置
+ 开启AOF，配置如下：

```bash
appendonly no # 是否打开 aof日志功能
appendfsync always   # 每1个命令,都立即同步到aof. 安全,速度慢
appendfsync everysec # 折衷方案,每秒写1次
appendfsync no      # 写入工作交给操作系统,由操作系统判断缓冲区大小,统一写入到aof. 同步频率低,速度快,
no-appendfsync-on-rewrite  yes: # 正在导出rdb快照的过程中,要不要停止同步aof
auto-aof-rewrite-percentage 100 #aof文件大小比起上次重写时的大小,增长率100%时,重写
auto-aof-rewrite-min-size 64mb #aof文件,至少超过64M时,重写
```

+ 把所有可写的操作都记录下来
+ 可以手动重写使用命令：`bgrewriteaof `命令
+ 如果aof 文件出现异常，可以使用bin目录下的`redis-check-aof` 来修复，命令：`redis-check-aof -fix test.aof`.
+ 同理，如果 dump 文件出现异常也可以使用`redis-check-dump`来修复。

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

## 三、过期策略
+ redis我们可以给key设置一个过期时间，到时间会删除。redis是如果做到过期删除的呢？
+ 我们知道，redis设置过期的方法有`expires()`方法。它的实现原理是怎样的？
+ redis针对TTL时间有专门的dict进行存储，就是redisDb当中的`dict *expires`字段。
+ dict顾名思义就是一个`hashtable`，key为对应的rediskey，value为对应的TTL时间。
+ TTL设置key的过期方法有如下：

```
expire() 	按照相对时间且以秒为单位的过期策略
expireat() 	按照绝对时间且以秒为单位的过期策略
pexpire() 	按照相对时间且以毫秒为单位的过期策略
pexpireat()	 按照绝对时间且以毫秒为单位的过期策略
```

+ 判断key是否过期，key去db->expires找到过期时间对象，然后与当前系统时间相比计算差值
+ 如果键没有设置过期时间，那么返回 -1，否则返回剩余时间
+ 那key过期了，redis怎么知道，并且把key删了呢？
+ **Redis 删除失效主键的方法主要有两种： `passive`(惰性方法) 和 `active`(主动方法)**
+ `passive`：在键被访问时如果发现它已经失效，那么就删除它
+ `active`：定期去扫描键空间，删除过期的key
+ 详细介绍如下：


### 1、过期删除策略

**惰性方法**
+ 在大致了解了Redis是如何维护设置了失效时间的主键之后
+ 我们就先来看一看 Redis 是如何实现消极地删除失效主键的
+ Redis 有一个函数：`expireIfNeeded()` ,Redis 在实现 `GET`、`MGET`、`HGET`、`LRANGE` 等所有涉及到读取数据的命令时都会调用它。
+ 这个函数的内容如下：

```C
int expireIfNeeded(redisDb *db, robj *key) {
    if (!keyIsExpired(db,key)) return 0;

    /* If we are running in the context of a slave, instead of
     * evicting the expired key from the database, we return ASAP:
     * the slave key expiration is controlled by the master that will
     * send us synthesized DEL operations for expired keys.
     *
     * Still we try to return the right information to the caller,
     * that is, 0 if we think the key should be still valid, 1 if
     * we think the key is expired at this time. */
    if (server.masterhost != NULL) return 1;

    /* If clients are paused, we keep the current dataset constant,
     * but return to the client what we believe is the right state. Typically,
     * at the end of the pause we will properly expire the key OR we will
     * have failed over and the new primary will send us the expire. */
    if (checkClientPauseTimeoutAndReturnIfPaused()) return 1;

    /* Delete the key */
    if (server.lazyfree_lazy_expire) {
        dbAsyncDelete(db,key);
    } else {
        dbSyncDelete(db,key);
    }
    server.stat_expiredkeys++;
    propagateExpire(db,key,server.lazyfree_lazy_expire);
    notifyKeyspaceEvent(NOTIFY_EXPIRED,
        "expired",key,db->id);
    signalModifiedKey(NULL,db,key);
    return 1;
}
```

+ 通过一些方法名大致可以知道这个方法主要是判断key是否失效的。
+ 有个主要的地方就是：`propagateExpire()` 方法，这个是广播失效的key给到当前Redis服务器的所有 Slave
+ 告知这些 Slave 删除各自的失效的key


**主动方法：**
+ 通过对 `expireIfNeeded()` 函数的介绍了解了 Redis 是如何以一种消极的方式删除失效主键的
+ 如果某些失效的主键迟迟等不到再次访问的话，Redis 就永远不会知道这些主键已经失效.
+ 也就永远也不会删除它们了，这无疑会导致内存空间的浪费。Redis还准备了一招积极的删除方法
+ 通过Redis的时间事件来实现，即每隔一段时间就中断一下完成一些指定操作，其中就包括检查并删除失效主键。
+ 这里我们说的时间事件就是`serverCron`，它在 Redis 服务器启动时创建,在源码：`server.c`中的`initServer()`方法中
+ 有个`aeCreateTimeEvent()`的方法，创建时间事件回调来处理一些后台任务，如: 逐步执行操作，例如客户端超时,过期key,BGSAVE和AOF的触发等等
+ 我们主要看过期key,而处理过期key的方法是：`expire.c`里面的`activeExpireCycle()`方法。
+ activeExpireCycle执行删除key的方法是：`activeExpireCycleTryExpire()`。 源码(版本：6.2.3)如下：

```C
/* Helper function for the activeExpireCycle() function.
 * This function will try to expire the key that is stored in the hash table
 * entry 'de' of the 'expires' hash table of a Redis database.
 *
 * If the key is found to be expired, it is removed from the database and
 * 1 is returned. Otherwise no operation is performed and 0 is returned.
 *
 * When a key is expired, server.stat_expiredkeys is incremented.
 *
 * The parameter 'now' is the current time in milliseconds as is passed
 * to the function to avoid too many gettimeofday() syscalls. 
 */
int activeExpireCycleTryExpire(redisDb *db, dictEntry *de, long long now) {
    long long t = dictGetSignedIntegerVal(de);
    mstime_t expire_latency;
    if (now > t) {
        sds key = dictGetKey(de);
        robj *keyobj = createStringObject(key,sdslen(key));

		// 在删除前广播该主键的失效信息,广播到slave库，把键del放到aof文件中（如果开启的话）
        propagateExpire(db,keyobj,server.lazyfree_lazy_expire);
        latencyStartMonitor(expire_latency);
		// 删除key
        if (server.lazyfree_lazy_expire)
            dbAsyncDelete(db,keyobj);
        else
            dbSyncDelete(db,keyobj);
        latencyEndMonitor(expire_latency);
        latencyAddSampleIfNeeded("expire-del",expire_latency);
        notifyKeyspaceEvent(NOTIFY_EXPIRED,
            "expired",keyobj,db->id);
        signalModifiedKey(NULL, db, keyobj);
        decrRefCount(keyobj);
		// 更新关于失效键的统计个数
        server.stat_expiredkeys++;
        return 1;
    } else {
        return 0;
    }
}
```

+ 此外`activeExpireCycle`函数还有处理时间上的限制，不是想执行多久就执行多久，凡此种种都只有一个目的。
+ 那就是避免失效主键删除占用过多的CPU资源。
+ 参考原文链接：[https://www.aidandai.com/posts/redis-expire.html](https://www.aidandai.com/posts/redis-expire.html)

**其实我们从redis.conf的配置文件中可以看到介绍：**
+ 部分介绍说明：

```bash
# Redis reclaims expired keys in two ways: upon access when those keys are
# found to be expired, and also in background, in what is called the
# "active expire key". The key space is slowly and interactively scanned
# looking for expired keys to reclaim, so that it is possible to free memory
# of keys that are expired and will never be accessed again in a short time.
#
# The default effort of the expire cycle will try to avoid having more than
# ten percent of expired keys still in memory, and will try to avoid consuming
# more than 25% of total memory and to add latency to the system. However
# it is possible to increase the expire "effort" that is normally set to
# "1", to a greater value, up to the value "10". At its maximum value the
# system will use more CPU, longer cycles (and technically may introduce
# more latency), and will tolerate less already expired keys still present
# in the system. It's a tradeoff between memory, CPU and latency.
#
# active-expire-effort 1
```


+ 但是这里还是有问题
+ 因为不管主动还是被动删除key,都可能会有部分key没有及时清理（因为主动扫描是有时间限制的，而被动删除可能你没有访问它就不会删除）
+ 如果大量过期 key 堆积在内存里，导致 redis 内存块耗尽了，咋整？
+ 答案：内存淘汰机制

### 2、Redis的内存淘汰策略
+ 当Redis达到最大内存时，Redis将如何选择要删除的内容。
+ 可以选择的策略有如下

**maxmemory-policy:**
+ **noeviction**： 
	当内存不足以容纳新写入数据时，新写入操作会报错。默认策略
+ **volatile-lru：**
	 当内存不足以容纳新写入数据时，在设置了过期时间的键空间中，移除最近最少使用的key。
+ **allkeys-lru：**
	 当内存不足以容纳新写入数据时，在所有键空间中，移除最近最少使用的key。
+ **volatile-lfu：**
	 在设置了过期时间的键值对中，移除最近最不频繁使用的键值对
+ **allkeys-lfu：**
	 在所有的键值对中，移除最近最不频繁使用的键值对
+ **volatile-random：**
	 当内存不足以容纳新写入数据时，在设置了过期时间的键空间中，随机移除某个key。
+ **allkeys-random：**
	 当内存不足以容纳新写入数据时，在键空间中，随机移除某个key。
+ **volatile-ttl：**
	 当内存不足以容纳新写入数据时，在设置了过期时间的键空间中，有更早过期时间的key优先移除。

> `LRU`表示最近最少使用，`LFU`表示最少经常使用


## 四、消息订阅与发布

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

## 五、Redis 事务
+ redis也是支持事务的哦

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

**慢慢更新吧**

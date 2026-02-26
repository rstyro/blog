---
title: 吃透Redis不用愁！String到Stream全类型实战命令手册
tags: [Redis]
categories: 开发工具
date: 2026-02-26 10:55:57
---

## 前言

Redis 作为一款高性能的内存数据库，凭借其高效、灵活的特性，已成为当下绝大多数项目的核心依赖，广泛应用于缓存、计数、消息队列、地理位置查询等各类场景。

本文整理了 Redis 最常用的 9 种数据类型，**每个类型都配实战指令 + 真实业务场景**，既是入门教程，也是日常开发的速查手册，看完就能直接上手！

<!--more-->


## 一、String（字符串）

Redis 最基础、最常用的数据类型，可存储字符串、数字（整数/浮点数）、二进制数据（如图片、序列化对象），最大存储容量为 512MB。核心优势是操作高效，常用于缓存、计数器、分布式锁等场景。

```bash
# 1. 设置值（基础）
SET name "zhangsan"          # 设置键name的值为zhangsan（默认永久有效）
SET age 20 EX 3600           # 设置键age的值为20，过期时间1小时（EX：秒）
SETNX email "test@xxx.com"   # 仅当email不存在时设置（避免覆盖，分布式锁常用）
MSET addr "guangxi" phone "18818868688"  # 批量设置多个键值对

# 2. 获取值
GET name                     # 获取name的值
MGET name age addr           # 批量获取多个键的值
GETRANGE name 0 2            # 获取name值的子串（索引0到2，包含2）

# 3. 修改/更新
APPEND name "_test"          # 给name的值追加字符串，结果变为zhangsan_test
INCR age                     # 数字值自增1（age变为21）
INCRBY age 5                 # 数字值自增指定数（age变为26）
DECR age                     # 数字值自减1（age变为25）
DECRBY age 3                 # 数字值自减指定数（age变为22）

# 4. 删除/过期
DEL name                     # 删除指定键
EXPIRE age 60                # 设置age的过期时间为60秒
TTL age                      # 查看键的剩余过期时间（-1：永久，-2：已过期）
PERSIST age                  # 移除age的过期时间，变为永久有效
```



## 二、Hash（哈希）

用于存储结构化数据（键值对集合），可理解为“字典中的字典”，适合存储用户信息、商品详情等对象类数据。相比 String 存储整个对象（需序列化），Hash 可单独操作对象的某个字段，更灵活、更节省内存。

```bash
# 1. 设置字段
HSET user:1 name "lisi" age 25 gender "男"  # 给哈希键user:1设置多个字段
HSETNX user:1 email "lisi@xxx.com"            # 仅当email字段不存在时设置

# 2. 获取字段
HGET user:1 name              # 获取user:1的name字段值
HMGET user:1 name age         # 批量获取多个字段值
HGETALL user:1                # 获取该哈希的所有字段和值（返回[key,val,key,val...]）
HKEYS user:1                  # 获取该哈希的所有字段名
HVALS user:1                  # 获取该哈希的所有字段值
HLEN user:1                   # 获取该哈希的字段数量

# 3. 修改/更新
HINCRBY user:1 age 2          # 给age字段值自增2（变为27）

# 4. 删除
HDEL user:1 gender            # 删除user:1的gender字段
DEL user:1                    # 删除整个哈希键
```

## 三、List（列表）

有序的字符串集合（按插入顺序排序），支持从两端（头部/尾部）添加、删除元素，底层基于双向链表实现，插入/删除效率高，查询效率较低。常用于实现队列、栈、最新消息列表、消息缓冲区等场景。

```bash
# 1. 添加元素
LPUSH list1 "a" "b" "c"       # 从列表左侧（头部）添加元素，结果：c b a
RPUSH list1 "d" "e"           # 从列表右侧（尾部）添加元素，结果：c b a d e
LPUSHX list1 "f"              # 仅当list1存在时，从左侧添加元素（结果：f c b a d e）
RPUSHX list1 "g"              # 仅当list1存在时，从右侧添加元素（结果：f c b a d e g）

# 2. 查询/遍历
LRANGE list1 0 -1             # 获取列表所有元素（0：第一个，-1：最后一个）
LRANGE list1 1 3              # 获取索引1到3的元素（c b a）
LLEN list1                    # 获取列表长度
LINDEX list1 2                # 获取索引为2的元素（b）

# 3. 删除元素
LPOP list1                    # 从左侧弹出并返回第一个元素（f）
RPOP list1                    # 从右侧弹出并返回最后一个元素（g）
LTRIM list1 1 3               # 修剪列表，仅保留索引1到3的元素（b a d）
DEL list1                     # 删除整个列表

# 4. 阻塞操作（队列常用）
BLPOP list2 10                # 阻塞式左弹出，list2为空时等待10秒，超时返回nil
BRPOP list2 10                # 阻塞式右弹出
```

## 四、Set（集合）

无序的字符串集合，核心特性是**元素唯一**（自动去重），支持交集、并集、差集等集合运算，底层基于哈希表实现，添加、删除、查询效率极高。常用于标签管理、好友关注、抽奖、去重统计等场景

```bash
# 1. 添加元素
SADD set1 "apple" "banana" "orange"  # 向集合添加元素（自动去重）
SADD set1 "apple"                    # 重复添加无效果，集合仍只有3个元素

# 2. 查询/遍历
SMEMBERS set1                  # 获取集合所有元素
SCARD set1                     # 获取集合元素数量
SISMEMBER set1 "banana"        # 判断元素是否在集合中（返回1：存在，0：不存在）
SRANDMEMBER set1               # 随机获取1个元素
SRANDMEMBER set1 2             # 随机获取2个元素（不删除）

# 3. 删除元素
SREM set1 "orange"             # 删除指定元素
SPOP set1                      # 随机删除并返回1个元素
DEL set1                       # 删除整个集合

# 4. 集合运算（核心特性）
SADD set2 "banana" "grape" "pear"
SUNION set1 set2               # 并集：apple banana grape pear
SINTER set1 set2               # 交集：banana
SDIFF set1 set2                # 差集（set1有、set2无）：apple
```





## 五、Sorted Set （zset，有序集合）

Set 的升级版本，元素唯一且**按分数（score）排序**，底层结合了哈希表和跳表，兼顾了查询、插入效率，支持按排名、分数范围查询。常用于排行榜、优先级队列、带权重的消息排序等场景。

```bash
# 1. 添加数据（基础操作）
# 格式：ZADD key score member [score member ...]
ZADD player_scores 100 "zhangsan" 95 "lisi" 98 "wangwu" 90 "zhaoliu" 88 "sunqi" 80 "zhouba" 
ZADD player_scores 60 "wujiu"  # 补充添加单个元素（分数60，成员wujiu）

# 2. 过期设置（zset无专属过期指令，给整个键设置过期）
EXPIRE player_scores 3600     # 方式1：相对时间（3600秒=1小时后过期）
PEXPIREAT player_scores 1770266046000  # 方式2：绝对时间（毫秒时间戳，指定时间点过期）

# 3. 过期时间验证
TTL player_scores              # 查看剩余过期时间（单位：秒），-1=永不过期，-2=已过期/不存在
PTTL player_scores             # 查看剩余过期时间（单位：毫秒）

# 4. 分数操作（核心）
ZSCORE player_scores "wangwu"  # 获取单个成员的分数（返回98）
ZINCRBY player_scores 10 "wangwu"  # 分数自增：给wangwu的分数加10（从98变为108）

# 5. 按排名查询（升序/降序）
ZRANGE player_scores 0 2       # 升序排名：查询排名前3的成员（分数从低到高，0=第一名）
ZRANGE player_scores 0 2 WITHSCORES  # 升序排名+分数：同时返回成员和对应分数
ZRANGE player_scores 0 -1 WITHSCORES  # 升序查询所有成员及分数
ZRANK player_scores "zhaoliu"  # 升序排名查询：返回zhaoliu的排名（索引从0开始，分数90对应排名3）
ZREVRANK player_scores "zhaoliu"  # 降序排名查询：返回zhaoliu的排名（分数90对应降序排名4）
ZREVRANGE player_scores 0 2 WITHSCORES  # 降序排名前3：分数从高到低，查询前3名及分数

# 6. 按分数区间查询（精准筛选）
ZRANGEBYSCORE player_scores 85 100 WITHSCORES  # 升序查询85-100分的成员（含边界）
ZRANGEBYSCORE player_scores -inf 100 WITHSCORES  # 升序查询≤100分的成员（-inf表示负无穷）
ZRANGEBYSCORE player_scores (90 100 WITHSCORES  # 升序查询>90且≤100分的成员（( 表示开区间）
ZREVRANGEBYSCORE player_scores 110 90 WITHSCORES  # 降序查询90-110分的成员

# 7. 弹出元素（移除并返回）
ZPOPMIN player_scores          # 弹出分数最小的1个成员（可指定数量，如ZPOPMIN key 3弹出3个）
ZPOPMAX player_scores          # 弹出分数最大的1个成员
BZPOPMIN player_scores 5       # 阻塞式弹出最小成员：无元素时阻塞5秒，超时返回nil
BZPOPMAX player_scores 10      # 阻塞式弹出最大成员：阻塞10秒，适用于异步消费场景

# 8. 删除操作
ZREM player_scores "lisi"      # 删除单个成员
ZREM player_scores "lisi" "wangwu"  # 批量删除多个成员
ZREMRANGEBYSCORE player_scores 0 50  # 按分数区间删除：删除0-50分的所有成员
ZREMRANGEBYRANK player_scores 0 2  # 按排名区间删除：删除升序排名前3（最低3名）的成员

# 9. 统计操作
ZCOUNT player_scores 90 110    # 统计分数区间人数：查询90-110分的成员数量
ZCARD player_scores            # 统计总成员数：返回集合的成员总数

# 10. 多集合聚合运算（进阶）
ZADD player_scores_2 95 "zhangsan" 92 "lisi" 98 "zhaoliu"  # 创建第二个集合
ZUNIONSTORE union_scores 2 player_scores player_scores_2 AGGREGATE SUM  # 并集合并：2个集合并集，分数求和，结果存入union_scores
ZRANGE union_scores 0 -1 WITHSCORES  # 查看并集结果
ZINTERSTORE inter_scores 2 player_scores player_scores_2 AGGREGATE MAX  # 交集计算：2个集合交集，分数取最大值，结果存入inter_scores
ZRANGE inter_scores 0 -1 WITHSCORES  # 查看交集结果

# 11. 字典序查询（分数相同时适用）
ZADD dict_zset 0 "apple" 0 "banana" 0 "cherry" 0 "date"  # 创建分数全为0的集合
ZLEXCOUNT dict_zset [b (d  # 统计字典序区间成员数：[b (d 表示b≤成员<d，返回2（banana、cherry）
ZRANGEBYLEX dict_zset [b [c  # 按字典序查询：查询[b,c]区间的成员（banana、cherry）

# 12. 大数据量遍历（进阶，百万级集合适用）
ZSCAN player_scores 0 MATCH "z*" COUNT 5  # 游标式遍历：匹配以z开头的成员，每次返回5个，避免一次性加载过多数据

# 13. 批量操作（Redis 6.2+ 新增）
ZMSCORE player_scores "zhangsan" "lisi" "zhaoliu"  # 批量获取多个成员的分数，减少网络往返
```

## 六、Bitmap（位图）

本质是 String 类型的扩展，以“位（bit）”为最小存储单位（每个位仅存储 0 或 1），极致节省内存（1KB 可存储 8192 个状态）。核心用于二值化统计场景，如用户签到、活跃用户标记、在线状态、连续天数统计等。

```bash
# 1. 设置位值（核心操作，SETBIT key offset value）
# offset：位偏移（从0开始，对应第N天/第N个状态），value：0（未触发）或1（已触发）
SETBIT sign:user1 0 1    # 用户1 第0天（对应1号）签到（置1）
SETBIT sign:user1 1 0    # 用户1 第1天（对应2号）未签到（置0）
SETBIT sign:user1 2 1    # 用户1 第2天（对应3号）签到（置1）

# 2. 获取位值（核心操作）
GETBIT sign:user1 0      # 获取用户1 第0天的签到状态（返回1，已签到）
GETBIT sign:user1 1      # 获取用户1 第1天的签到状态（返回0，未签到）

# 3. 统计与位运算（实战核心）
BITCOUNT sign:user1      # 统计置1位数：用户1 累计签到天数（返回2）
BITCOUNT sign:user1 0 0  # 指定字节统计：仅统计第0个字节（8位）内的置1位数

# 多用户位运算（合并/对比）
SETBIT sign:user2 0 1    # 用户2 第0天签到
SETBIT sign:user2 2 0    # 用户2 第2天未签到

BITOP AND sign:both sign:user1 sign:user2  # 与运算：统计两人都签到的天数（结果存sign:both）
BITCOUNT sign:both       # 查看结果：返回1（仅第0天两人都签到）

# 4. 其他辅助操作
BITPOS sign:user1 1      # 查找第一个置1的位偏移（返回0，即第0天首次签到）
GET sign:user1           # 查看底层存储：直接获取位图对应的字符串（底层以String存储）
```

## 七、HyperLogLog

专门用于**基数估算**（统计集合中不重复元素的数量），无需存储具体元素，仅占用固定 12KB 内存，误差率约 0.81%。适合大数据量去重统计场景，如日活（DAU）、访客数（UV）、页面访问去重等，无需精准统计时优先使用。

```bash
# ==================== 基础操作 ====================
# 1. 空键统计（返回0，而非nil）
PFCOUNT uv:empty_key  # 返回 0

# 2. 批量添加重复元素（验证去重特性）
PFADD uv:20260225 "user1" "user2" "user3" "user1" "user2"  # 重复元素不影响基数
PFCOUNT uv:20260225                                        # 返回 3

# ==================== 进阶操作 ====================
# 1. 多键合并+统计（跨天UV合并）
PFADD uv:20260225 "user1" "user2" "user3"  # 25号UV：3
PFADD uv:20260226 "user3" "user4" "user5"  # 26号UV：3
PFMERGE uv:20260225_26 uv:20260225 uv:20260226  # 合并两天数据
PFCOUNT uv:20260225_26                        # 返回 5（去重后总数）

# 2. 合并多个HyperLogLog（支持超过2个源键）
PFADD uv:20260227 "user5" "user6" "user7"
PFMERGE uv:20260225_27 uv:20260225 uv:20260226 uv:20260227
PFCOUNT uv:20260225_27                        # 返回 7

# 3. 验证内存占用（核心优势：固定12KB）
# 无论添加多少元素，HyperLogLog 键仅占约12KB内存
MEMORY USAGE uv:20260225  # 输出约 12288 字节（12KB），与元素数量无关

# ==================== 实战场景：统计页面UV ====================
# 模拟用户访问页面（重复访问只算1次）
PFADD page:index:uv:20260225 "user100" "user101" "user100" "user102" "user101"
# 统计页面UV
PFCOUNT page:index:uv:20260225  # 返回 3
# 清空统计（无专属清空命令，直接删除）
DEL page:index:uv:20260225
```
## 八、GEO（地理位置）

用于存储地理位置信息（经纬度），底层基于 Sorted Set 实现，支持距离计算、范围查询、地理位置编码等操作。专为 LBS（基于位置的服务）设计，适合附近的人、门店定位、配送范围查询等场景。

```bash
# 1. 添加地理位置（GEOADD key longitude latitude member...）
GEOADD shop:coffee 116.403874 39.914885 "starbucks1"  # 北京星巴克1（经纬度）
GEOADD shop:coffee 116.410082 39.915072 "starbucks2"  # 北京星巴克2
GEOADD shop:coffee 116.390604 39.906217 "luckin1"     # 北京瑞幸1

# 也可以添加多个
GEOADD shop:coffee 121.473701 31.230416 "starbucks3" 113.264434 23.129110 "starbucks4"  


# 2. 获取经纬度（GEOPOS key member...）
GEOPOS shop:coffee "starbucks1"  # 返回["116.40387344360351562", "39.91488456937919781"]

# 3. 计算两点距离（GEODIST key member1 member2 [unit]）
# unit：m(米，默认)/km(千米)/mi(英里)/ft(英尺)
GEODIST shop:coffee "starbucks1" "starbucks2" km  # 返回约0.53km

# 4. 范围查询（核心）
# 格式：GEOSEARCH 键名 [查询起点] [查询范围] [排序] [数量限制] [附加信息]
# GEOSEARCH key [FROMMEMBER member/FROMLONLAT lon lat] [BYRADIUS distance unit/BYBOX width height unit] [ASC/DESC] [COUNT count]
# 示例：查找starbucks1周围1km内的咖啡店，最多返回2个，按距离升序
GEOSEARCH shop:coffee FROMMEMBER starbucks1 BYRADIUS 1 km ASC COUNT 2

# 场景：用户当前位置（116.405285, 39.906217），查找1公里内的餐饮门店
# 格式：GEOSEARCH key FROMLONLAT 经度 纬度 BYRADIUS 距离 单位 [ASC/DESC] [COUNT 数量] [WITHDIST] [WITHCOORD]
# [WITHDIST]=附带距离（单位：km）、[WITHCOORD]=附带经纬度
GEOSEARCH shop:coffee FROMLONLAT  116.405285 39.906217 BYRADIUS 1 km ASC COUNT 2 WITHDIST WITHCOORD

# 矩形范围查询
# 场景：查询经度 116.3~116.5、纬度 39.8~39.95 范围内的门店
# 矩形宽0.5km、高0.5km（单位：km）
GEOSEARCH shop:coffee FROMLONLAT 116.4 39.906217  BYBOX 0.5 0.5 km ASC WITHCOORD

# 兼容旧版的范围查询（GEOSEARCH是Redis 6.2+，旧版用GEORADIUS）
GEORADIUS shop:coffee 116.403874 39.914885 1 km ASC COUNT 2

# 5. 获取地理位置的哈希值（GEOHASH）
GEOHASH shop:coffee "starbucks1"  # 返回地理位置的geohash编码

# 6. 删除（无专属删除命令，GEO底层是zset，用ZREM）
ZREM shop:coffee "luckin1"
```
## 九、Stream（流）

Redis 5.0+ 引入的日志型数据类型，支持持久化、消息分区、消费确认、消费组等特性，是 Redis 官方推荐的消息队列实现方式，比 List 更强大、更稳定，适合订单通知、日志收集、异步任务调度等场景。

```bash
# 1. 添加消息（核心操作，XADD）
# 格式：XADD 键名 [MAXLEN [~] 数量] *|消息ID 字段 值...
# MAXLEN ~ 数量：近似截断，保留最新N条消息（提升性能）；*：自动生成消息ID（时间戳-序列号）
XADD order:log MAXLEN ~ 1000 * user_id 1001 order_id "O20260225001" status "paid"  # 订单支付日志
XADD order:log * user_id 1002 order_id "O20260225002" status "shipped"             # 订单发货日志

# 2. 查询消息（三种方式，按需使用）
# XRANGE：按消息ID范围查询（-=最小ID，+=最大ID）
XRANGE order:log - +                          # 查询所有消息
XRANGE order:log - + COUNT 1                 # 只查询1条消息
XRANGE order:log 1772071300000-0 1773071300000-0  # 按时间戳范围查询（指定时间段内的消息）

# XREVRANGE：反向查询（从最新消息到最旧消息）
XREVRANGE order:log + - COUNT 1              # 查询最新的1条消息

# XREAD：阻塞读取（消费消息，核心）
XREAD BLOCK 0 COUNT 2 STREAMS order:log 0    # 永久阻塞，每次读2条，从第一条消息开始（ID=0）
# 后续消费（仅读新消息）：用上次最后一条消息的ID，如1772071324605-0
XREAD BLOCK 0 STREAMS order:log 1772071324605-0

# 3. 消费组（核心特性，实现多消费者负载均衡）
# 创建消费组（XGROUP CREATE 键名 消费组名 消息ID [MKSTREAM]）
# MKSTREAM：流不存在时自动创建；$：从最新消息开始消费（不消费历史消息）
XGROUP CREATE order:log group1 $ MKSTREAM

# 消费组内读取消息（XREADGROUP）
# GROUP group1 consumer1：指定消费组group1和消费者consumer1；>：只读未被该组消费过的消息
XREADGROUP GROUP group1 consumer1 BLOCK 0 COUNT 2 STREAMS order:log >

# 确认消息已处理（XACK）：避免消息重复消费，必须手动确认
XACK order:log group1 1772071567770-0 1772071331010-0 1772071324605-0  # 确认指定ID的消息已处理

# 4. 查看流/消费组信息
XLEN order:log                                # 查看流中消息总数
XINFO STREAM order:log                        # 查看流详细信息（长度、首尾消息ID、消费组等）
XINFO GROUPS order:log                        # 查看该流的所有消费组信息

# 5. 删除操作
XDEL order:log 1740460800000-0                # 删除指定ID的消息（仅删除消息，不影响流结构）
DEL order:log                                 # 删除整个流（连带所有消费组、消息一起删除）
```



![redis-流数据类型命令示例](redis-stream.png)

## 十、最后

根据使用频率和复杂度，我们可以把 Redis 的数据类型分为三个梯队：

- **第一梯队 (基石型)**：`String`, `Hash`, `List`, `Set`, `Sorted Set`。**这是必须熟练掌握的5种**，解决了80%的常规需求。
- **第二梯队 (特种兵型)**：`Bitmap`, `HyperLogLog`, `GEO`。为特定场景（统计、地理）而生，用对地方有奇效。
- **第三梯队 (专家型)**：`Stream`。Redis 官方认证的消息队列方案，适合复杂的流处理场景。



![所有命令执行后的数据结构](redis-view.png)

本文所有指令均经过实战验证，可直接复制到Redis客户端执行，方便快速上手落地。

Redis的核心优势在于“按需选型、高效复用”，实际开发中，需结合业务场景的存储需求、查询频率、数据量大小，选择最合适的数据类型，才能充分发挥Redis的高性能优势，同时避免资源浪费。



**建议将本文收藏作为速查手册，用到的时候翻出来，效率提升肉眼可见！** 滑稽.jpg

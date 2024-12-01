---
title: Elasticsearch7 cat API详解
date: 2020-09-24 10:25:29
updated: 2020-09-24 10:25:29
tags: [ElasticSearch]
categories: 搜索引擎
---
### 一、cat API 简介
ES 大部分API返回值都是`JSON`对象，格式化展示确实是挺整齐的。但是如果数据量多的话，不方便管理员查看。
而`cat API` 像是专为管理员设计的，因为它是以表格的形式返回的。如果你用的是`curl`命令请求还可以使用 Linux 的命令用法，比如： `grep`、`help`、`awk` 之类的结果集筛选。

<!--more-->

通过 `GET` 请求发送 `cat` 命名可以列出所有可用的 API：
```yml
# 展示所有可用的cat api
GET http://172.16.1.236:9201/_cat

=^.^=
/_cat/allocation
/_cat/shards
/_cat/shards/{index}
/_cat/master
/_cat/nodes
/_cat/tasks
/_cat/indices
/_cat/indices/{index}
/_cat/segments
/_cat/segments/{index}
/_cat/count
/_cat/count/{index}
/_cat/recovery
/_cat/recovery/{index}
/_cat/health
/_cat/pending_tasks
/_cat/aliases
/_cat/aliases/{alias}
/_cat/thread_pool
/_cat/thread_pool/{thread_pools}
/_cat/plugins
/_cat/fielddata
/_cat/fielddata/{fields}
/_cat/nodeattrs
/_cat/repositories
/_cat/snapshots/{repository}
/_cat/templates
/_cat/ml/anomaly_detectors
/_cat/ml/anomaly_detectors/{job_id}
/_cat/ml/trained_models
/_cat/ml/trained_models/{model_id}
/_cat/ml/datafeeds
/_cat/ml/datafeeds/{datafeed_id}
/_cat/ml/data_frame/analytics
/_cat/ml/data_frame/analytics/{id}
/_cat/transforms
/_cat/transforms/{transform_id}
```

### 二、cat API公共参数
cat api 的通用参数：
#### 1、Verbose 
这个参数主要作用就是返回的时候把表头也返回了。但是请求传参不是这个而是它简称的小写`v`。如：
```
# 查询集群健康状态
GET http://172.16.1.236:9201/_cat/health?v

epoch      timestamp cluster  status node.total node.data shards pri relo init unassign pending_tasks max_task_wait_time active_shards_percent
1600829883 02:58:03  mtSearch green           3         3     57  27    0    0        0             0                  -                100.0%
```

#### 2、Headers
通过`v`参数显示表头，而通过这个参数`h`只显示特定的列，例如：
```
GET http://172.16.1.236:9201/_cat/health?v&h=cluster,epoch,status,shards

cluster  epoch      status shards
mtSearch 1600830942 green      57
```
只显示了我`h`后面指定的列

#### 3、Help
见名知意，请求api查看帮助，例如：
```
GET http://172.16.1.236:9201/_cat/health?help

epoch                 | t,time                                   | seconds since 1970-01-01 00:00:00  
timestamp             | ts,hms,hhmmss                            | time in HH:MM:SS                   
cluster               | cl                                       | cluster name                       
status                | st                                       | health status                      
node.total            | nt,nodeTotal                             | total number of nodes              
node.data             | nd,nodeData                              | number of nodes that can store data
shards                | t,sh,shards.total,shardsTotal            | total number of shards             
pri                   | p,shards.primary,shardsPrimary           | number of primary shards           
relo                  | r,shards.relocating,shardsRelocating     | number of relocating nodes         
init                  | i,shards.initializing,shardsInitializing | number of initializing nodes       
unassign              | u,shards.unassigned,shardsUnassigned     | number of unassigned shards        
pending_tasks         | pt,pendingTasks                          | number of pending tasks            
max_task_wait_time    | mtwt,maxTaskWaitTime                     | wait time of longest task pending  
active_shards_percent | asp,activeShardsPercent                  | active number of shards in percent 

```
第一列显示完整的名称，第二列显示缩写，第三列提供了关于这个参数的简介。

#### 4、Sort
见名知意，对返回结果进行排序，传`s`参数，格式：`s=字段:desc(或 asc)` 多个用逗号隔开。
```
GET http://172.16.1.236:9201/_cat/templates?v&s=order:desc,index_patterns:asc

name                            index_patterns               order      version composed_of
.slm-history                    [.slm-history-2*]            2147483647 2       
.triggered_watches              [.triggered_watches*]        2147483647 11      
.watch-history-11               [.watcher-history-11*]       2147483647 11      
.watches                        [.watches*]                  2147483647 11      
ilm-history                     [ilm-history-2*]             2147483647 2       
my_template                     [index*, topic*]             201                [setting_template, dynamic_template]
test_template                   [test*, topic*]              200                []
logs                            [logs-*-*]                   100        0       [logs-mappings, logs-settings]
metrics                         [metrics-*-*]                100        0       [metrics-mappings, metrics-settings]
test_template                   [test*, topic*]              1                  
.logstash-management            [.logstash]                  0                  
.ml-anomalies-                  [.ml-anomalies-*]            0          7090099 
.ml-config                      [.ml-config]                 0          7090099 
.ml-inference-000002            [.ml-inference-000002]       0          7090099 
.ml-meta                        [.ml-meta]                   0          7090099 
.ml-notifications-000001        [.ml-notifications-000001]   0          7090099 
.ml-state                       [.ml-state*]                 0          7090099 
.ml-stats                       [.ml-stats-*]                0          7090099 
.monitoring-alerts-7            [.monitoring-alerts-7]       0          7000199 
.monitoring-beats               [.monitoring-beats-7-*]      0          7000199 
.monitoring-es                  [.monitoring-es-7-*]         0          7000199 
.monitoring-kibana              [.monitoring-kibana-7-*]     0          7000199 
.monitoring-logstash            [.monitoring-logstash-7-*]   0          7000199 
.transform-internal-005         [.transform-internal-005]    0          7090099 
.transform-notifications-000002 [.transform-notifications-*] 0          7090099 
```

#### 5、Numeric formats
ES支持参数对一些数字类型的返回值进行转换更改，有：字节，大小或时间值，对应的请求参数分别为：`bytes`、`size`、`time`
+ bytes单位有：`b`、`kb`、`mb`、`gb`、`tb`、`pb`。
+ size单位有：`k`、`m`、`g`、`t`、`p`。
+ time单位有：`d`、`h`、`m`、`s`、`ms`、`micros`、`nanos`。


> 可参考文档：[common-options.html#size-units](https://www.elastic.co/guide/en/elasticsearch/reference/7.9/common-options.html#size-units)

简单例子：
```yml
# 返回值有字节类型的，以 b 为单位返回
GET http://172.16.1.236:9201/_cat/indices?v&s=store.size:desc&bytes=b

health status index       uuid                   pri rep docs.count docs.deleted store.size pri.store.size
green  open   topic       ZHfmduvvSDu014SIF9IC9A   3   2          3            0      60633          20211
green  open   .security-7 HjqN4EO1Qq2JQLGg8fLwzQ   1   1          7            0      52266          26133
green  open   test-000002 G8zQeW3_Qrmk3QAEhM2sZQ   1   1          4            0      35536          17768
green  open   test-001    R7-IIFffRjSDwBmOws09kQ   5   1          3            0      29166          14583
green  open   test-000003 0FMWo1FTTpSBqLixYNcNGg   5   1          1            0      15202           7601
```
cat api除了支持table格式的`text`文本返回，也支持json等其他格式返回，总共有：`text`（默认）、`json`、`smile`、`yaml`、`cbor`。

```
GET http://172.16.1.236:9201/_cat/indices?v&s=store.size:desc&bytes=b&format=json&pretty

[
    {
        "health": "green",
        "status": "open",
        "index": "topic",
        "uuid": "ZHfmduvvSDu014SIF9IC9A",
        "pri": "3",
        "rep": "2",
        "docs.count": "3",
        "docs.deleted": "0",
        "store.size": "60633",
        "pri.store.size": "20211"
    },
    {
        "health": "green",
        "status": "open",
        "index": ".security-7",
        "uuid": "HjqN4EO1Qq2JQLGg8fLwzQ",
        "pri": "1",
        "rep": "1",
        "docs.count": "7",
        "docs.deleted": "0",
        "store.size": "52266",
        "pri.store.size": "26133"
    },
    {
        "health": "green",
        "status": "open",
        "index": "test-000002",
        "uuid": "G8zQeW3_Qrmk3QAEhM2sZQ",
        "pri": "1",
        "rep": "1",
        "docs.count": "4",
        "docs.deleted": "0",
        "store.size": "35536",
        "pri.store.size": "17768"
    },
    {
        "health": "green",
        "status": "open",
        "index": "test-001",
        "uuid": "R7-IIFffRjSDwBmOws09kQ",
        "pri": "5",
        "rep": "1",
        "docs.count": "3",
        "docs.deleted": "0",
        "store.size": "29166",
        "pri.store.size": "14583"
    },
    {
        "health": "green",
        "status": "open",
        "index": "test-000003",
        "uuid": "0FMWo1FTTpSBqLixYNcNGg",
        "pri": "5",
        "rep": "1",
        "docs.count": "1",
        "docs.deleted": "0",
        "store.size": "15202",
        "pri.store.size": "7601"
    }
]
```
老实说如果是分析数据的话，个人感觉还是text好用，json 太长了。

### 三、cat API详解
把各个cat api 说个遍，**Tip: 以下的所有API 都可以用上面的参数**

#### 1、aliases
返回集群下的所有别名信息，请求格式如下：
```yml
# 获取一个或多个别名的信息，<alias> 是一个别名数组，多个别名用逗号隔开
GET /_cat/aliases/<alias>

# 获取所有别名
GET /_cat/aliases

# 例如：获取指定多个别名的信息，你指定别名不存在也不会报错
GET http://172.16.1.236:9201/_cat/aliases/test,.security,topic?v

alias     index       filter routing.index routing.search is_write_index
test      test-000002 -      -             -              false
.security .security-7 -      -             -              -
test      test-001    -      -             -              false
test      test-000003 -      -             -              true
```

#### 2、allocation
查看数据节点的分片情况与硬盘占用情况，格式：
```yml
# 获取一个或多个数据节点信息，<node_id>是一个节点ID数组（或者节点名称数组），多个用逗号隔开。
GET /_cat/allocation/<node_id>

# 获取所有数据节点
GET /_cat/allocation

#获取指定多个节点的信息，你指定节点不存在也不会报错
GET http://172.16.1.236:9201/_cat/allocation/mtNode1,mtNode2,mtNode3?v
```

#### 3、anomaly_detectors
查看 anomaly_detectors jobs 的api,先决条件是如果启动了安全功能必须拥有 `monitor_ml`, `monitor`, `manage_ml` 或 `manage`集群权限才能使用这个api。
格式：理解上面的格式，后面基本上都同一个规律。不写注释了
```
GET /_cat/ml/anomaly_detectors/<job_id>

GET /_cat/ml/anomaly_detectors
```

#### 4、count
返回集群下的所有索引的文档个数，格式：
```yml
# 这里和上面的区别就是，<target> 可以写具体的索引之外，也支持写 _all或*
GET /_cat/count/<target>


GET /_cat/count
```

#### 5、data_frame analytics
返回data frame analytics 的配置任务信息，没用过,如果启动了安全功能，需要 `monitor_ml` 权限.格式:
```
GET /_cat/ml/data_frame/analytics/<data_frame_analytics_id>

GET /_cat/ml/data_frame/analytics
```

#### 6、datafeeds
返回datafeeds的配置信息，格式：
```
GET /_cat/ml/datafeeds/<feed_id>

GET /_cat/ml/datafeeds
```
如果启动了安全功能必须拥有 `monitor_ml`, `monitor`, `manage_ml` 或 `manage`集群权限才能使用

#### 7、fielddata
查看每个数据节点上字段属性包含fielddata的当前占用的堆内存。text类型的字段是不能分组及排序的。
ES中引入了fielddata的数据结构用来做正排索引。如果需要对某一个字段排序、分组聚合、过滤，则可将字段设置成fielddata。
格式：
```
GET /_cat/fielddata/<field>

GET /_cat/fielddata
```

#### 8、health
返回集群的运行状况
```
GET /_cat/health?v&ts=false
```

#### 9、indices
返回集群的索引信息，包含分片计数、文档数量、删除文档数、状态、存储等
```yml
# 这里和上面的区别就是，<target> 可以写具体的索引之外，也支持写 _all或*(通配符)
GET /_cat/indices/<target>

GET /_cat/indices

# 筛选节点状态：green、yellow、red
GET http://172.16.1.236:9201/_cat/indices?v&health=green
```

#### 10、master
返回master节点的信息，包括ID，绑定的IP地址和名称
```
GET /_cat/master?v
```
#### 11、nodeattrs
返回自定义节点属性
```
GET /_cat/nodeattrs?v

node    host         ip           attr              value
mtNode1 172.16.1.236 172.16.1.236 ml.machine_memory 16825085952
mtNode1 172.16.1.236 172.16.1.236 ml.max_open_jobs  20
mtNode1 172.16.1.236 172.16.1.236 xpack.installed   true
mtNode1 172.16.1.236 172.16.1.236 transform.node    true
mtNode3 172.16.1.236 172.16.1.236 ml.machine_memory 16825085952
mtNode3 172.16.1.236 172.16.1.236 ml.max_open_jobs  20
mtNode3 172.16.1.236 172.16.1.236 xpack.installed   true
mtNode3 172.16.1.236 172.16.1.236 transform.node    true
mtNode2 172.16.1.236 172.16.1.236 ml.machine_memory 16825085952
mtNode2 172.16.1.236 172.16.1.236 ml.max_open_jobs  20
mtNode2 172.16.1.236 172.16.1.236 xpack.installed   true
mtNode2 172.16.1.236 172.16.1.236 transform.node    true
```
#### 12、nodes
返回集群节点信息
```
GET /_cat/nodes?v

# 返回的字段不明白可以使用help参数
# heap.percent 最大配置堆，ram.percent 内存占用百分比
# load_1m 最近平均负载，load_5m 5分钟平均负载
ip           heap.percent ram.percent cpu load_1m load_5m load_15m node.role master name
172.16.1.236           20          77   0    0.02    0.04     0.05 dilmrt    -      mtNode1
172.16.1.236           70          77   0    0.02    0.04     0.05 dilmrt    -      mtNode3
172.16.1.236           38          77   0    0.02    0.04     0.05 dilmrt    *      mtNode2
```
默认只返回上面几个列信息，其他的需要自己通过h参数指定，如下：

|参数|参数简写|描述|
|--|--|--|
|ip<div style="width:100px;"></div>|i|IP地址|
|heap.percent|hp|最大配置堆|
|ram.percent|rp|已使用的总内存百分比|
|file_desc.percent|fdp|使用的文件描述符百分比|
|node.role|r|节点的角色。返回的值包括d（数据节点），i （目标节点），m（主资格节点），l（机器学习节点），v （仅投票节点），t（转换节点），r（远程集群客户端节点）和-（仅协调节点） ）|
|master|m|指示该节点是否为当选的主节点。返回的值包括*（当选的主服务器）和-（当选的主服务器）|
|name|n|节点名称|
|id|id|节点的ID|
|pid|p|进程ID|
|port|po|绑定的运输港口，例如9300|
|http_address|http|绑定的http地址，例如127.0.0.1:9200|
|version|v|Elasticsearch版本，|
|build|b|Elasticsearch构建哈希|
|jdk|j|Java版本，例如1.8.0。|
|disk.total|dt|总磁盘空间|
|disk.used|du|已使用的磁盘空间|
|disk.avail|d|可用磁盘空间|
|heap.current|hc|已用堆|
|ram.current|rc|已用的总内存|
|ram.max|rm|总内存|
|cpu|cpu|最近的系统CPU使用率|
|load_1m|l|最近的平均负载|
|load_15m|l|最近15分钟的平均负载|
|uptime|u|节点正常运行时间|
|refresh.total|rto|刷新次数|

还有很多参数，就不一一写了。

#### 13、pending tasks
查看被挂起的任务
```
GET /_cat/pending_tasks
```
#### 14、plugins
查看每个节点正在运行的插件
```
GET /_cat/plugins

GET http://172.16.1.236:9201/_cat/plugins?v&h=id,name,component,version,description
```

#### 15、recovery
索引分片的恢复视图,包括正在进行和先前已完成的恢复,只要索引分片移动到群集中的其他节点，就会发生恢复事件
```
GET /_cat/recovery/<target>

GET /_cat/recovery
```
可以添加参数`active_only=true`仅响应正在进行的分片恢复

#### 16、repositories
返回集群的快照仓库
```
GET /_cat/repositories
```

#### 17、shards
返回索引的分片情况，格式：
```
# <target> 可以写具体的索引之外，也支持写 _all或*(通配符)，多个索引逗号隔开
GET /_cat/shards/<target>

GET /_cat/shards
```

默认只返回了几个列信息，还有很多列信息

|参数|参数简写|描述|
|--|--|--|
|index <div style="width:180px;"></div>|i<div style="width:70px;"></div>|索引名称|
|shard|s|分片的名称|
|prirep|p|分片类型。返回的值是primary或replica|
|state|st|分片的状态。返回值是：<br/>`INITIALIZING：分片正在从对等分片或网关中恢复。`<br/> `RELOCATING：分片正在重定位。` <br/>`STARTED：分片已开始。`<br/> `UNASSIGNED：分片未分配给任何节点`|
|docs|d|分片中的文档数|
|store|sto|分片使用的磁盘空间|
|ip|ip|节点的IP地址，|
|id|id|节点的ID|
|node|n|节点名称|
|completion.size|cs|完成大小|
|indexing.index_total|iito|索引操作的数量|
|indexing.index_failed|iif|索引操作失败的次数|
|merges.current|mc|当前合并操作的数量|
|merges.current_docs|mcd|当前合并文档的数量|
|merges.total|mt|完成的合并操作的数量|
|merges.total_docs|mtd|合并文档的数量，|
|query_cache.memory_size|qcm|已使用的查询缓存存储器|
|sync_id|sync_id|分片的同步ID。|
|unassigned.at|ua|分片未分配的（UTC）时间|
|unassigned.details|ud|分片未分配的详细信息|
|unassigned.for|uf|请求未分配的UTC时间|
|unassigned.reason|ur|未分配分片的原因:<br/>`ALLOCATION_FAILED：由于分片分配失败而未分配。` <br/> `CLUSTER_RECOVERED：由于完全群集恢复而未分配。` <br/> `DANGLING_INDEX_IMPORTED：由于导入了悬空索引而未分配。` <br/> `EXISTING_INDEX_RESTORED：由于恢复到封闭索引而未分配。` <br/> `INDEX_CREATED：由于创建索引的API而未分配。` <br/> `INDEX_REOPENED：由于打开封闭索引而未分配。` <br/> `NEW_INDEX_RESTORED：由于恢复到新索引而未分配。` <br/> `NODE_LEFT：由于托管它的节点离开集群而未分配。` <br/> `REALLOCATED_REPLICA：标识一个更好的副本位置，并导致现有副本分配被取消。` <br/> `REINITIALIZED：分片从开始移回初始化时。` <br/> `REPLICA_ADDED：由于明确添加副本而未分配。` <br/> `REROUTE_CANCELLED：由于明确的取消重新路由命令而未分配。`
|

还有很多参数，就不一一写了。`help` 你就知道


#### 18、segments
返回索引 Lucene segments 信息，
```
# <target> 可以写具体的索引之外，也支持写 _all或*(通配符)，多个索引逗号隔开
GET /_cat/segments/<target>

GET /_cat/segments
```

#### 19、snapshots
返回ES的快照仓库，快照也就是ES的备份。
```
# <repository> 必选，是一个快照仓库名
GET /_cat/snapshots/<repository>
```

#### 20、task management 
返回有关当前在集群中一个或多个节点上执行的任务的信息。task 管理API,是一个开发版的,未来估计会变了解就好
```
GET /_cat/tasks
```
#### 21、templates
返回集群的索引模板
```
GET /_cat/templates/<template_name>

GET /_cat/templates
```
#### 22、thread pool
返回集群下每个节点的线程池，包括所有内置线程池和自定义线程池
```java
GET /_cat/thread_pool/<thread_pool>

GET /_cat/thread_pool

// 返回值解析：
// actinve（活跃的），
// queue（队列中的）
// reject（拒绝的） 
// completed(完成的) 
// pool_size（当前线程池中的线程数）
// size（当前线程池中配置的活动线程的固定数目。）
// type 线程池的类型。返回的值是fixed或scaling。
```

#### 23、trained model
返回训练模型的配置信息,需要 `monitor_ml` 权限
```
GET /_cat/ml/trained_models
```

#### 24、transforms
返回transformsp配置与用法信息
```
GET /_cat/transforms/<transform_id>

GET /_cat/transforms/_all

GET /_cat/transforms/*

GET /_cat/transforms
```
返回有很多列，带上help查看所有列


### 四、结尾
感觉没必要写那么多，记得第一个请求`GET /_cat` 就掌握所有了！！！

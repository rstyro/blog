---
title: ElasticSearch 分布式
date: 2017-12-01 00:09:23
tags: [ElasticSearch]
categories: 搜索引擎
---
# ElasticSearch 集群
## 这个也是超级简单的配置

## 一、Master 配置
修改 /usr/local/elasticsearch/config/elasticsearch.yml 文件
#
```
# 跨域问题
http.cors.enabled: true
http.cors.allow-origin: "*"

# 集群名称
cluster.name: lrshuai.top
node.name: master
node.master: true

# 绑定ip ,0.0.0.0 默认
network.host: 0.0.0.0
# 绑定端口
http.port: 9200

# 设置节点间交互的tcp端口，默认是9300。
transport.tcp.port: 9300
# 设置是否压缩tcp传输时的数据，默认为false，不压缩。
transport.tcp.compress: true

```

## 一、Slave 配置
修改 /usr/local/elasticsearch/config/elasticsearch.yml 文件
#
```
# 跨域问题
http.cors.enabled: true
http.cors.allow-origin: "*"

# 集群名称,这个名称要一样
cluster.name: lrshuai.top
node.name: slave1

network.host: 127.0.0.1
# 绑定端口
http.port: 8200

# 设置节点间交互的tcp端口，默认是9300。
transport.tcp.port: 9301
# 设置是否压缩tcp传输时的数据，默认为false，不压缩。
transport.tcp.compress: true

# 这个是集群中节点的自动发现和Master节点的选举。
# 节点之间使用p2p的方式进行直接通信
discovery.zen.ping.unicast.hosts:["127.0.0.1"]
```

## 其他配置
```
# 存放数据的地方，默认是安装目录
path.data: /path/to/data1,/path/to/data2 

# 存放log的地方，默认是安装目录
# Path to log files:
path.logs: /path/to/logs

# 存放插件的地方，默认是安装目录
# Path to where plugins are installed:
path.plugins: /path/to/plugins
```
## 配置好直接正常启动即可，elasticsearch 会自动添加节点。
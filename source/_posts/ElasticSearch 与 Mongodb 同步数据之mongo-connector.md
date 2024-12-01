---
title: ElasticSearch 与 Mongodb 同步数据之mongo-connector
date: 2017-12-01 11:12:32
updated: 2017-12-01 11:12:32
tags: [ElasticSearch, MongoDB]
categories: 搜索引擎
---
# ElasticSearch 与 Mongodb 同步数据之mongo-connector

## 一、安装ElasticSearch 并配置 集群
### 可参看我之前的文章

## 二、安装Mongodb

<!--more-->

### Mongodb 安装并配置副本集
### 可参看我的相关文章 ，我这里是只有一个mongo所以，栗子如下
```
use admin
db.runCommand({"replSetInitiate":{_id:"robot",members:[{_id:1,host:"127.0.0.1:2222"}]}})

# 查看状态
rs.status()
```

## 三、安装所需的工具
#### 1、pip
#### 2、mongo-connector (安装对应版本的：[https://github.com/mongodb-labs/mongo-connector](https://github.com/mongodb-labs/mongo-connector))
#### 3、elastic2-doc-manager(安装对应版本的：[https://github.com/mongodb-labs/elastic2-doc-manager](https://github.com/mongodb-labs/elastic2-doc-manager))
```shell
# 安装pip
yum -y install epel-release python-pip

# 我这里是elaseic5 
pip install 'mongo-connector[elastic5]
pip install 'elastic2-doc-manager[elastic5]'
```

## 四、开启同步
### 最好 elasticsearch 的启动用户和 mongo的启动用户一致
### 下面是同步命令：
```
mongo-connector -m 127.0.0.1:2222 -t 127.0.0.1:9201 -d elastic2_doc_manager
```
|参数:|说明|
|--|--|
|-m| mongodb的地址与端口，端口默认为27017。 |
|-t|ES的地址与端口，端口默认为9200。 |
|-d|doc manager的名称，2.x版本为： elastic2-doc-manager。|

## 五、在mongo 中插入数据验证
![](59286.png)

![](64927.png)
![](76281.png)

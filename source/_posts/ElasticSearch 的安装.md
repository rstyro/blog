---
title: ElasticSearch 的安装
date: 2017-11-30 14:09:31
tags: [ElasticSearch]
categories: 搜索引擎
---
# ElasticSearch 的安装
#### 这个安装超级简单，下载解压就可以了。前提是你已经安装了 JDK ,关于jdk的安装可参看我的文章：[Linux 安装jdk](http://www.lrshuai.top/atc/show/8)
## 一、下载安装包
### 1、打开官网下载页:[https://www.elastic.co/downloads/elasticsearch](https://www.elastic.co/downloads/elasticsearch)
```
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-6.0.0.tar.gz
```

## 二、解压

#### 我解压到/usr/local 目录下
```
tar -zxvf elasticsearch-6.0.0.tar.gz -C /usr/local/
```

## 三、启动

### 1、进入elasticsearch 的目录，运行
```
cd /usr/local/elasticsearch-6.0.0
# 启动
bin/elasticsearch -d 
```
> 上次装了个7.9版本的时候，发现有个问题我环境的JDK是1.8的，7.9这个版本是需要JDK11的，得改一下ES的jdk环境。我下载的7.9是自带JDK的，在解压的目录下有一个命名为jdk的文件夹。
> 修改bin目录下的elasticsearch.sh，在最前面添加
>```
# 这个下面的路径改成你es下jdk的路径即可
export JAVA_HOME=/opt/elasticsearch/elasticsearch-7.9.0/jdk
export PATH=$JAVA_HOME/bin:$PATH
```

## 四、其他问题

### 1、如果是7.9版本的话
> 我就用过5.6.4 和7.9.0 版本，其他版本不多说。

7.9版本得配置initial_master_nodes，添加如下配置

```
cluster.name: "youClusterName"
node.name: "youNode1"
cluster.initial_master_nodes: ["youNode1"]
```

我的`7.9` 开发环境全部配置：
```
cluster.name: "mySearch"
node.name: "myNode1"
cluster.initial_master_nodes: ["myNode1"]
# 跨域问题
http.cors.enabled: true
http.cors.allow-origin: "*"
#http.cors.allow-headers: Authorization

network.host: 0.0.0.0
http.port: 9200
transport.tcp.port: 9300

# 日志
path.logs: /home/elastic/eslogs
```

> 官方文档：[https://www.elastic.co/guide/en/elasticsearch/reference/current/targz.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/targz.html)

### 2、如果报错的话，可以参看我的文章：[Elasticsearch5.0+ 安装问题集锦](http://www.lrshuai.top/atc/show/84)
### 2、在浏览器访问 http://localhost:9200 或者 用命令 `curl http://localhost:9200`
一般返回类似如下信息：
```
{
  "name" : "O8y3xAV",
  "cluster_name" : "elasticsearch",
  "cluster_uuid" : "chl0ooDkTnuecJ3cQfWsJA",
  "version" : {
    "number" : "6.0.0",
    "build_hash" : "8f0685b",
    "build_date" : "2017-11-10T18:41:22.859Z",
    "build_snapshot" : false,
    "lucene_version" : "7.0.1",
    "minimum_wire_compatibility_version" : "5.6.0",
    "minimum_index_compatibility_version" : "5.0.0"
  },
  "tagline" : "You Know, for Search"
}

```
### 3、如果浏览器访问不了的话，可以修改配置文件 添加
```
http.cors.enabled: true
http.cors.allow-origin: "*"
```


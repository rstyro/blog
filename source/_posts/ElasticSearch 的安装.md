---
title: ElasticSearch 的安装
date: 2017-11-30 14:09:31
tags: [ElasticSearch]
categories: 搜索引擎
---
# ElasticSearch 的安装
#### 这个安装超级简单，下载解压就可以了。前提是你已经安装了 JDK ,关于jdk的安装可参看我的文章：[Linux 安装jdk](http://rstyro.gitee.io/blog/2017/05/13/Linux%20%E5%AE%89%E8%A3%85jdk/)

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
```yml
cd /usr/local/elasticsearch-6.0.0
# 启动
bin/elasticsearch -d 
```

在启动`ES7.9.0`的时候，会提示：`future versions of Elasticsearch will require Java 11; your Java version from [/usr/local/jdk1.8.0/jre] does not meet this requirement` 也就是说ES未来版本需要JDK11,我目前的环境是JDK8不符合要求。我这个包是自带JDK的，我干脆只把把自动的JDK指定为ES的JDK运行环境：
修改3个节点下的 bin/elasticsearch 文件，在最前面添加如下：
```yml
# 这个下面的路径改成你es节点下jdk的路径即可
export JAVA_HOME=/opt/elasticsearch-cluster/elasticsearch-9301/jdk
export PATH=$JAVA_HOME/bin:$PATH
```
不修改也是可以启动的，但是建议改算了，毕竟官方包都自带了，那肯定是推荐我们使用新版本。


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
```yml
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

# 生成日志路径， 默认:$ES_HOME/logs/elastcsearch.log
path.logs: /home/elastic/eslogs
```

> 官方文档：[https://www.elastic.co/guide/en/elasticsearch/reference/current/targz.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/targz.html)

### 2、如果报错的话，可以参看我的文章：[Elasticsearch5.0+ 安装问题集锦](http://rstyro.gitee.io/blog/2017/11/30/Elasticsearch5.0+%20%E5%AE%89%E8%A3%85%E9%97%AE%E9%A2%98%E9%9B%86%E9%94%A6/)

### 2、在浏览器访问 http://localhost:9200 或者 用命令 `curl http://localhost:9200`
一般返回类似如下信息：
```
{
  "name" : "youNode1",
  "cluster_name" : "youClusterName",
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


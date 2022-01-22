---
title: Elasticsearch5.0+ 安装问题集锦
date: 2017-11-30 22:21:00
updated: 2017-11-30 22:21:00
tags: [ElasticSearch]
categories: 搜索引擎
---
# Elasticsearch5.0+ 安装可能会出现的问题

## 一、服务器内存不够
> Java HotSpot(TM) 64-Bit Server VM warning: INFO: os::commit_memory(0x00000000c5330000, 986513408, 0) failed; error='Cannot allocate memory' (errno=12)

像我就是这种类型，穷人，服务器配置都是最低配的。装不了几个东西
elasticsearch 的默认是2g内存，不够就改呗。

#### 解决方法：修改 elasticsearch 下的config/jvm.options 文件
``` 
vim config/jvm.options  
```
### 把
```
-Xms2g  
-Xmx2g  
```
### 修改为  
```
-Xms512m  
-Xmx512m  
```
> 但是官方是不推荐更改JVM 的配置的，看如下图：

![](31548.png)

## 二、用root 用户启动报错
![](59786.png)

#### 因为安全问题elasticsearch 不让用root用户直接运行，所以要创建新用户
#### 建议创建一个单独的用户用来运行ElasticSearch
#### 创建elsearch用户组 及elsearch用户 并为其设置密码 elasticsearch
```
groupadd elsearch
useradd elsearch -g elsearch -p elasticsearch
```
## 三、 权限不够
> grep: /usr/local/elasticsearch/config/jvm.options: 权限不够
> ```Exception in thread "main" 2017-11-30 12:09:31,518 main ERROR No log4j2 configuration file found. Using default configuration: logging only errors to the console. Set system property 'log4j2.debug' to show Log4j2 internal initialization logging.
2017-11-30 12:09:31,697 main ERROR Could not register mbeans java.security.AccessControlException: access denied ("javax.management.MBeanTrustPermission" "register")
```

![](18725.png)

### 这个只需把elasticsearch 目录拥有者 修改为运行的用户即可。
### 解决方案：切换到root用户 执行chown 命令
```
chown -R elsearch:elsearch /usr/local/elasticsearch
```

## 四、 ERROR: [2] bootstrap checks failed
> ```ERROR: [2] bootstrap checks failed
[1]: max file descriptors [4096] for elasticsearch process is too low, increase to at least [65536]
[2]: max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144]
```


![](84529.png)

### 解决方案：
### 1、切换到root用户，编辑limits.conf 添加类似如下内容
```
vi /etc/security/limits.conf 
```

#### 添加如下内容:
```yml
* soft nofile 65536
* hard nofile 65536
* soft nproc 2048
* hard nproc 4096
```
#### 2、然后 ，修改配置sysctl.conf
```
vi /etc/sysctl.conf 
```
#### 添加下面配置：
```
vm.max_map_count=655360
```
### 保存退出后，在shell 下执行命令：
```
sysctl -p
```
## 五、浏览器访问不了虚拟机的elasticsearch
#### 如果在虚拟机中安装elasticSearch, 然后本地访问不了，可在elasticsearch 的配置文件（config/elasticsearch.yml）中加入
```yml
# 这个是跨域的配置
http.cors.enabled: true
http.cors.allow-origin: "*"

# 下面写上虚拟机的ip
network.host: 192.168.12.137

```

>参考链接： http://www.cnblogs.com/sloveling/p/elasticsearch.html

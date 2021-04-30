---
title: Filebeat收集日志到ES
date: 2021-04-30 10:13:16
updated: 2021-04-30 10:13:16
tags: [ElasticSearch,Filebeat]
categories: 搜索引擎
---

### 一、Filebeat
+ Filebeat是轻量型日志采集器
+ logstash 和filebeat都具有日志收集功能，filebeat更轻量，占用资源更少。
+ logstash 不仅仅是一个日志采集工具，它也是可以作为一个日志搜集工具，有丰富的input|filter|output插件可以使用。资源消耗比较大

#### 1、下载 Filebeat
+ 下载地址：[https://www.elastic.co/cn/downloads/beats/filebeat](https://www.elastic.co/cn/downloads/beats/filebeat)
+ 下载成功后，解压即可
```
wget https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-7.12.0-linux-x86_64.tar.gz
tar -zxvf filebeat-7.12.0-linux-x86_64.tar.gz -C /usr/local/
cd /usr/local/
mv filebeat-7.12.0-linux-x86_64 filebeat
```

#### 2、配置Filebeat
+ 默认Fileabeat收集的日志都存到ES的同一索引
+ 我想把不同的日志放到不同的索引，这样方便查找
+ 新建一个 `filebeat-myconfig.yml`
+ 内容编辑如下：
```
# 定义 gateway、nginx等应用的input类型、以及存放的具体路径
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /manage_log/sys-gateway/info.log
    - /manage_log/sys-gateway/error.log
  fields: 
    module: gateway
- type: log
  enabled: true
  paths:
    - /var/log/nginx/*.log
  fields:
    module: nginx
- type: log
  enabled: true
  paths:
    - /manage_log/dcs-original-xj/info.log
    - /manage_log/dcs-original-xj/error.log
  fields:
    module: original
    
filebeat.config.modules:
  path: ${path.config}/modules.d/*.yml
  reload.enabled: true
  
setup.template.settings:
  index.number_of_shards: 1
  
# 定义kibana的IP:PORT
setup.kibana:
  host: "192.168.31.169:5601"

# 定义模板的相关信息  
setup.template.name: "rstyro_log"
setup.template.pattern: "rstyro-*"
setup.template.overwrite: true
setup.template.enabled: true
# 自定义ES的索引需要把ilm设置为false
setup.ilm.enabled: false

# 定义 gateway、original、nginx的output
output.elasticsearch:
  # 定义ES的IP:PORT
  hosts: ["192.168.31.169:9200"]
  # 这里的index前缀lile与模板的pattern匹配，中间这一串设置为field.module变量，方面后面具体的匹配
  index: "rstyro-%{[fields.module]}-*"
  indices:
    # 这里的前缀 rstyro 同为与模板的pattern匹配，中间为field.module具体的值，当前面的input的field.module值与这里的匹配时，则index设置为定义的
    - index: "rstyro-gateway-%{+yyyy.MM.dd}"
      when.equals:
        fields:
            module: "gateway"
    - index: "rstyro-original-%{+yyyy.MM.dd}"
      when.equals: 
        fields:
            module: "original"
    - index: "rstyro-nginx-%{+yyyy.MM.dd}"
      when.equals: 
        fields:
            module: "nginx"
  
processors:
  - add_host_metadata: ~
  - add_cloud_metadata: ~
```

#### 3、启动filebeat
+ 启动filebeat
```
# -e 输出到控制台，-c 配置文件
./filebeat -e -c filebeat-myconfig.yml
```

![](result.png)

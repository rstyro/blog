---
title: Elasticsearch+Kibana+Metricbeat收集系统信息并展示仪表盘
date: 2021-04-29 11:11:32
updated: 2021-04-29 11:11:32
tags: [ElasticSearch,Kibana,Metricbeat]
categories: 搜索引擎
---
### 一、Metricbeat
+ Metricbeat是轻量型指标采集器

#### 1、下载Metericbeat
+ 下载地址：[https://www.elastic.co/cn/downloads/beats/metricbeat](https://www.elastic.co/cn/downloads/beats/metricbeat)
+ 下载成功后，解压即可
```
wget https://artifacts.elastic.co/downloads/beats/metricbeat/metricbeat-7.12.0-linux-x86_64.tar.gz
tar -zxvf metricbeat-7.12.0-linux-x86_64.tar.gz -C /usr/local/
cd /usr/local/
mv metricbeat-7.12.0-linux-x86_64 metricbeat
```
#### 2、启动Metericbeat
+ 可以编辑：`/usr/local/metricbeat.yml` 配置文件
```bash
# 启动: -e 控制台打印日志，-c 后面跟配置文件
/usr/local/metricbeat -e -c metricbeat.yml
```

#### 3、收集系统指标
+ MetricBeat使用模块来收集指标。
+ Metricbeat默认只开启了 system模块。
+ 每个模块都定义了用于从特定服务中收集数据的基本逻辑，例如Redis或MySQL。

```bash
# 查看metricbeat支持的模块列表，默认`enabled`中只有`system`，其他都是disabled不启用.
/usr/local/metricbeat/metricbeat modules list

# 启用 redis、mysql 模块
metricbeat modules enable redis mysql

# 查看各个模块的配置文件
ll /usr/local/metricbeat/modules.d
```
+ 手机系统指标到ES中，然后到kibana查看可视化界面
+ 在`metricbeat.yml`配置ES

```
output.elasticsearch:
  hosts: ["192.168.31.169:9200"]
```
+ 启动Metericbeat: `/usr/local/metricbeat -e -c metricbeat.yml`


#### 4、安装仪表盘到kibana
+ 修改配置 metricbeat.yml
```
setup.kibana:
  host: "192.168.31.169:5601"
```
+ 然后执行命令：
`/usr/local/metricbeat/metricbeat setup --dashboards` ，执行这个命令需要`kibana`是启动的状态

![](setup-metricbeat.png)

+ 如上就是成功，之后kibana就会加载有很多Metricbeat的仪表版
+ 选择添加：`[Metricbeat System] Host overview ECS` 可视化仪表盘

![](dashboards.png)

![](dashboards2.png)
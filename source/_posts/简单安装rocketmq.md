---
title: 简单安装rocketmq
date: 2017-08-20 16:22:20
updated: 2017-08-20 16:22:20
tags: [MQ]
categories: MQ
---
## 下载
```shell
# 下载，在http://www-us.apache.org/dist/rocketmq/ 选择合适的版本下载
wget http://www-us.apache.org/dist/rocketmq/4.3.2/rocketmq-all-4.3.2-bin-release.zip

# 解压
unzip rocketmq-all-4.3.2-bin-release.zip -d rocketmq

# 启动 nameserver:
nohup bin/mqnamesrv -n 127.0.0.1:9876 > /dev/null 2>&1 &

# 启动broker
mqbroker -n 127.0.0.1:9876 autoCreateTopicEnable=true


# 指定配置文件 启动broker
mqbroker -c /data/rocketmq/rocketmq/conf/2m-noslave/broker-a.properties > /dev/null 2>&1 &
```

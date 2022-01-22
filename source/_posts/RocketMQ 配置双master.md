---
title: RocketMQ 配置双master
date: 2017-08-23 14:05:41
updated: 2017-08-23 14:05:41
tags: [MQ]
categories: MQ
---
# RocketMQ 配置多master
## 一、准备工作
#### 1、虚拟机安装两台 Centos7
#### 2、jdk8
#### 3、maven 3.5.0
#### 4、git

## 二、下载并编译
```
git clone -b develop https://github.com/apache/incubator-rocketmq.git
cd incubator-rocketmq
mvn -Prelease-all -DskipTests clean install -U
cd distribution/target/apache-rocketmq
# 把编译后得到的apache-rocketmq（target下的文件夹就是） 剪切到/usr/local 下并重命名rocketmq
cp -r apache-rocketmq /usr/local/ && cd /user/local
mv apache-rocketmq rocketmq
# 用scp命令把rocketmq 文件夹复制到另一台机器。也可以在另一个台执行同样的操作。
scp -r /usr/local/rocketmq root@192.168.12.133:/usr/local/rocketmq
```

## 三、修改broker 的配置文件
### 1、两台电脑都要修改
```
vim /usr/local/rocketmq/conf/2m-noslave/broker-a.properties 
vim /usr/local/rocketmq/conf/2m-noslave/broker-b.properties
```
##### 再多一台就broker-c.properties ,以此类推可以添加多台。。
### 2、修改的内容如下：
```
#所属集群名字
brokerClusterName=rocketmq-cluster
#broker名字，注意此处不同的配置文件填写的不一样，如果是broker-a.properties 这里就写broker-a,broker-b.properties 这里就写broker-b,以此类推
brokerName=broker-a
#0 表示 Master， >0 表示 Slave
brokerId=0
#nameServer地址，分号分割
namesrvAddr=rocketmq-nameserver1:9876;rocketmq-nameserver2:9876
#在发送消息时，自动创建服务器不存在的topic，默认创建的队列数
defaultTopicQueueNums=4
#是否允许 Broker 自动创建Topic，建议线下开启，线上关闭
autoCreateTopicEnable=true
#是否允许 Broker 自动创建订阅组，建议线下开启，线上关闭
autoCreateSubscriptionGroup=true
#Broker 对外服务的监听端口
listenPort=10911
#删除文件时间点，默认凌晨 0点
deleteWhen=00
#文件保留时间，默认 48 小时
fileReservedTime=120
#commitLog每个文件的大小默认1G
mapedFileSizeCommitLog=1073741824
#ConsumeQueue每个文件默认存30W条，根据业务情况调整
mapedFileSizeConsumeQueue=300000
#destroyMapedFileIntervalForcibly=120000
#redeleteHangedFileInterval=120000
#检测物理文件磁盘空间
diskMaxUsedSpaceRatio=88
#存储路径
storePathRootDir=/usr/local/rocketmq/data
#commitLog 存储路径
storePathCommitLog=/usr/local/rocketmq/data/commitlog
#消费队列存储路径存储路径
storePathConsumeQueue=/usr/local/rocketmq/data/consumequeue
#消息索引存储路径
storePathIndex=/usr/local/rocketmq/data/index
#checkpoint 文件存储路径
storeCheckpoint=/usr/local/rocketmq/data/checkpoint
#abort 文件存储路径
abortFile=/usr/local/rocketmq/data/abort
#限制的消息大小
maxMessageSize=65536
#flushCommitLogLeastPages=4
#flushConsumeQueueLeastPages=2
#flushCommitLogThoroughInterval=10000
#flushConsumeQueueThoroughInterval=60000
#Broker 的角色
#- ASYNC_MASTER 异步复制Master
#- SYNC_MASTER 同步双写Master
#- SLAVE
brokerRole=ASYNC_MASTER
#刷盘方式
#- ASYNC_FLUSH 异步刷盘
#- SYNC_FLUSH 同步刷盘
flushDiskType=ASYNC_FLUSH
#checkTransactionMessageEnable=false
#发消息线程池数量
#sendMessageThreadPoolNums=128
#拉消息线程池数量
#pullMessageThreadPoolNums=128
```
#### 只需要修改`brokerName `这个属性就行，`nameservAddr `这个使用域名，下面会修改hosts文件。
#### 当然也可以用ip,如果用ip，下面的hosts文件配置就可以不用配，这里配的原因主要是为了方便而已没其他含义

## 四、修改/etc/hosts 文件(可选，如果上面的nameservAddr用ip,这个步骤可跳过)
### 1、两台电脑都要修改
```
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
#添加下面4行 ，注意修改成你电脑的ip
192.168.12.132 rocketmq-nameserver1
192.168.12.132 rocketmq-master1
 
192.168.12.133 rocketmq-nameserver2
192.168.12.133 rocketmq-master2
```
### 2、测试: ping 一下
```
ping rocketmq-nameserver1
ping rocketmq-nameserver2
```

## 五、修改日志配置文件
###  1、两台电脑都要修改
```
mkdir /usr/local/rocketmq/logs
cd /usr/local/rocketmq/conf && sed -i 's#${user.home}#/usr/local/rocketmq#g' *.xml
```

## 六、修改启动脚本（可不用修改，我是用虚拟机,内存不够,所以改改）
### 1、修改 bin/runserver.sh
![](1503655178352098012.png)
### 2、修改 bin/runbroker.sh
![](1503655219756096848.png)
#### 都是改成1G 和 512M 


## 七、启动

### 1、启动 nameserver
```
nohup sh /usr/local/rocketmq/bin/mqnamesrv &
#查看日志
tail -n 200 /usr/local/rocketmq/logs/rocketmqlogs/namesrv.log
#可以用jps 查看后台程序
jps
```
### 2、启动 broker
```
#在192.168.12.132 中启动
nohup sh /usr/local/rocketmq/bin/mqbroker -c /usr/local/rocketmq/conf/2m-noslave/broker-a.properties >/dev/null 2>&1 &
#在192.168.12.133 中启动，启动读取不用的配置文件（注意）
nohup sh /usr/local/rocketmq/bin/mqbroker -c /usr/local/rocketmq/conf/2m-noslave/broker-b.properties >/dev/null 2>&1 &
#查看启动的日志
tail -n 200 /usr/local/rocketmq/logs/rocketmqlogs/broker.log
```

### 3、端口开放
#### 1、注意开放端口

+ 9876 （nameserver 端口）
+ 10909（主要是fastRemotingServer服务使用）
+ 10911（Broker 对外服务的监听端口）
+ 10912 (Master 和Slave同步的数据的端口，)

#### 2、废话一下:
`/dev/null` ：代表空设备文件
`> ` ：代表重定向到哪里，例如：echo "123" > /home/123.txt
`1`  ：表示stdout标准输出，系统默认值是1，所以">/dev/null"等同于"1>/dev/null"
`2`  ：表示stderr标准错误
`& ` ：表示等同于的意思，2>&1，表示2的输出重定向等同于1

 `1 > /dev/null 2>&1 ` 语句含义：
`1 > /dev/null `： 首先表示标准输出重定向到空设备文件，也就是不输出任何信息到终端，说白了就是不显示任何信息。
`2>&1 `：接着，标准错误输出重定向（等同于）标准输出，因为之前标准输出已经重定向到了空设备文件，所以标准错误输出也重定向到空设备文件。

## 八、代码示例
#### 1、 Consumer类
```java
package com.alibaba.rocketmq.example.quickstart;
 
import java.io.UnsupportedEncodingException;
import java.util.List;
 
import com.alibaba.rocketmq.client.consumer.DefaultMQPushConsumer;
import com.alibaba.rocketmq.client.consumer.listener.ConsumeConcurrentlyContext;
import com.alibaba.rocketmq.client.consumer.listener.ConsumeConcurrentlyStatus;
import com.alibaba.rocketmq.client.consumer.listener.MessageListenerConcurrently;
import com.alibaba.rocketmq.client.exception.MQClientException;
import com.alibaba.rocketmq.common.consumer.ConsumeFromWhere;
import com.alibaba.rocketmq.common.message.MessageExt;
 
 
/**
 * Consumer，订阅消息
 */
public class Consumer {
 
    public static void main(String[] args) throws InterruptedException, MQClientException {
        DefaultMQPushConsumer consumer = new DefaultMQPushConsumer("hello_pushconsumer");
        /**
         * 设置Consumer第一次启动是从队列头部开始消费还是队列尾部开始消费<br>
         * 如果非第一次启动，那么按照上次消费的位置继续消费
         */
        consumer.setConsumeFromWhere(ConsumeFromWhere.CONSUME_FROM_FIRST_OFFSET);
        consumer.setNamesrvAddr("192.168.12.132:9876;192.168.12.133:9876");
        consumer.subscribe("TopicTest", "*");
 
        consumer.registerMessageListener(new MessageListenerConcurrently() {
 
            @Override
            public ConsumeConcurrentlyStatus consumeMessage(List<MessageExt> msgs,
                    ConsumeConcurrentlyContext context) {
                try {
                     for(MessageExt msg:msgs){
                         String topic=msg.getTopic();
                         String tags=msg.getTags();
                         String msgBody = new String(msg.getBody(),"utf-8");
                         System.out.println(topic+" -- "+tags+" -- "+msgBody);
                     }
                } catch (UnsupportedEncodingException e) {
                    e.printStackTrace();
                }
                 
                return ConsumeConcurrentlyStatus.CONSUME_SUCCESS;
            }
        });
 
        consumer.start();
 
        System.out.println("==================Consumer Started.===========================");
    }
}
```

### 2、Producer类
```java
package com.alibaba.rocketmq.example.quickstart;
 
import com.alibaba.rocketmq.client.exception.MQClientException;
import com.alibaba.rocketmq.client.producer.DefaultMQProducer;
import com.alibaba.rocketmq.client.producer.SendResult;
import com.alibaba.rocketmq.common.message.Message;
/**
 * Producer，发送消息
 * 
 */
public class Producer {
    public static void main(String[] args) throws MQClientException, InterruptedException {
        DefaultMQProducer producer = new DefaultMQProducer("hello_producer");
        producer.setNamesrvAddr("192.168.12.132:9876;192.168.12.133:9876");
        producer.start();
 
        for (int i = 0; i < 1000; i++) {
            try {
                Message msg = new Message("TopicTest",// topic
                    "TagA",// tag
                    ("Hello RocketMQ " + i).getBytes()// body
                        );
                SendResult sendResult = producer.send(msg);
                System.out.println(sendResult);
            }
            catch (Exception e) {
                e.printStackTrace();
                Thread.sleep(1000);
            }
        }
        producer.shutdown();
    }
}
```
![](1504160283634075289.png)



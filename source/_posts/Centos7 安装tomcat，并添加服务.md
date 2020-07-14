---
title: Centos7 安装tomcat，并添加服务
date: 2017-05-10 22:06:08
tags: [开发工具, 系统装机, Linux]
categories: 网络运维
---
# 一、下载源码包
### 官网：[https://tomcat.apache.org/download-80.cgi](https://tomcat.apache.org/download-80.cgi)
#### 复制下载地址，到 linux 用 wget下载
```
wget http://mirrors.hust.edu.cn/apache/tomcat/tomcat-8/v8.5.14/bin/apache-tomcat-8.5.14.tar.gz
```
## 二、解压源码包
```
# -C 是解压到指定位置，这里的位置为：/usr/local
tar -zxvf apache-tomcat-8.5.14.tar.gz -C /usr/local 
```
## 三、重命名 (可选)
```
cd /usr/local
mv apache-tomcat-8.5.14 tomcat
```
## 四、配置环境变量
```
vim /etc/profile
```
### 在最后加入,下面两行代码
```
export CATALINA_HOME=/usr/local/tomcat
export CATALINA_BASE=/usr/local/tomcat
```
## 五、添加服务
#### (1)、修改tomcat的bin目录下的catalina.sh 文件
```
vim /usr/local/tomcat/bin/catalina.sh
```
#### (2)、在定义CATALINA_BASE定义的后面加上
```
CATALINA_PID="$CATALINA_BASE/tomcat.pid"
```
##### 如下图所示：
![示例图说明](1494743565799068934.png)

#### (3)、创建tomcat.service
```
vim /lib/systemd/system/tomcat.service
```
##### 写入如下内容
```
[Unit]
 
Description=Tomcat
After=syslog.target network.target remote-fs.target nss-lookup.target
 
[Service]
 
Type=forking
 
Environment="JAVA_HOME=/usr/local/jdk"
PIDFile=/usr/local/tomcat/tomcat.pid
ExecStart=/usr/local/tomcat/bin/startup.sh
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true
 
[Install]
 
WantedBy=multi-user.target
```
> 最后记得 保存 才退出（ESC键 ,然后shift + ；，然后 wq）,（啰嗦 ，哈哈）

#### (4)、测试是否可以用systemctl 来操作tomcat
```
#启动tomcat
systemctl start tomcat 

#关闭tomcat
systemctl stop tomcat

#查看是否启动成功
ps aux | grep tomcat

```
> 正文到此结束，谢谢观看，觉得有用，赞一个再走啊，客官！

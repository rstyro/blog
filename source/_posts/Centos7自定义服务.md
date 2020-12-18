---
title: Centos7自定义服务
date: 2020-12-18 18:00:33
tags: [Linux]
categories: 网络运维
---

## 一、前言
+ 在CentOS7下，已经不再使用chkconfig命令管理系统开机自启动服务和条件自定义脚本服务了，
+ 而是使用管理unit的方式来控制开机自启动服务和添加自定义脚本服务。
+ 如果想把自定义的脚本变成服务进程，都需要写对应的service配置文件，这样才能被unit所管理.


## 二、自定义服务配置脚本文件解析
一般服务脚本文件由三部分组成：
+ [Unit]	单元的定义，描述
+ [Service]	服务的启动相关配置
+ [Install]	就我的理解实时，安装服务的命名空间，就是起到一个隔离的作用。

### 1、Unit
+ Description：
    给出当前服务的简单描述。
+ Documentation：
    给出文档位置。
+ After：
    表示本服务应该在某服务之后启动。
+ Before：
    表示本服务应该在某服务之前启动。After和Before字段只涉及启动顺序，不涉及依赖关系。设置依赖关系，需要使用Wants字段和Requires字段。
+ Wants：
    表示本服务与某服务之间存在“依赖”系，如果被依赖的服务启动失败或停止运行，不影响本服务的继续运行。
+ Requires：
    表示本服务与某服务之间存在“强依赖”系，如果被依赖的服务启动失败或停止运行，本服务也必须退出

### 2、Service
+ Type：启动类型
	+ simple（默认值）：ExecStart字段启动的进程为主进程。
	+ forking：ExecStart字段将以fork()方式启动，此时父进程将会退出，子进程将成为主进程。
	+ oneshot：类似于simple，但只执行一次，Systemd会等它执行完，才启动其他服务。
	+ dbus：类似于simple，但会等待D-Bus信号后启动。
	+ notify：类似于simple，启动结束后会发出通知信号，然后Systemd再启动其他服务。
	+ idle：类似于simple，但是要等到其他任务都执行完，才会启动该服务
+ ExecStart：    定义启动进程时执行的命令
+ ExecReload：   重启服务时执行的命令
+ ExecStop： 停止服务时执行的命令
+ ExecStartPre： 启动服务之前执行的命令
+ ExecStartPost：    启动服务之后执行的命令
+ ExecStopPost： 停止服务之后执行的命令
+ KillMode：定义Systemd如何停止服务,它可以设置的值如下
	+ control-group(默认值)：  当前控制组里面的所有子进程，都会被杀掉
	+ process： 只杀主进程
	+ mixed：   主进程将收到 SIGTERM 信号，子进程收到 SIGKILL 信号
	+ none：    没有进程会被杀掉，只是执行服务的 stop 命令
+ Restart：定义了服务退出后,Systemd的重启方式,它可以设置的值如下：
	+ no(默认值) 退出后不会重启
	+ on-success  只有正常退出时（退出状态码为0），才会重启
	+ on-failure  非正常退出时（退出状态码非0），包括被信号终止和超时，才会重启
	+ on-abnormal 只有被信号终止和超时，才会重启
	+ on-abort    只有在收到没有捕捉到的信号终止时，才会重启
	+ on-watchdog 超时退出，才会重启
	+ always  不管是什么退出原因，总是重启
+ EnvironmentFile=文件路径    指定当前服务的环境参数文件
+ RestartSec=数值   表示Systemd重启服务之前，需要等待的秒数
+ PIDFile=PID文件路径 PID进程文件
+ KillSignal=信号量  停止信号量,值一般为SIGQUIT
+ TimeoutStopSec=数值   停止超时时间
+ PrivateTmp=布尔值  独立空间true或false,即文件系统名字空间的配置将被该命令行启动的进程忽略


### 3、Install

+ WantedBy: 表示该服务所在的 Targe，target的含义是服务组，表示一组服务，它可以设置的值如下:
	+ multi-user.target   表示多用户命令行状态
	+ graphical.target    表示图形用户状态，它依赖于multi-user.target      

## 三、自定义Java服务
把Java程序添加到系统服务中。本文的重点

### 1、编写脚本
需要写服务脚本和程序关闭启动脚本，如下

#### 1.1、编写服务脚本
+ 在`/usr/lib/systemd/system/`下新建一个自定义服务脚本，命名为：`minibox.service`(名字随便写)，如下
+ `vim /usr/lib/systemd/system/minibox.service` 编辑如下内容：

```
[Unit]
Description=Java
After=network.target mysqld.service
 
[Service]
User=root
Group=root

Type=forking
KillMode=process
Environment="JAVA_HOME=/usr/local/java/jdk8"
ExecStart=/usr/local/minibox/bin/start.sh
ExecReload=/usr/local/minibox/bin/restart.sh
ExecStop=/usr/local/minibox/bin/stop.sh
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```

+ 我们定义一个Java服务，里面的脚本有：start.sh、stop.sh、restart.sh
+ 内容如下

#### 1.2、start.sh
启动脚本
```sh
#!/bin/bash

JAVA_HOME=/usr/local/java/jdk8
PATH=$PATH:$JAVA_HOME/bin
nohup java -jar /usr/local/minibox/minibox.jar >/usr/local/minibox/logs/out.log 2>&1 &
```

**这里需要注意的是，需要写JAVA_HOME环境,不然会报错，好像在服务脚本写无效，不知道是不是我写错的原因**

#### 1.3、stop.sh
停止脚本
```
#!/bin/bash
ods_pid=`ps -ef | grep minibox.jar |grep -v color |grep -v grep | awk '{print $2}'`
if [[ $ods_pid != "" ]]
then
	echo " pid= $ods_pid"
	echo "stop..."
	kill -9 $ods_pid
	echo "已停止ods_jar"
else
	echo "程序未启动"
fi
```

#### 1.4、restart.sh
重启脚本,调用关闭在启动即可
```
./stop.sh
sleep 1
./start.sh
```


### 2、加载服务
在上面的脚本文件和Java应用程序包都放之后
```
// 加载、刷新服务
systemctl daemon-reload

// 开机自启动
systemctl enable minibox.service
// 停止开机自启动
systemctl disable minibox.service

// 开启服务
systemctl start minibox.service

// 停止服务
systemctl stop minibox.service

// 重启服务
systemctl restart minibox.service

// 查看服务状态
systemctl status minibox.service

// 查看服务日志
journalctl -f -u minibox.service

// 查看所有已启动的service
systemctl list-units --type=service
```


### 三、其他
其实可以把3个脚本整合成一个脚本，然后通过参数执行对应的方法，如下

**minibox-server.sh**
```
#!/bin/bash
echo '==minibox-server=='
JAVA_HOME=/usr/local/java/jdk8
PATH=$PATH:$JAVA_HOME/bin

killminibox()
{
box_pid=`ps -ef | grep minibox.jar |grep -v color |grep -v grep | awk '{print $2}'`
if [[ $box_pid != "" ]]
then
	echo " pid= $box_pid"
	echo "stop..."
	kill -9 $box_pid
	echo "已停止minibox"
else
	echo "程序未启动"
fi
}

startminibox()
{
# 远程调试的启动方法
# nohup java -jar -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005  /usr/local/minibox/minibox.jar >out.log 2>&1 &
nohup java -jar  /usr/local/minibox/minibox.jar >out.log 2>&1 &
echo "启动成功"
}

case $1 in
start)
startminibox
;;
stop)
killminibox
;;
restart)
killminibox
startminibox
;;
*)
echo "命令错误，请检查"
;;
esac

```

通过case 函数，选择执行什么脚本，执行方式如下：
```
./minibox-server.sh start
./minibox-server.sh stop
./minibox-server.sh restart
```

**参考链接：**
+ [http://www.jinbuguo.com/systemd/systemd.service.html](http://www.jinbuguo.com/systemd/systemd.service.html)
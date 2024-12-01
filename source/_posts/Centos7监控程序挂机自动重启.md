---
title: Centos7监控程序挂机自动重启
date: 2022-01-21 14:23:10
updated: 2022-01-21 14:23:10
tags: [Linux]
categories: 网络运维
---

### 一、前言

- 就是刚去公司，然后有个项目是每天都需要执行一些任务的
- 然后听说之前旧版的项目有时会自动挂了，导致任务没执行
- 然后我接手之后改版之后，暂时是没遇到挂了的情况。
- 但是为了保险，打算在服务器写一个定时监控程序，如果挂了就给它重启
> 虽然对自己代码也算自信，但是多重防护还是有必要的
>

<!--more-->

### 二、Centos7设置定时任务
- 在centos上最常用的定时任务应该就是crontab了，本文也是用它

#### 1、检查是否安装了crontab
- 运行命令：`crontab -l`
- 如果显示`no crontab for root` 或者 显示当前的任务列表 或者 不报错 那说明已经安装

#### 2、安装crontab
- 如果发现没有安装，直接执行yum安装即可，如下

```bash
# 安装crontab
yum install -y cronie

# 常用的一些命令
# 启动服务
systemctl start   crond
# 停止服务
systemctl stop    crond
# 重启服务
systemctl restart crond
# 重载配置文件
systemctl reload  crond
# 查看状态
systemctl status  crond

# 设定某个用户的cron服务
crontab -u 		

# 显示crontab文件(显示已设置的定时任务)
crontab -l
# 编辑crontab文件(编辑定时任务)
crontab -e
# 删除crontab文件(删除定时任务)
crontab -r
# 删除crontab文件提醒用户(删除定时任务)
crontab -i
```

#### 3、设置定时任务
- 设置定时有几种方式

##### ①、直接编辑配置文件
- 配置文件路径：`/etc/crontab`
- 直接添加到最后一行即可
- 因为在crontab中，`%`是代表着换行，所以需要转义
- 如：`*  *  *  *  * root echo \"test-$(date '+\%Y\%m\%d\%H\%M\%S') info\" >> /root/cron.log`

![](crontab.png)

##### ②、使用`crontab -e`命令编辑
- 使用命令编辑相当于就是编辑当前用户的任务，所以不需要加用户字段
- 如：`*  *  *  *  * echo \"test-$(date '+\%Y\%m\%d\%H\%M\%S') info\" >> /root/cron.log`
- 这里其实会写入到：`/var/spool/cron/` 目录下以当前用户名字命名的文件
- 如，如果是root用户，那么就是:`/var/spool/cron/root`这个文件


### 三、定时监控程序
- 知道怎么设置定时任务，那接下来就是写脚本查看程序是否运行了

#### 1、编写脚本
- 我这边是查看Java进程，思路是一样的，就是通过命令查看程序是否在运行
- 为了方便，我把程序的 关闭、启动、监控、日志 等全放一个脚本里面了。
- 如下：

```bash
#!/bin/bash

source /etc/profile

# 脚本当前目录
CUR_PATH=$( cd ${0%/*} && pwd )
LOG=$CUR_PATH/logs
BACKUP=$CUR_PATH/backup
cd $CUR_PATH
# 查看目录下的jar包
JAR=$(find . -maxdepth 1 -name "*.jar")
JAR_NAME="${JAR:2}"
# JAR_NAME=met-machining-process.jar
JARNAME=${JAR_NAME%.*}
JARNAME_TYPE=${JAR_NAME##*.}

# 得到程序执行的进程PID号
JAR_PID=`ps -ef | grep $JAR_NAME  |grep -v color |grep -v grep | awk '{print $2}'`
CRON_LOG=$LOG/$(date "+%Y-%m-%d")_cron.log

check()
{
if [[ ! -d "$LOG"  ]]
then
        mkdir -p $LOG
fi

if [[ ! -d "$BACKUP"  ]]
then
        mkdir -p $BACKUP
fi

}

# 监控进程执行的
monitor()
{
DATE_STR=`date "+%Y-%m-%d_%H:%M:%S"`
if [[ $JAR_PID != "" ]]
then
        echo "$DATE_STR $JAR_NAME 进程ID pid: $JAR_PID 正在运行" >> $CRON_LOG
else
        echo "$DATE_STR $JAR_NAME 未启动,尝试启动 " >> $CRON_LOG
        start
fi
}

backup()
{
cd $CUR_PATH

if [ -f "$JAR_NAME" ];then
    sudo cp $JAR_NAME $BACKUP/$JARNAME-$(date "+%Y%m%d-%H%M%S").$JARNAME_TYPE
    sleep 2s
fi

}

stop()
{

if [[ $JAR_PID != "" ]]
then
        echo "$JAR_NAME 进程ID pid: $JAR_PID"
        echo "stop..."
        kill -9 $JAR_PID
        echo "已停止$JAR_NAME"
else
        echo "$JAR_NAME 未启动"
fi
}

start()
{
JAR_PID=`ps -ef | grep $JAR_NAME  |grep -v color |grep -v grep | awk '{print $2}'`
if [ ! -z "$JAR_PID" ]
then
        echo "$JAR_NAME 正在运行,进程ID:$JAR_PID"
        exit 0
fi
echo "" > /$LOG/out.log
nohup java -jar -Dspring.profiles.active=test  $JAR_NAME >$LOG/out.log 2>&1 &
echo "$JAR_NAME 启动成功"
}

status()
{
if [ ! -z "$JAR_PID" ]
then
        echo "$JAR_NAME 正在运行,进程ID:$JAR_PID"
else
        echo "$JAR_NAME 未在运行"
fi
}

logger()
{
        tail -200f $LOG/out.log
}

monitorlog()
{
        tail -200f $CRON_LOG
}


check

case $1 in
start)
        start
        ;;
stop)
        stop
        ;;
restart)
        stop
        start
        ;;
status)
        status
        ;;
log)
        logger
        ;;
backup)
        backup
        ;;
monitor | m)
        monitor
        ;;
monitorlog | mlog)
        monitorlog
        ;;
*)
echo "命令错误，可选:$0 {stop|start|restart|status|log}"

;;
esac
```

- 如上，脚本中的 `monitor` 方法就是监控程序执行的
- 我是把监控的信息，打印到了 `cron.log`日志文件中


##### ②、设置定时任务
- 执行命令：`crontab -e` 添加内容：`*/1 * * * * /home/met/server.sh monitor`
- 然后就结束了，执行结果如下：

![](monitor.png)

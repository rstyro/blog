---
title: Crontab 命令详解
date: 2017-10-16 14:57:54
updated: 2017-10-16 14:57:54
tags: [Linux]
categories: 网络运维
---
# Crontab 概念
#### crontab命令常见于Unix和类Unix的操作系统之中，用于设置周期性被执行的指令。该命令从标准输入设备读取指令，并将其存放于“crontab”文件中（是“cron table”的简写），以供之后读取和执行。该词来源于希腊语 chronos(χρνο)，原意是时间。通常，crontab储存的指令被守护进程激活， crond常常在后台运行，每一分钟检查是否有预定的作业需要执行。这类作业一般称为cron jobs。

> 简单点说：就是和闹钟的概念类似。就是定时执行 

<!--more-->

## 一、检查 crontab 服务是否安装

##### 下面的命令 如果显示 ‘no crontab for root’ 或者 显示当前的任务列表 或者 不报错 那说明已经安装，
```
crontab -l
```

#### 1、如果没有安装 cron 服务
##### Contos 
```
yum -y install cronie
```
##### ubuntu
```
apt-get install cron
```

#### 2、cron 服务的启动与关闭

##### Contos 
```
# 查看cond 状态
service crond status

# 启动cron
service crond start

# 关闭cron
service crond stop

# 重启cron
service crond restart

```
##### Ubuntu 
```
# 查看cond 状态
service cron status

# 启动cron
service cron start

# 关闭cron
service cron stop

# 重启cron
service cron restart
```

## 二、crontab 命令

### 1．命令格式：
```
	crontab [-u user] file
	crontab [-u user] [ -e | -l | -r ]
```
### 2．命令功能：
```
通过crontab 命令，我们可以在固定的间隔时间执行指定的系统指令或 shell script脚本。时间间隔的单位可以是分钟、小时、日、月、周及以上的任意组合。这个命令非常设合周期性的日志分析或数据备份等工作。
```
### 3．命令参数：
```
-u user：用来设定某个用户的crontab服务，例如，“-u ixdba”表示设定ixdba用户的crontab服务，此参数一般有root用户来运行。
file：file是命令文件的名字,表示将file做为crontab的任务列表文件并载入crontab。如果在命令行中没有指定这个文件，crontab命令将接受标准输入（键盘）上键入的命令，并将它们载入crontab。
-e：编辑某个用户的crontab文件内容。如果不指定用户，则表示编辑当前用户的crontab文件。
-l：显示某个用户的crontab文件内容，如果不指定用户，则表示显示当前用户的crontab文件内容。
-r：从/var/spool/cron目录中删除某个用户的crontab文件，如果不指定用户，则默认删除当前用户的crontab文件。
-i：在删除用户的crontab文件时给确认提示。
```

#### 4、crontab 文件格式

##### 每一行都代表一项任务，每行的每个字段代表一项设置，它的格式共分为六个字段，前五段是时间设定段，第六段是要执行的命令段，格式如下：

```
minute   hour   day   month   week   command
# For details see man 4 crontabs
# Example of job definition:
.---------------------------------- minute (0 - 59) 表示分钟
|  .------------------------------- hour (0 - 23)	表示小时
|  |  .---------------------------- day of month (1 - 31)	表示日期
|  |  |  .------------------------- month (1 - 12) OR jan,feb,mar,apr ... 表示月份
|  |  |  |  .---------------------- day of week (0 - 6) (Sunday=0 or 7) OR sun,mon,tue,wed,thu,fri,sat 	表示星期（0 或 7 表示星期天）
|  |  |  |  |  .------------------- username  以哪个用户来执行 
|  |  |  |  |  |			.------ command  要执行的命令，可以是系统命令，也可以是自己编写的脚本文件
|  |  |  |  |  |            |
*  *  *  *  * user-name  command to be executed
```
##### 格式示例：
|格式|说明|
|--|--|
|`*/1 * * * * service httpd restart` |每一分钟 重启httpd服务 |
|`0 */1 * * * service httpd restart` |每一小时 重启httpd服务 |
|`30 21 * * * service httpd restart`|每天 21：30 分 重启httpd服务 |
|`26 4 1,5,23,28 * * service httpd restart`|每月的1号，5号 23 号 28 号 的4点26分，重启httpd服务|
|`26 4 1-21 * * service httpd restart`|每月的1号到21号 的4点26分，重启httpd服务|
|`*/2 * * * * service httpd restart`|每隔两分钟 执行，偶数分钟 重启httpd服务|
|`1-59/2 * * * * service httpd restart`|每隔两分钟 执行，奇数 重启httpd服务|
|`0 23-7/1 * * * service httpd restart`|每天的晚上11点到早上7点 每隔一个小时 重启httpd服务|
|`0,30 18-23 * * * service httpd restart`|每天18点到23点 每隔30分钟 重启httpd服务|
|`0-59/30 18-23 * * * service httpd restart`|每天18点到23点 每隔30分钟 重启httpd服务|
|`59 1 1-7 4 * test 'date +\%w' -eq 0 && /root/a.sh `|四月的第一个星期日 01:59 分运行脚本 /root/a.sh ，命令中的 `test`是判断，`%w`是数字的星期几|

### 5、小结：
+ `* `表示任何时候都匹配
+ `"a,b,c"` 表示a 或者 b 或者c 执行命令
+ `"a-b"` 表示a到b 之间 执行命令
+ `"*/a"` 表示每 a分钟(小时等) 执行一次
+ crontab 不能编辑系统级的 任务

##### 其他需求 : crontab 最小执行时间是分钟，如果是需要 半分钟执行，如果实现呢？，看如下：
每30秒 把时间写入 /tmp/cron.txt 文件
```
*/1 * * * * data >> /tmp/cron.txt
*/1 * * * * sleep 30s;data >> /tmp/cron.txt
```

## 三、crontab 的配置文件

|文件|说明|
|--|--|
|/etc/crontab|全局配置文件|
|/etc/cron.d|这个目录用来存放任何要执行的crontab文件或脚本|
|/etc/cron.deny|该文件中所列用户不允许使用crontab命令|
|/etc/cron.allow|该文件中所列用户允许使用crontab命令|
|/var/spool/cron/|所有用户crontab文件存放的目录,以用户名命名，比如你是root 用户，那么当你添加任务是，就会在该路径下有一个root文件。|
|/etc/cron.deny|该文件中所列用户不允许使用crontab命令|
|/var/log/cron|crontab 的日志文件|



## 四、注意事项
#### 1、环境变量
##### 环境变量的值，在crontab 文件中获取不到，所以要注意，可以写脚本
#### 2、%
##### 在crontab中%是有特殊含义的，表示换行的意思。如果要用的话必须进行转义\%
```
`59 1 1-7 4 * test 'date +\%w' -eq 0 && /root/a.sh `
```

> 正文到此结束，如果觉得有用，点个赞可否！！！！！

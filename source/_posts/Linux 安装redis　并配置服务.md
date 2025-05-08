---
title: Linux 安装redis　并配置服务
date: 2017-06-09 15:14:58
updated: 2017-06-09 15:14:58
tags: [Linux, Redis]
categories: 网络运维
---
# Centos 安装redis 并配置服务

## 一.下载源码包

```
# 安装gcc依赖
yum install -y gcc gcc-c++
wget http://download.redis.io/releases/redis-4.0.14.tar.gz
tar -zxvf redis-4.0.14.tar.gz -C /opt/
cd /opt/redis-4.0.14/
make PREFIX=/usr/local/redis install      //指定安装的路径,
```

<!--more-->

#### 可能报错一
> zmalloc.h:50:31: error: jemalloc/jemalloc.h: No such file or directory
zmalloc.h:55:2: error: #error "Newer version of jemalloc required"
make[1]: *** [adlist.o] Error 1
make[1]: Leaving directory `/data0/src/redis-2.6.2/src'
make: *** [all] Error 2

#### 可以改成
> make MALLOC=libc PREFIX=/usr/local/redis install   
ll /usr/local/redis/bin

#### 可以报错二
```
cc: error: ../deps/hiredis/libhiredis.a: No such file or directory
cc: error: ../deps/lua/src/liblua.a: No such file or directory
make[1]: *** [redis-server] Error 1
make[1]: Leaving directory `/usr/local/src/redis-4.0.1/src'
make: *** [all] Error 2
```
**解决方法：**
+ 进入源码包目录下的`deps`目录中执行:
+ `make lua hiredis linenoise`

## 二、添加服务
### a)、这个是centos6 的service 命令
#### 1、创建服务脚本
```
cp /opt/redis-4.0.14/utils/redis_init_script  /etc/rc.d/init.d/redis
mkdir /etc/redis             #创建redis目录，是为了以后可以存放多个redis配置  
cp /opt/redis-4.0.14/redis.conf /etc/redis/6379.conf      
vim /etc/rc.d/init.d/redis               #修改如下圈出来的地方
```
![](1497593356955096462.png)

> 前面两行注释是：redis服务必须在运行级2，3，4，5下被启动或关闭，启动的优先级是90，关闭的优先级是10。

#### 2、修改配置文件
```
vim /etc/redis/6379.conf  
```
##### 把daemnize no改为yes，意思是后台运行

#### 3、添加服务

```
chkconfig --add redis   	#如果没报错的话，说明成功，可以用
chkconfig --list        	#查看所有服务

service redis start         #启动redis服务器
ps -ef | grep redis         #查看是否启动成功
```

## b)、这个是centos 7 的systemctl 命令
#### 使用systemctl 命令之前先来说说 systemctl脚本的配置
#### 位置：/lib/systemd/system/
```
[Unit]
	部分主要是对这个服务的说明，内容包括Description和After，
	Description		用于描述服务，
	After			用于描述服务类别;
[Service]
	部分是服务的关键，是服务的一些具体运行参数的设置，
	这里:
	Type=forking	是后台运行的形式，
	PIDFile		  为存放PID的文件路径，
	ExecStart		为服务的运行命令，
	ExecReload		为重启命令，
	ExecStop			为停止命令，
	PrivateTmp=True	表示给服务分配独立的临时空间，
	

[Install]
	部分是服务安装的相关设置，可设置为多用户的
```
#### 1、创建redis 脚本
```
vim /lib/systemd/system/redis.service
```
#### 2、编辑内容
```shell
[Unit]
Description=Redis
After=syslog.target network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=/var/run/redis_6379.pid
ExecStart=/usr/local/redis/bin/redis-server /etc/redis/6379.conf
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target

```

##### 先说明一下啊，上面的：
##### PIDFile   这个值要和 上面配置脚本中的 `ExecStart `命令启动 redis 的配置文件（/etc/redis/6379.conf）里的pidfile 一样，比如下图：
![](40316.png)

##### ExecStart 前面是redis启动的服务脚本 空格 之后是启动需要的配置文件路径

#### 3、重载系统服务
```
systemctl daemon-reload
```

#### 4、启动redis 服务
```
systemctl start redis.service 
```

#### 5、开机自启动 (可选)
```
systemctl enable redis.service
```
###　结束，配置不成功，评论说明，不出意外　３分钟之内回复


## 三、Centos一键脚本安装Redis
- 使用脚本安装

```bash
#!/bin/bash
set -e

REDIS_CONF="/etc/redis.conf"
SERVICE_NAME="redis"

echo -e "\033[36m[1/5] 安装EPEL仓库\033[0m"
dnf install -y epel-release

echo -e "\033[36m[2/5] 安装Redis\033[0m"
dnf install -y redis

echo -e "\033[36m[3/5] 配置Redis\033[0m"
# 备份原始配置
cp ${REDIS_CONF} ${REDIS_CONF}.bak

# 基础优化配置
sed -i 's/^bind 127.0.0.1 -::1/# bind 127.0.0.1 -::1/' ${REDIS_CONF}
sed -i 's/^protected-mode yes/protected-mode no/' ${REDIS_CONF}
sed -i 's/^daemonize no/daemonize yes/' ${REDIS_CONF}
sed -i 's/^# requirepass foobared/requirepass MyRedisPwd!/' ${REDIS_CONF}

echo -e "\033[36m[4/5] 启动服务\033[0m"
systemctl enable --now ${SERVICE_NAME}
firewall-cmd --permanent --add-port=6379/tcp
firewall-cmd --reload

echo -e "\033[36m[5/5] 验证安装\033[0m"
echo "服务状态:"
systemctl status ${SERVICE_NAME} --no-pager

echo -e "\n连接测试:"
redis-cli -a MyRedisPwd! ping


```

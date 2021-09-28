---
title: Centos7安装单机版Greenplumdb6.17
date: 2021-09-28 14:28:21
updated: 2021-09-28 14:28:21
tags: [Greenplumdb]
categories: 数据库
---

### 一、Centos7环境配置

#####  1、关闭防火墙

```bash
# 关闭防火墙：
systemctl stop firewalld

# 禁止防火墙开机启动：
systemctl disable firewalld
```
+ 其实不关闭防火墙也可以，但是需要把后面涉及到的数据库端口开放就行（保险点就全关了）


#####  2、修改主机名
+ 这个还是要的,后面配置ssh免密登录啥的需要用到

```bash
# 修改主机名：
hostnamectl set-hostname master205
```

+ 修改文件 `/etc/hosts` 添加如下内容

```
# 配置主机域名为刚刚的hostname,192.168.1.205是你服务器的ip
192.168.1.205 master205

```

##### 3、关闭selinux
+ 修改配置文件：`/etc/selinux/config`
+ 将里面的`SELINUX`选项改为：`SELINUX=disabled`

##### 4、修改内核
+ 修改文件：`/etc/sysctl.conf`
+ 添加如下内容：

```bash
net.ipv4.ip_forward = 0 
net.ipv4.conf.default.accept_source_route = 0 
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_recycle = 1 
net.ipv4.tcp_max_syn_backlog = 4096 
net.ipv4.conf.all.arp_filter = 1
net.ipv4.ip_local_port_range = 1025 65535
net.core.netdev_max_backlog= 10000 
net.core.rmem_max = 2097152
net.core.wmem_max = 2097152
net.core.somaxconn = 2048
kernel.sysrq = 1 
kernel.core_uses_pid = 1 
kernel.msgmni = 2048 
kernel.msgmax = 65536
kernel.msgmnb = 65536 
kernel.shmmni = 4096 
kernel.shmmax = 500000000 
kernel.shmall = 4000000000 
kernel.sem = 250 64000 100 512 
vm.overcommit_memory = 2
```

+ 修改文件描述符文件：`/etc/security/limits.conf`
+ 如下内容：

```
* soft nofile 65536
* hard nofile 65536
* soft nproc 131072
* hard nproc 131072
```

+ 可以参考文档：[https://github.com/greenplum-db/gpdb/blob/master/README.CentOS.bash](https://github.com/greenplum-db/gpdb/blob/master/README.CentOS.bash)



### 二、安装Greenplum-db
+ 系统环境差不多准备好了
+ DB配置：1 master，1 primary segment ， 1个mirror segment

####  1、下载greenplum-db 安装包
+ Github下载目前最新的release版本，地址：[https://github.com/greenplum-db/gpdb/releases/download/6.17.6/open-source-greenplum-db-6.17.6-rhel7-x86_64.rpm](https://github.com/greenplum-db/gpdb/releases/download/6.17.6/open-source-greenplum-db-6.17.6-rhel7-x86_64.rpm)
+ 直接使用wget下载，然后安装如下：

```bash
# 下载到/opt
cd /opt
wget https://github.com/greenplum-db/gpdb/releases/download/6.17.6/open-source-greenplum-db-6.17.6-rhel7-x86_64.rpm

# 开始安装,默认会自动把需要的依赖给安装上
# 也可以参考：https://github.com/greenplum-db/gpdb/blob/master/README.CentOS.bash
# 先安装好依赖，再执行
# rpm -Uvh open-source-greenplum-db-6.17.6-rhel7-x86_64.rpm

yum install -y open-source-greenplum-db-6.17.6-rhel7-x86_64.rpm
```
+ 默认会安装到：`/usr/local/greenplum-db`
+ 添加到环境变量

```
echo 'export PATH=/usr/local/greenplum-db/bin:$PATH' >>/etc/profile
```

#### 2、创建用户并授权

```
# 添加用户 gpadmin
useradd gpadmin

# 给gpamdin 设置密码,远程连接数据库需要用到
passwd gpadmin

chown -R gpadmin /usr/local/greenplum*
chgrp -R gpadmin /usr/local/greenplum*

# 切换到 gpadmin
su gpadmin

# 创建后面需要存放的数据目录
mkdir -p /data/gpdata/master
mkdir -p /data/gpdata/primary
mkdir -p /data/gpdata/mirror 
```

#### 3、设置gpadmin用户的环境变量
+ 进入`/home/gpadmin`目录下，分别在`.bash_profile`和`.bashrc` 添加如下配置

```
source /usr/local/greenplum-db/greenplum_path.sh
export MASTER_DATA_DIRECTORY=/data/gpdata/master/gpseg-1
export PGPORT=5432
export PGUSER=gpadmin
export PGDATABASE=gpdb
```

+ 执行命令，使上面的配置生效：`source .bash_profile .bashrc`

#### 4、添加节点服务器文件
+ 本例是单机，故只需要写一个,新增文件`seg_hosts`，执行如下命令

```bash
cat >/home/gpadmin/seg_hosts<<EOF
master205
EOF
```

#### 5、设置ssh免密登录

```bash
# 执行之后，一路回车即可
ssh-keygen
ssh-copy-id master205
gpssh-exkeys -f /home/gpadmin/seg_hosts
```

### 三、初始化数据库
+ 准备工作都差不多了

#### 1、复制配置文件

```bash
mkdir -p /home/gpadmin/conf

# 复制配置文件
cp /usr/local/greenplum-db/docs/cli_help/gpconfigs/gpinitsystem_config /home/gpadmin/conf/initGp
```

+ 修改如下内容：

```
declare -a DATA_DIRECTORY=(/data/gpdata/primary)
MASTER_HOSTNAME=master205
MASTER_DIRECTORY=/data/gpdata/master
MASTER_PORT=5432
MIRROR_PORT_BASE=7000
DATABASE_NAME=gpdb
declare -a MIRROR_DATA_DIRECTORY=(/data/gpdata/mirror)
MACHINE_LIST_FILE=/home/gpadmin/seg_hosts
```

+ 大致如下：

![](conf.png)

#### 2、执行初始化命令

```bash
# 因为已经设置环境变量了
gpinitsystem -c /home/gpadmin/conf/initGp

# 连接
psql -p 5432


#正常启动
gpstart 
#正常关闭
gpstop 
#快速关闭
gpstop -M fast 
#重启
gpstop –r 
# 重新加载配置
gpstop -u
```


#### 3、远程连接配置
+ 修改`pg_hba.conf` 配置，执行如下：

```
# 添加配置
echo 'host all  gpadmin    0.0.0.0/0    md5' >>/data/gpdata/master/gpseg-1/pg_hba.conf

# 重启服务
gpstop –r 
```


---
title: Centos 防火墙相关命令
date: 2017-05-08 21:39:55
tags: [干货, Linux]
categories: 网络运维
---
# 这里主要介绍centos7 和centos 6 的防火墙相关命令
#### 顺便说一下最小化安装centos7后 上不了网的问题

## Centos 6
```shell
#查看开放端口
service iptables status

#开启8080端口 ,下面是命令，
# 方法二是 修改 /etc/sysconfig/iptables 文件，添加： -A INPUT -p tcp -m tcp --dport 8080 -j ACCEPT
/sbin/iptables -I INPUT -p tcp --dport 8080 -j ACCEPT


#防火墙开启命令: 
service iptables start

#防火墙关闭命令: 
service iptables stop 

#永久关闭防火墙：
chkconfig iptables off

```
#### 可能发生的异常
```
具体的异常现象： 
#1.启动或者关闭防火墙没任何的提示
[root@ethnicity ~]# service iptables start
[root@ethnicity ~]# service iptables stop

#2.查看防火墙的状态直接提示模块未加载
[root@ethnicity ~]# service iptables status
iptables: Firewall modules are not loaded.
修复的方法：
 
modprobe  ip_tables  						#加载ip_tables模块
modprobe  iptable_filter 					#加载iptable_filter模块
[root@ethnicity ~]# lsmod | grep iptable 	#查看模块，有模块即解决了
iptable_filter          2173  0 
ip_tables               9567  1 iptable_filter
```
## Centos 7
### Centos7 的firewalld 取代了centos6 的iptables
#### 端口命令
```
#查看开放端口
firewall-cmd --list-ports

#开启端口 --permanent 是永久有效
firewall-cmd --zone=public --add-port=80/tcp --permanent 
#开启范围端口 8080 - 9090范围的端口
firewall-cmd  --zone=public  --add-port=8080-9090/tcp --permanent


#查看
firewall-cmd --zone= public --query-port=80/tcp 
# 删除
firewall-cmd --zone= public --remove-port=80/tcp --permanent
```
| 参数 | 描述 |
|---|---|
|--zone|作用域|
|--add-port=80/tcp |添加端口，格式为：端口/通讯协议|
|--permanent|设置永久生效，没有此参数重启后失效|
#### 防火墙命令
```
firewall-cmd --reload                  #重启firewall
firewall-cmd  --state                  #查看防火墙状态
systemctl start firewalld.service      #开启firewall
systemctl stop firewalld.service       #停止firewall
systemctl disable firewalld.service    #禁止firewall开机启动
```

##### 顺便说一下 最小化安装centos7后 上不了网的问题
```
vi /etc/sysconfig/network-scripts/ifcfg-ens33
# 将 ONBOOT=no 改为 ONBOOT=yes
# 重启网卡
service network restart
```
![](1503627585949070215.png)
##### 就像我们所知道的，“ifconfig”命令用于配置GNU/Linux系统的网络接口。它显示网络接口卡的详细信息，包括IP地址，MAC地址，以及网络接口卡状态之类。但是，该命令已经过时了，而且在最小化版本的RHEL 7以及它的克隆版本CentOS 7，Oracle Linux 7和Scientific Linux 7中也找不到该命令。
##### 我们可以用
```
ip addr
```
> 正文到此结束，谢谢观看

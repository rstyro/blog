---
title: 脚本一键安装MySQL
date: 2020-12-09 12:17:40
tags: [Linux, MYSQL]
categories: 网络运维
---
### 一、脚本一键安装MySQL
这里以安装MySQL5.7.30 版本为例。

### 二、准备工作
可提前下载好安装包，如果网速好也可以直接用wget在脚本中进行下载

#### 1、下载地址
+ 官网下载地址:[https://downloads.mysql.com/archives/community/](https://downloads.mysql.com/archives/community/)
+ 这里选择`5.7.30`版本，选择`Linux-Generic`,选择64位
+ 得到下载[地址](https://downloads.mysql.com/archives/get/p/23/file/mysql-5.7.30-linux-glibc2.12-x86_64.tar.gz)
+ 如下图

![](download.png)


#### 2、创建脚本
+ 在创建脚本之前把上面加载好的压缩包（`mysql-5.7.30-linux-glibc2.12-x86_64.tar.gz`）放在`/opt`路径下.
+ 创建脚本`install-mysql.sh`
+ 编辑如下内容：

```bash
#!/bin/bash
echo '==开始安装mysql=='
useradd mysql -s /sbin/nologin -M
tar -zxvf /opt/mysql-5.7.30-linux-glibc2.12-x86_64.tar.gz -C /opt/
mv /opt/mysql-5.7.30-linux-glibc2.12-x86_64 /usr/local/mysql-5.7.30
ln -s /usr/local/mysql-5.7.30  /usr/local/mysql
rpm -e --nodeps mariadb-libs
cat >/etc/my.cnf<<EOF
[mysqld]
basedir = /usr/local/mysql/
datadir = /usr/local/mysql/data
socket = /tmp/mysql.sock
server_id = 1
port = 3306
log_error = /usr/local/mysql/data/rstyro_mysql.err

[mysql]
socket = /tmp/mysql.sock
prompt = rstyro_mysql>
EOF
yum install libaio-devel -y
# rpm -ivh /opt/libaio-devel-0.3.12-1.i386.rpm
mkdir -p /usr/local/mysql/data
chown -R mysql.mysql /usr/local/mysql/
/usr/local/mysql/bin/mysqld --initialize-insecure --user=mysql --basedir=/usr/local/mysql/ --datadir=/usr/local/mysql/data
cat >/etc/systemd/system/mysqld.service<<EOF
[Unit]
Description=MySQL Server by dcs
Documentation=man:mysqld(8)
Documentation=http://dev.mysql.com/doc/refman/en/using-systemd.html
After=network.target
After=syslog.target
[Install]
WantedBy=multi-user.target
[Service]
User=mysql
Group=mysql
ExecStart=/usr/local/mysql/bin/mysqld --defaults-file=/etc/my.cnf
LimitNOFILE = 5000
EOF
systemctl start mysqld
systemctl enable mysqld
netstat -lntup|grep mysql
ps -ef|grep mysql|grep -v grep
echo 'export PATH=/usr/local/mysql/bin:$PATH' >>/etc/profile
source  /etc/profile
mysqladmin -u root password 'rstyro123456'
echo '==结束安装mysql=='
```

赋予脚本执行权限：`chmod +x install-mysql.sh`

#### 3、执行脚本
+ 账号密码是：root@rstyro123456
+ 执行脚本即可
```
./install-mysql.sh
```

**结束！！！**
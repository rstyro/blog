---
title: Centos7源码安装mysql5.7
date: 2017-05-20 23:49:28
updated: 2017-05-20 23:49:28
tags: [Linux, MYSQL]
categories: 网络运维
---
## 一、下载源码包
#### 官网：[https://dev.mysql.com/downloads/file/?id=471658](https://dev.mysql.com/downloads/file/?id=471658)
```
wget https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-5.7.19.tar.gz
```
## 二、解压
```
# -C 解压到指定目录： 如下命令，解压到 /opt/
tar -zxvf mysql-5.7.18.tar.gz -C /opt/
```

<!--more-->

## 三、安装运行环境
```
yum -y install gcc-c++ ncurses-devel cmake make perl  gcc autoconf automake zlib libxml libgcrypt libtool bison
```
> 还缺什么自己yum 安装一下就可以了。

## 四、编译
> 注意：下面的命令都要进入到刚解压的目录下执行

### (1)、cmake
```
cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mysql 
-DMYSQL_DATADIR=/usr/local/mysql/data 
-DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci 
-DMYSQL_TCP_PORT=3306 -DMYSQL_USER=mysql 
-DWITH_MYISAM_STORAGE_ENGINE=1 
-DWITH_INNOBASE_STORAGE_ENGINE=1 
-DWITH_ARCHIVE_STORAGE_ENGINE=1 
-DWITH_BLACKHOLE_STORAGE_ENGINE=1 
-DWITH_MEMORY_STORAGE_ENGINE=1 
-DDOWNLOAD_BOOST=1 
-DWITH_BOOST=/usr/local/boost
```
#### 参数解析
|参数|描述说明|
|----|-----|
|CMAKE_INSTALL_PREFIX|指定MySQL程序的安装目录，默认/usr/local/mysql|
|DEFAULT_CHARSET|指定服务器默认字符集，默认latin1|
|DEFAULT_COLLATION|指定服务器默认的校对规则，默认latin1_general_ci|
|ENABLED_LOCAL_INFILE|指定是否允许本地执行LOAD DATA INFILE，默认OFF|
|WITH_COMMENT|指定编译备注信息|
|WITH_xxx_STORAGE_ENGINE|指定静态编译到mysql的存储引擎，MyISAM，MERGE，MEMBER以及CSV四种引擎默认即被编译至服务器，不需要特别指定。|
|WITHOUT_xxx_STORAGE_ENGINE|指定不编译的存储引擎|
|SYSCONFDIR|初始化参数文件目录|
|MYSQL_DATADIR|数据文件目录|
|MYSQL_TCP_PORT|服务端口号，默认3306|
|MYSQL_UNIX_ADDR|socket文件路径，默认/tmp/mysql.sock|

> 如果这个cmake 失败，则需要删除CMakeCache.txt文件。命令：rm -f CMakeCache.txt
> mysql 5.7 要boost 1.59的，如果命令下载不下来，则自己手动安装。命令如下:

```
# 如果没有boost 目录则自己创建，命令：mkdir /usr/local/boost
cd /usr/local/boost
wget http://liquidtelecom.dl.sourceforge.net/project/boost/boost/1.59.0/boost_1_59_0.tar.gz
```


### (2)、make && make install
```
make && make install
```
> 如果上面的命令出错，又再进行编译之前，要clean 一下。命令：make clean

### (3)、可能发生的异常
> g++: internal compiler error: Killed (program cc1plus)
Please submit a full bug report,

#### 异常原因：可能是内存不足，导致的
#### 解决方法：设置2G交换分区来用
```
dd if=/dev/zero of=/swapfile bs=1k count=2048000 #获取要增加的2G的SWAP文件块
mkswap /swapfile     #创建SWAP文件
swapon /swapfile     #激活SWAP文件
swapon -s            #查看SWAP信息是否正确
echo "/var/swapfile swap swap defaults 0 0" >> /etc/fstab     #添加到fstab文件中让系统引导时自动启动
```
> 注意, swapfile文件的路径在/var/下,编译完后, 如果不想要交换分区了, 可以删除:

## 五.配置MySQL
#### 1、查看是否有mysql用户及用户组
```
cat /etc/passwd 查看用户列表
cat /etc/group  查看用户组列表
```
#### 2、没有就添加
```
#添加组，名为 mysql
groupadd mysql
#添加 mysql 用户到mysql 组
useradd -g mysql mysql
```
#### 3、设置权限并初始化MySQL系统授权表
```
cd /usr/local/mysql/
chown -R mysql .
chgrp -R mysql .
```
#### 4、启动
```
#以root初始化操作时要加–user=mysql参数，生成一个随机密码（注意保存登录时用）
cd /usr/local/mysql
bin/mysqld --initialize --user=mysql --basedir=/usr/local/mysql --datadir=/usr/local/mysql/data
```
##### 随机密码图如下：
![](1494762278916005105.png)

#### 5、初始化配置
##### 1、进入安装路径，将默认生成的my.cnf备份
```
cd /usr/local/mysql
mv /etc/my.cnf /etc/my.cnf.bak
```
> 注：在启动MySQL服务时，会按照一定次序搜索my.cnf，先在/etc目录下找，找不到则会搜索"$basedir/my.cnf"，在本例中就是 /usr/local/mysql/my.cnf，这是新版MySQL的配置文件的默认位置！

##### 2、配置my.cnf
```
vim /etc/my.cnf
```
> 我的my.cnf,如下:,这个可以根据自己的需求改，不改也是可以的。

```
[mysqld]
character_set_server=utf8mb4
init_connect='SET NAMES utf8'
lower_case_table_names=1
sql_mode=STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION
 
[client]
default-character-set=utf8mb4
```
## 六、添加服务

```
#配置mysql服务开机自动启动拷贝启动文件到/etc/init.d/下并重命令为mysql
cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysql

#增加执行权限
chmod 755 /etc/init.d/mysql
 
#检查自启动项列表中没有mysql这个，如果没有就添加mysql：
chkconfig --list mysql
chkconfig --add mysql
 
#设置MySQL在345等级自动启动
chkconfig --level 345 mysql on
 
#或用这个命令设置开机启动：
chkconfig mysql on
 
#mysql服务的启动/重启/停止
#启动mysql服务
service mysql start

#重启mysql服务
service mysql restart

#停止mysql服务
service mysql stop11
```
### 访问mysql数据库连接mysql， 输入初始化生成的随机密码
#### 然后修改密码
![](1494762422649025642.png)

```
#mysql创建用户
CREATE  USER  'username'@'localhost'   IDENTIFIEDBY   'password';

#授权
GRANT All privileges ON databasename.tablename   TO 'username'@'localhost'；

#刷新
flush privileges;
```

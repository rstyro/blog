---
title: Centos8安装MYSQL8
date: 2020-11-01 15:42:53
updated: 2020-11-01 15:42:53
tags: [Linux, MYSQL]
categories: 网络运维
---

### 一、下载安装包

+ 官网下载地址：[https://dev.mysql.com/downloads/mysql/](https://dev.mysql.com/downloads/mysql/)
+ 我的是64位系统,点击`download` 然后进入到新的页面
+ 在最下面选择`No thanks, just start my download.`得到下载地址。如下图所示

<!--more-->

![](download.png)

![](download2.png)

**命令行下载：**
```yml
# 下载
wget https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-8.0.22-linux-glibc2.12-x86_64.tar.xz

# 解压
tar -xvf mysql-8.0.22-linux-glibc2.12-x86_64.tar.xz

# 移动安装目录到/usr/local下,重命名为mysql
mv mysql-8.0.22-linux-glibc2.12-x86_64 /usr/local/mysql

```

### 二、MYSQL8配置
在上面解压就可以配置了。

#### 1、创建mysql用户组与用户
```
# 查看用户列表
cat /etc/passwd 
# 查看用户组列表
cat /etc/group  

#添加组，名为 mysql
groupadd mysql
#添加 mysql 用户到mysql 组
useradd -g mysql mysql
```

#### 2、给用户授权
```
# 进入mysql的解压目录
cd /usr/loca/mysql

# 创建一个存放数据目录，以后配置用到
mkdir data

# 给目录及其一下文件，赋予mysql组用户
chown -R mysql:mysql ./
```

#### 3、初始化数据库
```
bin/mysqld --initialize --user=mysql --basedir=/usr/local/mysql --datadir=/usr/local/mysql/data
```

不出意外是没有报错的，并且随机生成了`root`用户的密码，记得保存好，等会登陆需要，然后改密码。

![](password.png)

这样之后还没完呢，继续如下。

#### 3、配置my.cnf

+ 在`/etc`下新建一个`my.cnf`文件。命令：`vim /etc/my.cnf`。
+ 然后编辑内容如下：

```
[mysqld]
character-set-server=utf8mb4
basedir = /usr/local/mysql
datadir = /usr/local/mysql/data
socket = /tmp/mysql.sock
log-error = /usr/local/mysql/data/error.log
pid-file = /usr/local/mysql/mysql.pid
tmpdir = /tmp
port = 3306

max_allowed_packet=32M
default-authentication-plugin = mysql_native_password

log_bin_trust_function_creators = ON
sql_mode=NO_ENGINE_SUBSTITUTION,STRICT_TRANS_TABLES

[client]
default-character-set=utf8mb4
```

+ 上面我修改了数据库编码为`utf8mb4`。
+ 并且修改了mysql8的默认密码加密方式为：`mysql_native_password`。
+ MYSQL8默认的加密方式是：`caching_sha2_password`
+ 这里注意一点就是，这个更改的加密方式只对后来新增的用户有影响。
+ 也就是说root用户还是用的`caching_sha2_password`。后面有修改密码的方法。
+ 根据自己的需求，加或者删配置。


### 三、配置服务
基本上都准备好了，在配置一下服务就可以使用了。命令如下：

#### 1、配置本地环境
配置一下环境，`vim /etc/profile`，在最后添加如下：
```
export PATH=$PATH:/usr/local/mysql/bin:/usr/local/mysql/lib
```
然后，保存退出。立即生效：`source /etc/profile`。

#### 2、配置服务命令
```yml
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
```

这样mysql的服务就添加好了

#### 3、MYSQL启动命令
上面配置好就可以启动了。
```yml
#mysql服务的启动/重启/停止
#启动mysql服务
service mysql start

#重启mysql服务
service mysql restart

#停止mysql服务
service mysql stop
```

#### 4、重置root用户密码

+ 使用如上的命令`service mysql start`，启动mysql.
+ 登陆到mysql控制台

```
mysql -u root -p
```

+ 然后输入上面的**初始化数据库**时生成的密码，如我的是：`i?2>r26eL;K>`。
+ 这个密码是随机生成的，你要输入你自己的。
+ 当你第一次访问的时候，是需要修改密码的，不然就会报错，提示你重置密码。

![](resetpwd.png)

```
alter user 'root'@'localhost' identified by 'root';
```

#### 5、添加mysql用户
```yml
#mysql创建用户
CREATE  USER  'username'@'localhost'  IDENTIFIEDBY   'password';

#授权
GRANT ALL privileges ON databasename.tablename   TO 'username'@'localhost'；

#刷新
flush privileges;
```

#### 6、修改密码
修改mysql用户的密码。
##### 5.7版本之前的
```
mysql> update user set password=password("新密码") where user="root";
mysql> flush privileges;
mysql> quit
```

##### 5.7版本之后的
```yml
# 方法1
mysql> alter user "root"@"localhost" identified by "新密码"; 
# 方法2，默认的mysql8就是这个，但是如果你改了验证方式就不行。
mysql> update user set authentication_string=password("新密码") where user="root"; 
# 方法3，这个就是指定密码加密方式的。
mysql> alter user "root"@"localhost" identified with mysql_native_password by "新密码";
# 刷新
mysql> flush privileges;
mysql> quit
```

这样就结束了，可以玩了。

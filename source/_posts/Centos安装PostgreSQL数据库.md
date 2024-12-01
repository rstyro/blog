---
title: Centos安装PostgreSQL数据库
date: 2022-01-08 15:35:32
updated: 2022-01-08 15:35:32
tags: [PostgreSQL,Linux]
categories: 开发工具
---

### 一、前言

- 好久没写文章了，也有小段时间没学习了。
- 刚好公司用到 PostgreSQL ,周末来学习一波

### 二、PostgreSQL简介
- PostgreSQL是一种特性非常齐全的自由软件的对象-关系型数据库管理系统，是以加州大学计算机系开发的POSTGRES，PostgreSQL支持大部分的SQL标准并且提供了很多其他现代特性， 如：复杂查询、外键、触发器、视图、事务完整性、多版本并发控制等。同样，PostgreSQL也可以用许多方法扩展，例如通过增加新的数据类型、函数、操作符、聚集函数、索引方法、过程语言等。另外，因为许可证的灵活，任何人都可以以任何目的免费使用、修改和分发PostgreSQL。

**优点：**

<!--more-->

- 操作系统支持： WINDOWS、Linux、UNIX、MAC OS X、BSD。
- 支持ACID、关联完整性、数据库事务、Unicode多国语言。
- 支持R-/R+tree索引、哈希索引、反向索引、部分索引、Expression 索引、GiST、GIN（用来加速全文检索）
>从8.3版本开始支持位图索引。



**受欢迎程度**
- 自从MySQL被Oracle收购以后，PostgreSQL逐渐成为开源关系型数据库的首选。
- 因为开源，所以很多国产数据库都是基于它开发的，比如Greenplum数据库
- 而且PostgreSQL在数据库排名也是挺靠前的，使用的人越来越多了

![](rank.png)

> 来自网站： https://db-engines.com/en/ranking



### 三、安装PostgreSQL
- 官网地址：[https://www.postgresql.org/download/](https://www.postgresql.org/download/)
- 中文文档：[http://www.postgres.cn/v2/document](http://www.postgres.cn/v2/document)

> PostgreSQL 数据库写着太长了，以下简称 PG 数据库，哈哈



#### 1、Centos7 安装PG数据库
- PG 支持很多系统，本文主要学习Linux 系统下的Centos7 安装，Centos算是常用的服务器系统
- Centos7安装有两种方式，一种是直接使用YUM安装，一种使用源码安装。

##### ①、YUM安装
- 访问网址：[https://www.postgresql.org/download/linux/redhat/](https://www.postgresql.org/download/linux/redhat/)
- 选择你要安装的版本，然后执行官方给出的命令脚本即可，如下：

![](yum.png)

- 脚本如下：

```bash
# 安装yum 源
sudo yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
# 安装PG
sudo yum install -y postgresql13-server

# 初始化数据库
sudo /usr/pgsql-13/bin/postgresql-13-setup initdb
# PG数据库开机自启动
sudo systemctl enable postgresql-13
# 启动PG数据库
sudo systemctl start postgresql-13
```

- 上面命令执行完之后，就可以使用PG数据库了。
- 默认的安装目录是：`/usr/pgsql-13/`,数据目录在：`/var/lib/pgsql/13/data/`
- 安装完毕后，系统会创建一个数据库超级用户 `postgres`，密码随机，但是psql可以连接。
- 执行 `psql` 连接数据库，但是需要切换到 `postgres` 用户。

![](psql.png)


**修改postgres的默认密码：**
- **方式一：**
	- 1、操作系统切换到`postgres`用户，执行、`psql` 进入控制台。
	- 2、然后执行：`\password`，然后按提示输入你要修改的密码即可。
- 方式二：
	- 1、操作系统切换到`postgres`用户，执行、`psql` 进入控制台。
	- 2、执行如下即可：

```bash
# 切换到postgres 库
\c postgres

# 修改postgres 用户的密码
alter user postgres with PASSWORD 'yourPassword';
```


![](pwd.png)


**还有其他命令**

- 如，关闭重启服务，如下：
```bash
# 重启PG数据库
sudo systemctl restart postgresql-13
# 关闭PG数据库
sudo systemctl stop postgresql-13
```
- YUM安装到这基本就结束了


##### ②、源码安装
- 访问官网地址：[https://www.postgresql.org/ftp/source/v13.5/](https://www.postgresql.org/ftp/source/v13.5/)
- 下载对应的版本，我这边还是下载13 的版本

```bash

# 下载安装包
wget --no-check-certificate  https://ftp.postgresql.org/pub/source/v13.5/postgresql-13.5.tar.gz

# 解压安装包，到 /opt
tar -zxvf postgresql-13.5.tar.gz -C /opt

# 安装依赖
yum install -y readline-devel zlib-devel make gcc

# 创建postgres 管理员用户其组
groupadd postgres
useradd -g postgres postgres

# 进入解压的安装目录
cd /opt/postgresql-13.5

# 配置参数，安装到 /usr/local/postgresql-13 目录
./configure --prefix=/usr/local/postgresql-13

# 编译并安装
make && make install
```

**Ⅰ、配置postgres用户环境变量**
- 编辑postgres用户的 `.bash_profile`文件

```bash
vim /home/postgres/.bash_profile


# 在文件末尾添加如下配置
export PGHOME=/usr/local/postgresql-13
export PGDATA=/postgresql/data
export PATH=$PATH:$PGHOME/bin:$PGDATA
```
- 其中 `/postgresql/data` 是PG数据库的存放数据目录

**Ⅱ、初始化数据库**
- 开始初始化数据库

```bash
# 创建PG数据库的数据目录
mkdir -p /postgresql/data

# 修改权限
chown -R postgres:postgres /postgresql

# 切换到postgres
su - postgres

# 初始化PG数据库,-D 后面是初始化的数据目录（上面配置了，其实是可以不加-D的）
initdb -D /postgresql/data

# 然后按照提示启动PG数据库即可,-l 是日志写入到当前目录的logfile文件
pg_ctl -D /postgresql/data -l logfile start

```
- 然后就可以执行 `psql` 登陆到控制台了，后面的操作就可以yum按照一样了。

**常用命令：**

```bash
pg_ctl start
pg_ctl restart
pg_ctl stop

# -m 是一个关闭的模式，有3钟可以选择，可通过： pg_ctl --help 查看参数含义
pg_ctl stop -mf
```


#### 2、PG数据库配置远程连接
- 需要进入到PG数据库的数据目录
- 修改`pg_hba.conf` 和 `postgresql.conf` 配置文件

**1、修改pg_hba.conf**

```bash
# 新增如下,把192.168.32.1 改成你所在的网段即可
# 或者也可以直接设置为： 0.0.0.0/0 就是所有IP 都可以访问

host    all     all    192.168.32.1/32    trust
```

![](pg_hba.png)

**2、修改postgresql.conf**
- 把 `listen_addresses='localhost'` 改成 `listen_addresses='*'` 
- 如下图所示，两个文件都修改了之后，重启一下服务：`pg_ctl restart`

![](listen.png)



> 记得把系统防火墙放开，默认的PG数据库端口是 5432



![](connect.png)

#### 3、常用命令
+ 列出一些控制台常用的命令吧

```bash
# 设置密码
\password

# 退出命令
\q

# 查看SQL命令的解析，比如：\h grant
\h

# 查看psql命令列表
\?

# 切换数据库
\c [database_name]

# 切换用户，记得中间有个 - 
\c - [username]

# 列出当前数据库的所有表格
\d

# 列出某张表的结构
\d [table_name]

# 列出所有用户
\du 

# 创建表，并设置 id 自增
create table test(id serial primary key,name varchar(50));

# 显示执行语句的时间
\timeing


#  创建序列
CREATE SEQUENCE voltask_id_seq START 1;
# 更新序列
alter SEQUENCE doi_record_id_seq restart WITH 1;

#  在字段的默认值设置：
nextval('voltask_id_seq')
nextval('check_datakey_id_seq')
nextval('check_machining_id_seq')


#  查询是否锁表了
select oid from pg_class where relname='可能锁表了的表'
#  pid 是进程
select pid from pg_locks where relation='上面查出的oid'
#  如果查询到了结果，表示该表被锁 则需要释放锁定
select pg_cancel_backend(上面查到的pid);

#  查看所有进程
select * from pg_stat_activity;
#  杀掉pid=2045的进程
select pg_terminate_backend(2045); 
```

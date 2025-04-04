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


### 四、Centos8一键脚本安装
- 可以把步骤写到脚本中，直接安装

```bash
#!/bin/bash

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# 预定义配置,密码搞复杂一点，不然修改不成功会报错，报错也问题不大吧，反正也是安装成功了
ROOT_PASS="rstyro@66DaShun.888"
MYSQL_CNF="/etc/my.cnf"

# 卸载MariaDB
echo -e "${GREEN}[1/8] 卸载现有MariaDB...${NC}"
sudo dnf remove -y mariadb-* > /dev/null 2>&1 || true

sudo dnf remove -y mysql80-community-release 2>/dev/null || true

# 添加MySQL仓库
echo -e "${GREEN}[2/8] 配置MySQL Yum仓库...${NC}"
sudo dnf install -y https://repo.mysql.com/mysql80-community-release-el8-7.noarch.rpm

# 清理缓存
sudo dnf clean all
sudo rm -rf /var/cache/dnf
sudo dnf makecache

# 禁用mysql模块，不校验mysql版本
sudo dnf module disable mysql

# 启用仓库
sudo dnf config-manager --enable mysql80-community


# 安装MySQL服务器
echo -e "${GREEN}[3/8] 安装MySQL服务器...${NC}"
sudo dnf install -y mysql-community-server 

# 启动MySQL服务
echo -e "${GREEN}[4/8] 启动MySQL服务...${NC}"
sudo systemctl start mysqld
sudo systemctl enable mysqld 

# 获取临时密码
echo -e "${GREEN}[5/8] 获取临时root密码...${NC}"
for i in {1..30}; do
  if [[ -f /var/log/mysqld.log ]] && sudo grep -q 'temporary password' /var/log/mysqld.log; then
    break
  fi
  sleep 2
done
TEMP_PASS=$(sudo grep 'temporary password' /var/log/mysqld.log | awk '{print $NF}')
if [[ -z "$TEMP_PASS" ]]; then
  echo -e "${RED}错误: 无法获取临时密码，请检查/var/log/mysqld.log${NC}"
  exit 1
fi

# 自动安全配置
echo -e "${GREEN}[6/8] 执行安全配置...${NC}"
mysql --connect-expired-password -u root -p"${TEMP_PASS}" <<EOF 2>/dev/null
ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PASS}';
CREATE USER 'root'@'%' IDENTIFIED WITH mysql_native_password BY '${ROOT_PASS}';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%';
FLUSH PRIVILEGES;
EOF

# 配置优化my.cnf
echo -e "${GREEN}[7/8] 配置my.cnf...${NC}"
sudo tee $MYSQL_CNF > /dev/null <<'EOF'
[mysqld]
# 网络配置
port=3306
bind-address=0.0.0.0

# 字符集设置
character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci

# 连接配置
max_connections=1000
wait_timeout=300
interactive_timeout=300

# 存储引擎
default-storage-engine=INNODB

# InnoDB配置
innodb_buffer_pool_size=1G
innodb_flush_log_at_trx_commit=2
innodb_log_file_size=256M

# 日志配置
slow_query_log=1
slow_query_log_file=/var/log/mysql-slow.log
long_query_time=2

# 其他优化
skip-name-resolve
log_bin_trust_function_creators=1
sql_mode=STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION

[client]
default-character-set=utf8mb4
EOF

# 重启服务生效配置
sudo systemctl restart mysqld

# 防火墙配置
echo -e "${GREEN}[8/8] 配置防火墙...${NC}"
sudo firewall-cmd --permanent --add-port=3306/tcp > /dev/null
sudo firewall-cmd --reload > /dev/null

# 验证安装
echo -e "${GREEN}验证安装...${NC}"
if mysql -u root -p"${ROOT_PASS}" -e "SELECT 1" >/dev/null 2>&1; then
  echo -e "${GREEN}√ MySQL 8安装成功"
  echo -e "Root密码: ${ROOT_PASS}"
  echo -e "连接命令: mysql -u root -p -h [服务器IP]"
else
  echo -e "${RED}× 安装验证失败，请检查日志${NC}"
fi

```

这样就结束了，可以玩了。

---
title: Docker（六）、启动mysql时自动执行脚本
date: 2018-01-18 17:34:52
tags: [Docker]
categories: 开发工具
---
# docker 启动mysql时自动执行脚本
##### 上次已经运行了一个 tomcat 我们还需要一个数据库，docker 运行一个mysql 是很简单的比如
```
docker run -d --name testmysql -p 3306:3306 -e MYSQL_ROOT_PASSWORD=root -e MYSQL_DATABASE=admin mysql
```
+ MYSQL_ROOT_PASSWORD=root，指定 root 用户名密码 root
+ MYSQL_DATABASE=admin 容器运行时创建一个数据库名为 admin
但是这样只能获得一个空的数据库，我们需要有数据的数据库，so

#### 其实mysql的官方镜像是支持这个能力的，在容器启动的时候自动执行指定的sql脚本或者shell脚本，我们一起来看看[mysql官方镜像的Dockerfile](https://github.com/docker-library/mysql/blob/7a850980c4b0d5fb5553986d280ebfb43230a6bb/8.0/Dockerfile)，如下图：
![](/Docker（六）、启动mysql时自动执行脚本/75031.png)

#### 已经设定了ENTRYPOINT，里面会调用/entrypoint.sh这个脚本，我们把镜像pull到本地，再用docker run启动起来，进入容器看看里面的entrypoint.sh这个脚本的内容，有一段内容就是从固定目录下遍历所有的.sh和.sql后缀的文件，然后执行，如下图：
![](/upload/images/73590.png)
##### 搞清楚原理了，现在我们来实战吧

## 一、创建 Dockerfile 文件 
```
# mysql 官方镜像
FROM docker.io/mysql

#作者
MAINTAINER rstyro <rstyro@gmail.com>

#定义会被容器自动执行的目录
ENV AUTO_RUN_DIR /docker-entrypoint-initdb.d

#定义初始化sql文件
ENV INIT_SQL admin.sql

#把要执行的sql文件放到/docker-entrypoint-initdb.d/目录下，容器会自动执行这个sql
COPY ./$INIT_SQL $AUTO_RUN_DIR/

#给执行文件增加可执行权限
RUN chmod a+x $AUTO_RUN_DIR/$INIT_SQL

```

## 二、admin.sql 文件
```
DROP DATABASE IF EXISTS `admin`;
CREATE DATABASE `admin` character set utf8mb4;
USE `admin`;

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for `sys_login`
-- ----------------------------
DROP TABLE IF EXISTS `sys_login`;
CREATE TABLE `sys_login` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `last_login_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后登录时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=73 DEFAULT CHARSET=utf8mb4;


-- ----------------------------
-- Table structure for `sys_menu`
-- ----------------------------
DROP TABLE IF EXISTS `sys_menu`;
CREATE TABLE `sys_menu` (
  `menu_id` int(11) NOT NULL,
  `parent_id` int(11) DEFAULT NULL,
  `menu_name` varchar(50) DEFAULT NULL,
  `menu_url` varchar(50) DEFAULT '#',
  `menu_type` enum('2','1') DEFAULT '2' COMMENT '1 -- 系统菜单，2 -- 业务菜单',
  `menu_icon` varchar(50) DEFAULT '#',
  `sort_num` int(11) DEFAULT '1',
  `user_id` int(11) DEFAULT '1' COMMENT '创建这个菜单的用户id',
  `is_del` int(11) DEFAULT '0' COMMENT '1-- 删除状态，0 -- 正常',
  `update_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `create_time` datetime DEFAULT NULL,
  PRIMARY KEY (`menu_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Records of sys_menu
-- ----------------------------
INSERT INTO `sys_menu` VALUES ('1', '0', '系统管理', '#', '1', 'fa fa-gears', '1', '1', '0', '2017-09-08 16:15:24', '2017-09-07 14:52:41');
INSERT INTO `sys_menu` VALUES ('2', '1', '菜单管理', 'menu/list', '1', '#', '1', '1', '0', '2017-09-12 11:28:09', '2017-09-07 14:52:41');
INSERT INTO `sys_menu` VALUES ('3', '1', '角色管理', 'role/list', '1', null, '2', '1', '0', '2017-09-07 17:58:52', '2017-09-07 14:52:41');
INSERT INTO `sys_menu` VALUES ('4', '1', '用户管理', 'user/list', '1', '', '3', '1', '0', '2017-09-12 09:44:48', '2017-09-07 14:52:41');
INSERT INTO `sys_menu` VALUES ('5', '0', '业务菜单', '#', '2', 'fa fa-tasks', '2', '1', '0', '2017-09-07 14:53:33', '2017-09-07 14:52:41');
INSERT INTO `sys_menu` VALUES ('6', '5', '随便添加的子菜单', 'page/t4', '2', '', '1', '1', '0', '2017-09-14 15:45:28', '2017-09-07 14:52:41');

-- ----------------------------
-- Table structure for `sys_role`
-- ----------------------------
DROP TABLE IF EXISTS `sys_role`;
CREATE TABLE `sys_role` (
  `role_id` int(11) NOT NULL AUTO_INCREMENT,
  `role_name` varchar(50) DEFAULT NULL COMMENT '角色名',
  `role_desc` varchar(255) DEFAULT NULL,
  `rights` varchar(255) DEFAULT '0' COMMENT '最大权限的值',
  `add_qx` varchar(255) DEFAULT '0',
  `del_qx` varchar(255) DEFAULT '0',
  `edit_qx` varchar(255) DEFAULT '0',
  `query_qx` varchar(255) DEFAULT '0',
  `user_id` varchar(10) DEFAULT NULL,
  `create_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`role_id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Records of sys_role
-- ----------------------------
INSERT INTO `sys_role` VALUES ('1', '管理员', '管理员权限', '1267650600228229401496703205375', '1', '1', '126', '126', '1', '2017-09-12 15:38:56');
INSERT INTO `sys_role` VALUES ('2', 'tyro', '随便创建的随便创建的随便创建的随便创建的随便创建的随便创建的随便创建的随便创建的随便创建的随便创建的', '94', '2', '1', '4', '126', '1', '2017-09-12 15:44:06');
INSERT INTO `sys_role` VALUES ('3', 'test', '是测试角色这个是测试角色这个是测试角色这个是测试角色这个是测试角色', '382', '382', '382', '382', '126', '1', '2017-09-12 15:39:28');
INSERT INTO `sys_role` VALUES ('4', '查看', '可以查看所有的东西', '126', '0', '0', '0', '126', '1', '2017-09-14 17:17:17');

-- ----------------------------
-- Table structure for `sys_user`
-- ----------------------------
DROP TABLE IF EXISTS `sys_user`;
CREATE TABLE `sys_user` (
  `user_id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(50) DEFAULT NULL,
  `nick_name` varchar(50) DEFAULT NULL,
  `password` varchar(50) DEFAULT NULL,
  `pic_path` varchar(200) DEFAULT '/images/logo.png',
  `status` enum('unlock','lock') DEFAULT 'unlock',
  `create_time` datetime DEFAULT NULL,
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Records of sys_user
-- ----------------------------
INSERT INTO `sys_user` VALUES ('1', 'admin', '管理员', 'd033e22ae348aeb5660fc2140aec35850c4da997', 'http://www.lrshuai.top/upload/user/20170612/05976238.png', 'unlock', '2017-08-18 13:57:32');
INSERT INTO `sys_user` VALUES ('2', 'tyro', 'tyro', '481c63e8b904bb8399f1fc1dfdb77cb40842eb6f', '/upload/show/user/82197046.png', 'unlock', '2017-09-12 14:03:39');
INSERT INTO `sys_user` VALUES ('3', 'asdf', 'asdf', '3da541559918a808c2402bba5012f6c60b27661c', '/upload/show/user/85610497.png', 'unlock', '2017-09-13 14:49:10');

-- ----------------------------
-- Table structure for `sys_user_role`
-- ----------------------------
DROP TABLE IF EXISTS `sys_user_role`;
CREATE TABLE `sys_user_role` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `role_id` int(11) DEFAULT NULL,
  `create_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Records of sys_user_role
-- ----------------------------
INSERT INTO `sys_user_role` VALUES ('1', '1', '1', '2017-08-18 14:45:43');
INSERT INTO `sys_user_role` VALUES ('2', '2', '3', '2017-09-08 17:12:58');
INSERT INTO `sys_user_role` VALUES ('13', '3', '3', '2017-09-14 14:30:02');

```
## 三、生成新的mysql镜像
```
docker build -t adminmysql .
```

## 四、启动
#### 现在启动是可以的，但是呢有一个问题，因为mysql的编码默认是瑞典latin1，我们要把改成utf8 或者utfmb4
#### my.cnf
```
[mysqld]
character_set_server=utf8mb4
init_connect='SET NAMES utf8'
wait_timeout=1814400
interactive_timeout=604800

sql_mode=NO_ENGINE_SUBSTITUTION,STRICT_TRANS_TABLES
[client]
default-character-set=utf8mb4

```
##### 上面的配置就和mysql 的配置是一样的，可以按照你的需求来配，下面就是启动容器的命令
```
# 默认密码： root,我们要挂载一个my.cnf 的配置文件
docker run --name admin_db -d -p 3306:3306 -e MYSQL_ROOT_PASSWORD=root -v /root/docker-mysql/my.cnf:/etc/mysql/my.cnf adminmysql
```
### 查看容器数据库是否有数据
![](/Docker（六）、启动mysql时自动执行脚本/52346.png)
#### 不错是有数据的。
我的命令过程
![](/Docker（六）、启动mysql时自动执行脚本/29401.png)

## 搞定收工

## 参考链接：[https://blog.csdn.net/boling_cavalry/article/details/71055159](https://blog.csdn.net/boling_cavalry/article/details/71055159)
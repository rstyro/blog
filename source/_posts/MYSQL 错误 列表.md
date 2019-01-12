---
title: MYSQL 错误 列表
date: 2017-05-09 21:44:18
tags: [MYSQL]
categories: 数据库
---
## 一、错误如下：

> [Err] 1055 - Expression #1 of ORDER BY clause is not in GROUP BY clause and contains nonaggregated column 'information_schema.
PROFILING.SEQ' which is not functionally dependent on columns in GROUP BY clause; 
this is incompatible with sql_mode=only_full_group_by

### 解决方法：
##### 在/etc/my.cnf 的最后面加一句话
```
sql_mode=STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION
```
####保存退出：
####重启mysql服务器，搞定

## 二、错误如下：
> mysql: [Warning] Using a password on the command line interface can be insecure.
ERROR 1840 (HY000) at line 24: @@GLOBAL.GTID_PURGED can only be set when @@GLOBAL.GTID_EXECUTED is empty.

#### 报这个错误的时候是再当你导入数据的时候报的，
### 解决方法：
#### 1、进入mysql 模式，运行
```
reset master;
```
##### 这个比较麻烦的是，当你导入数据的时候，都要 reset master 一次。
#### 2、就是当你导出数据的时候加参数 ：--set-gtid-purged=OFF,例如
```
# 导出数据
mysqldump -h 192.168.1.1 -u root -ppassword --set-gtid-purged=OFF daname > db.sql
# 导入数据
mysql -u root -ppassword dbname < db.sql
```

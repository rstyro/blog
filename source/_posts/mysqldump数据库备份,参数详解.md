---
title: mysqldump数据库备份,参数详解
date: 2017-07-03 16:13:12
tags: [MYSQL]
categories: 数据库
---
## 一、 mysqldump是mysql用于转存储数据库的实用程序。它主要产生一个SQL脚本，其中包含从头重新创建数据库所必需的命令CREATE TABLE INSERT等。

#### 1、导出数据库为dbname所有表结构及表数据
```
mysqldump -u root -pdbpasswd  dbname > db.sql //密码为dbpasswd,注意的是-p后面不能加空格,db.sql就是生成的脚本，可以改成你要生成的文件
mysqldump -u root -p  dbname > db.sql//回车的时候再输入密码
```
#### 2、导出数据库为dbname某张表(test)结构及表数据
```
# 如果只想导表结构而不要数据则，不加参数  -d
mysqldump -uroot -pdbpasswd dbname test > db.sql
```

#### 3、导出数据库为dbname的表结构
```
mysqldump -uroot -pdbpasswd -d dbname >db.sql
```
#### 4、导出数据库为dbname某张表(test)结构
```
mysqldump -uroot -pdbpasswd -d dbname test>db.sql
```

#### 5、如果要备份某个MySQL主机上的所有数据库可以使用--all-databases选项，如下：
```
mysqldump  -uroot -p --all-databases > test.dump
```

## 二、DEMO 如下：
![](/mysqldump数据库备份,参数详解/1499159395684062812.png)

> 出现一个警告是说把密码放在命令行会不安全，
> 但文件还是保存下来了

![](/mysqldump数据库备份,参数详解/1499159652299097894.png)

## 三、导入文件
#### 有导入命令，那是不是也有导入命令呢？
#### 那是肯定的,命令如下
##### 1、shell 命令导入
```
mysql -u root -p dbname < db.sql
```
##### 2、在mysql 中导入
```
use dbname;
source db.sql
```

## 四、下面介绍mysqldump 的其他参数
#### --all-tablespaces  , -Y
##### 导出全部表空间。
```
mysqldump  -uroot -p --all-databases --all-tablespaces > db.sql
```

#### --no-tablespaces  , -y
##### 不导出任何表空间信息。
```
mysqldump  -uroot -p --all-databases --no-tablespaces > db.sql
```

#### --add-drop-database
##### 每个数据库创建之前添加drop数据库语句。
```
mysqldump  -uroot -p --all-databases --add-drop-database > db.sql
```

#### --add-drop-table
##### 每个数据表创建之前添加drop数据表语句。(默认为打开状态，使用--skip-add-drop-table取消选项)
```
mysqldump  -uroot -p --all-databases > db.sql (默认添加drop语句)
mysqldump  -uroot -p --all-databases –skip-add-drop-table  > db.sql (取消drop语句)
```

#### --add-locks
##### 在每个表导出之前增加LOCK TABLES并且之后UNLOCK  TABLE。(默认为打开状态，使用--skip-add-locks取消选项)
```
mysqldump  -uroot -p --all-databases  > db.sql (默认添加LOCK语句)
mysqldump  -uroot -p --all-databases –skip-add-locks  > db.sql (取消LOCK语句)
```

#### --allow-keywords
##### 允许创建是关键词的列名字。这由表名前缀于每个列名做到。
```
mysqldump  -uroot -p --all-databases --allow-keywords > db.sql
```

#### --apply-slave-statements
##### 在'CHANGE MASTER'前添加'STOP SLAVE'，并且在导出的最后添加'START SLAVE'。
```
mysqldump  -uroot -p --all-databases --apply-slave-statements > db.sql
```

#### --character-sets-dir
##### 字符集文件的目录
```
mysqldump  -uroot -p --all-databases  --character-sets-dir=/usr/local/mysql/share/mysql/charsets > db.sql
```
#### --comments
##### 附加注释信息。默认为打开，可以用--skip-comments取消
```
mysqldump  -uroot -p --all-databases  > db.sql (默认记录注释)
mysqldump  -uroot -p --all-databases --skip-comments > db.sql  (取消注释)
```

#### --compatible
##### 导出的数据将和其它数据库或旧版本的MySQL 相兼容。值可以为ansi、mysql323、mysql40、postgresql、oracle、mssql、db2、maxdb、no_key_options、no_tables_options、no_field_options等，要使用几个值，用逗号将它们隔开。它并不保证能完全兼容，而是尽量兼容。
```
mysqldump  -uroot -p --all-databases --compatible=ansi > db.sql
```

#### --compact
##### 导出更少的输出信息(用于调试)。去掉注释和头尾等结构。可以使用选项：--skip-add-drop-table  --skip-add-locks --skip-comments --skip-disable-keys
```
mysqldump  -uroot -p --all-databases --compact > db.sql
```

#### --complete-insert,  -c

##### 使用完整的insert语句(包含列名称)。这么做能提高插入效率，但是可能会受到max_allowed_packet参数的影响而导致插入失败。
```
mysqldump  -uroot -p --all-databases --complete-insert > db.sql
```

#### --compress, -C

##### 在客户端和服务器之间启用压缩传递所有信息
```
mysqldump  -uroot -p --all-databases --compress
```

#### --create-options,  -a

##### 在CREATE TABLE语句中包括所有MySQL特性选项。(默认为打开状态)
```
mysqldump  -uroot -p --all-databases > db.sql
```

#### --databases,  -B

##### 导出几个数据库。参数后面所有名字参量都被看作数据库名。
```
mysqldump  -uroot -p --databases test mysql > db.sql
```

#### -debug

##### 输出debug信息，用于调试。默认值为：d:t:o,/tmp/mysqldump.trace
```
mysqldump  -uroot -p --all-databases --debug > db.sql
mysqldump  -uroot -p --all-databases --debug=” d:t:o,/tmp/debug.trace” > db.sql
```

-#### -debug-check

##### 检查内存和打开文件使用说明并退出。
```
mysqldump  -uroot -p --all-databases --debug-check > db.sql
```

#### --debug-info

##### 输出调试信息并退出
```
mysqldump  -uroot -p --all-databases --debug-info > db.sql
```

#### --default-character-set

##### 设置默认字符集，默认值为utf8
```
mysqldump  -uroot -p --all-databases --default-character-set=latin1 > db.sql
```

#### --delayed-insert

##### 采用延时插入方式（INSERT DELAYED）导出数据
```
mysqldump  -uroot -p --all-databases --delayed-insert > db.sql
```

#### --delete-master-logs

##### master备份后删除日志. 这个参数将自动激活--master-data。
```
mysqldump  -uroot -p --all-databases --delete-master-logs > db.sql
```

#### --disable-keys

##### 对于每个表，用/*!40000 ALTER TABLE tbl_name DISABLE KEYS */;和/*!40000 ALTER TABLE tbl_name ENABLE KEYS */;语句引用INSERT语句。这样可以更快地导入dump出来的文件，因为它是在插入所有行后创建索引的。该选项只适合MyISAM表，默认为打开状态。

```
mysqldump  -uroot -p --all-databases  > db.sql
```

#### --dump-slave

##### 该选项将导致主的binlog位置和文件名追加到导出数据的文件中。设置为1时，将会以CHANGE MASTER命令输出到数据文件；设置为2时，在命令前增加说明信息。该选项将会打开--lock-all-tables，除非--single-transaction被指定。该选项会自动关闭--lock-tables选项。默认值为0。

```
mysqldump  -uroot -p --all-databases --dump-slave=1 > db.sql
mysqldump  -uroot -p --all-databases --dump-slave=2 > db.sql
```

#### --events, -E

##### 导出事件。

```
mysqldump  -uroot -p --all-databases --events > db.sql
```

#### --extended-insert,  -e

##### 使用具有多个VALUES列的INSERT语法。这样使导出文件更小，并加速导入时的速度。默认为打开状态，使用--skip-extended-insert取消选项。

```
mysqldump  -uroot -p --all-databases > db.sql
mysqldump  -uroot -p --all-databases--skip-extended-insert  > db.sql (取消选项)
```

#### --fields-terminated-by

##### 导出文件中忽略给定字段。与--tab选项一起使用，不能用于--databases和--all-databases选项
```
mysqldump  -uroot -p test test --tab=”/home/mysql” --fields-terminated-by=”#” > db.sql
```

#### --fields-enclosed-by

##### 输出文件中的各个字段用给定字符包裹。与--tab选项一起使用，不能用于--databases和--all-databases选项

```
mysqldump  -uroot -p test test --tab=”/home/mysql” --fields-enclosed-by=”#” > db.sql
```

#### --fields-optionally-enclosed-by

##### 输出文件中的各个字段用给定字符选择性包裹。与--tab选项一起使用，不能用于--databases和--all-databases选项

```
mysqldump  -uroot -p test test --tab=”/home/mysql”  --fields-enclosed-by=”#” --fields-optionally-enclosed-by  =”#” > db.sql
```

#### --fields-escaped-by

##### 输出文件中的各个字段忽略给定字符。与--tab选项一起使用，不能用于--databases和--all-databases选项

```
mysqldump  -uroot -p mysql user --tab=”/home/mysql” --fields-escaped-by=”#” > db.sql
```

#### --flush-logs

##### 开始导出之前刷新日志。

##### 请注意：假如一次导出多个数据库(使用选项--databases或者--all-databases)，将会逐个数据库刷新日志。除使用--lock-all-tables或者--master-data外。在这种情况下，日志将会被刷新一次，相应的所以表同时被锁定。因此，如果打算同时导出和刷新日志应该使用--lock-all-tables 或者--master-data 和--flush-logs。

```
mysqldump  -uroot -p --all-databases --flush-logs > db.sql
```

#### --flush-privileges

##### 在导出mysql数据库之后，发出一条FLUSH  PRIVILEGES 语句。为了正确恢复，该选项应该用于导出mysql数据库和依赖mysql数据库数据的任何时候。
```
mysqldump  -uroot -p --all-databases --flush-privileges > db.sql
```

#### --force

##### 在导出过程中忽略出现的SQL错误。
```
mysqldump  -uroot -p --all-databases --force > db.sql
```

#### --host, -h

##### 需要导出的主机信息

```
mysqldump  -uroot -p --host=localhost --all-databases > db.sql
```

## 还有一些应该不算太常用，就不写了


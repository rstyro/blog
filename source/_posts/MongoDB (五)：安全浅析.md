---
title: MongoDB (五)：安全浅析
date: 2017-10-24 12:09:43
updated: 2017-10-24 12:09:43
tags: [MongoDB]
categories: 数据库
---
# MongoDB 安全浅析
### MongoDB副本集默认会创建local、admin数据库，local数据库主要存储副本集的元数据，admin数据库则主要存储MongoDB的用户、角色等信息
### 当Mongod启用auth选项时，用户需要创建数据库帐号，访问时根据帐号信息来鉴权，而数据库帐号信息就存储在admin数据库下
## 一、角色
### 1、数据库用户角色
#### (a)、read
+ 提供对所有读取数据的权限

#### (b)、readWrite
+ 提供read角色的所有权限以及修改所有非系统集合的权限

<!--more-->


### 2、数据库管理角色
#### (a)、dbAdmin
提供执行管理任务的能力，如模式相关任务，索引，收集统计信息。此角色不授予用户和角色管理权限。
对非系统集合提供了一下操作：
+ bypassDocumentValidation
+ collMod
+ collStats
+ compact
+ convertToCapped
+ createCollection
+ createIndex
+ dbStats
+ dropCollection
+ dropDatabase
+ dropIndex
+ enableProfiler
+ reIndex
+ renameCollectionSameDB
+ repairDatabase
+ storageDetails
+ validate

#### (b)、dbOwner
+ 数据库所有者可以对数据库执行任何管理操作

#### (c)、userAdmin
+ 提供创建和修改数据库角色和用户的功能。在数据库上具有此角色的用户可以为该数据库的任何用户（包括其自身）分配任何角色或特权

#### (d)、root
+ 超级管理员

### 3、集群角色
#### (a)、clusterAdmin
+ 提供最大的集群管理访问

#### (b)、clusterManager
+ 在集群上提供管理和监控动作。具有该角色的用户可以访问config和local 数据库，其在分片和复制所使用的

#### (c)、clusterMonitor
+ 提供对监控工具的只读访问权限

#### (d)、hostManager
+ 提供监控和管理服务器的能力

### 4、备份角色
#### (a)、backup
+ 提供备份数据所需的权限

#### (b)、restore
+ 提供在`mongorestore`没有`--oplogReplay `选项或没有`system.profile`收集数据的情况下恢复数据所需的权限 

### 5、全数据库角色
> 版本V3.4更改

|角色|介绍说明|
|--|---|
|readAnyDatabase|提供相同的只读权限read，除了它适用 于群集中的所有其他数据库local和config数据库。该角色还为[listDatabases](https://docs.mongodb.com/manual/reference/privilege-actions/#listDatabases)整个群集提供了 行动。有关角色授予的特定权限，请参阅 [readAnyDatabase](https://docs.mongodb.com/manual/reference/built-in-roles/#readAnyDatabase)。在3.4版中更改：3.4之前，readAnyDatabase包含local 和config数据库。要为数据库提供read权限，请在local数据库中使用admin 数据库中的read角色创建一个用户local 。另请参阅[clusterManager](https://docs.mongodb.com/manual/reference/built-in-roles/#clusterManager)访问config和local数据库的角色。|
|readWriteAnyDatabase|提供相同的读取和写入权限 readWrite，除了它适用于群集中的所有其他 数据库local和config数据库。该角色还为listDatabases整个群集提供了行动。有关角色授予的特定权限，请参阅 [readWriteAnyDatabase](https://docs.mongodb.com/manual/reference/built-in-roles/#readWriteAnyDatabase)。在3.4版中更改：3.4之前，readWriteAnyDatabase包含 local和config数据库。要为数据库提供readWrite 权限，请在local数据库中使用admin数据库中的readWrite角色 创建一个用户 local。|
|userAdminAnyDatabase|提供与用户管理操作相同的访问权限 userAdmin，除了适用于群集中的所有其他 数据库local和config数据库。由于该[userAdminAnyDatabase](https://docs.mongodb.com/manual/reference/built-in-roles/#userAdminAnyDatabase)角色允许用户向任何用户（包括其自身）授予任何权限，该角色也间接提供超级用户访问权限。有关角色授予的特定权限，请参阅 [userAdminAnyDatabase](https://docs.mongodb.com/manual/reference/built-in-roles/#userAdminAnyDatabase)。在3.4版中更改：3.4之前，userAdminAnyDatabase包含 local和config数据库。|
|dbAdminAnyDatabase|提供与数据库管理操作相同的访问权限dbAdmin，除了适用于群集中的所有其他 数据库local和config数据库。该角色还为listDatabases整个群集提供了行动。有关角色授予的特定权限，请参阅 [dbAdminAnyDatabase](https://docs.mongodb.com/manual/reference/built-in-roles/#dbAdminAnyDatabase)。在3.4版中更改：3.4之前，dbAdminAnyDatabase包含 local和config数据库。要为数据库提供dbAdmin 权限，请在local数据库中使用admin数据库中的dbAdmin角色 创建一个用户 local。另请参阅clusterManager访问config和local数据库的角色。|



## 二、创建自定义角色
### 1、语法：`db.createRole(role, writeConcern)`
|参数|类型|描述|
|--|--|
|role|document|	包含角色名称和角色定义的文档。|
|writeConcern|document|	可选的。写入的程度适用于此操作。该writeConcern文档使用与[getLastError](https://docs.mongodb.com/manual/reference/command/getLastError/#dbcmd.getLastError)命令相同的字段。|

### 2、role 格式如下：
```
{
  role: "<name>",
  privileges: [
     { resource: { <resource> }, actions: [ "<action>", ... ] },
     ...
  ],
  roles: [
     { role: "<role>", db: "<database>" } | "<role>",
      ...
  ]
}
```

|参数|类型|描述|
|---|-----|----|
|role|String|新角色的名称。|
|privileges	|array	|授予角色的权限。有关语法，请参阅 [privileges](https://docs.mongodb.com/manual/reference/system-roles-collection/#admin.system.roles.privileges)数组。您必须包括该privileges字段。使用空数组来指定没有权限。|
|roles	|array	|这个角色继承权限的角色数组。您必须包括该roles字段。使用空数组来指定 不继承的角色。|

### 3、栗子
```
use admin
db.createRole(
   {
     role: "myClusterwideAdmin",
     privileges: [
       { resource: { cluster: true }, actions: [ "addShard" ] },
       { resource: { db: "config", collection: "" }, actions: [ "find", "update", "insert", "remove" ] },
       { resource: { db: "users", collection: "usersCollection" }, actions: [ "update", "insert", "remove" ] },
       { resource: { db: "", collection: "" }, actions: [ "find" ] }
     ],
     roles: [
       { role: "read", db: "admin" }
     ]
   },
   { w: "majority" , wtimeout: 5000 }
)
```
## 三、创建用户
### 1、语法：db.createUser(user, writeConcern)
### 2、user 参数的格式：
```
{ user: "<name>",
  pwd: "<cleartext password>",
  customData: { <any information> },
  roles: [
    { role: "<role>", db: "<database>" } | "<role>",
    ...
  ]
}
```
### 3、栗子
```
use admin
db.createUser( { user: "accountAdmin01",
                 pwd: "changeMe",
                 customData: { employeeId: 12345 ,desc:"这里是可以写备注的"},
                 roles: [ { role: "clusterAdmin", db: "admin" },
                          { role: "readAnyDatabase", db: "admin" },
                          "readWrite"] },
               { w: "majority" , wtimeout: 5000 } )
```

## 四、开启权限认证
#### 第一种方法：在配置文件添加
```
auth = true
```
### 第二种方法：在启动的时候 加 参数： `--auth`
```
mongod --auth --port 27017 --dbpath /data/db1
```
### 当开启认证时，进入要认证才能执行相关操作
```
use admin
db.auth("username","password")
```
## 五、修改用户权限
### 一、db.grantRolesToUser(username, roles, writeConcern)
##### 这种是以追加的方式给用户添加权限
```
db.grantRolesToUser(
   "testUser",
   [{ role: "readWrite", db: "stock" }]
)
```
上面的意思是给testUser用户添加stock数据库的读写权限

### 二、db.updateUser(username, update, writeConcern)
##### 这种方式是替换账号的原有的角色
```
db.updateUser( "appClient01",
               {
                 customData : { employeeId : "0x3039" },
                 roles : [
                           { role : "read", db : "assets"  }
                         ]
                }
             )
```
这种方式其实和创建的时候差不多，就稍稍有点不同

## 六、一些常用的方法

1、删除用户
```
# 第二个参数可选，
db.dropUser(username,writeConcern)

# V2.6以后已弃用
# db.removeUser(username)
```
2、修改用户密码
```
db.changeUserPassword(username, password)
```
3、删除角色
```
db.dropRole(rolename,writeConcern )
```

> 参考文献：https://docs.mongodb.com/manual/security/

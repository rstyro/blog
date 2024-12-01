---
title: MongoDB (三)：基本命令操作
date: 2017-10-23 14:25:04
updated: 2017-10-23 14:25:04
tags: [MongoDB]
categories: 数据库
---
# MongoDB 的基本操作

### 数据库的一些常用命令
##### 1、显示所有数据库
```
show dbs
```
##### 2、使用数据库,当没有这个数据库时，mongodb 会在需要的时候帮你创建
```
use demo
```
##### 3、删除数据库
```
db.dropDatabase()
```

<!--more-->

## 一、插入数据
##### 1、往集合test插入单条数据
```
db.test.insert({url:"http://www.lrshuai.top"})
```

###### 2、往集合test插入多条数据，可通过for 循环
```
for(i=1;i<11;i++)db.test.insert({name:"lrshuai",age:23,num:i})
```
##### 插入数据时，会指定一个唯一不重复的 `_id` 字段,这个字段用户可以指定，但不能重复，当重复是报异常：E11000 duplicate key error collection.

##### save操作和insert操作区别在于当遇到_id相同的情况下, save完成保存操作,存在则替换
## 二、查询数据
###### 1、查询test 集合的所有数据
```
db.test.find()
```
##### 2、查询 test 集合 name为lrshuai 的数据
```
db.test.find({name:"lrshuai"})
```

## 三、更新数据
#### 参数详解
|参数|说明|
|---|---|
|参数一|query 查询要更新的条件|
|参数二|update 修改的内容|
|参数三|upsert 可选， 值默认为false——未找到匹配时不插入新记录|
|参数四|multi——可选 ，更新满足查询条件的多条记录|
|参数五|writeConcern 可选，抛出异常的级别|
##### 1、更改name 为 test ,当num 等于1 的时候，但这样的操作会把其他属性给删除掉。
```
db.test.update({num:1},{name:"test"})
```

##### 2、更改name 为test ,当num 等于1 的时候，只修改一个属性，其他属性不动,加 `$set:`
```
db.test.update({num:1},{$set:{name:"test"}})
```

##### 3、当修改不存在的数据时,自动添加修改的数据。第三个参数 设置为true
```
db.test.update({num:1},{name:"test"},true)
```

##### 4、修改满足条件的所有数据
```
db.test.update({num:1},{name:"test"},false,true)
```

## 四、删除数据
##### 1、删除 test 集合中name 为lrshuai 的所有数据
```
db.test.remove({name:"lrshuai"})
```

##### 2、删除test 的集合
```
db.test.drop()
```



---
title: MongoDB (四)：索引
date: 2017-10-23 17:45:01
tags: [MongoDB]
categories: 数据库
---
# MongoDB 的索引

## MongoDB 的索引种类
### 1、_id 索引
### 2、单键索引
### 3、复合索引
### 4、多键索引
### 5、过期索引
### 6、全文索引
### 7、地理位置索引

#### 查看索引的信息
```
db.test.getIndexes()

```

## 一、_id 索引
#### 这个索引绝大多数集合默认建立的索引，一个唯一的索引

## 二、单键索引
#### 单键索引最普通的索引
#### 1、创建索引,给 `name` 这个列添加索引
```
# 这个应该是V3.0 之前的方法了
db.test.ensureIndex({name:1})
# 这个是V3.0后的新方法，推荐用这个
db.test.createIndex({name:1})

#一个值1指定以升序排列的索引。-1指定按降序排列的索引。
```
#### 2、创建索引的其他参数属性
##### (a)、name 指定，给索引命名
```
db.test.createIndex({name:1},{name:"indexName"})
```
##### (b)、unique 唯一性 ,为true 时 当插入已存在name 的值后，将报错
```
db.test.createIndex({name:1},{unique:true/false})
```
##### (c)、sparse 稀疏性，当为true时，索引字段不存在时将不创建索引，
```
db.test.createIndex({name:1},{sparse:true/false})
```
##### (d)、expireAfterSeconds 过期， 下面会讲到


## 三、复合索引
#### 复合索引可以支持与多个字段匹配的查询
#### 简单说就是把多个字段组合成一个单键索引

## 四、多键索引
#### 1、这个和单键的区别就是，索引可以是一个数组
#### 2、栗子
```
# 有这么一个数据
{ _id: 1, item: "ABC", ratings: [ 2, 5, 9 ] }

# 创建一个索引
db.survey.createIndex( { ratings: 1 } )

```
或者这样的
```
{
  _id: 1,
  item: "abc",
  stock: [
    { size: "S", color: "red", quantity: 25 },
    { size: "S", color: "blue", quantity: 10 },
    { size: "M", color: "blue", quantity: 50 }
  ]
}
{
  _id: 2,
  item: "def",
  stock: [
    { size: "S", color: "blue", quantity: 20 },
    { size: "M", color: "blue", quantity: 5 },
    { size: "M", color: "black", quantity: 10 },
    { size: "L", color: "red", quantity: 2 }
  ]
}
{
  _id: 3,
  item: "ijk",
  stock: [
    { size: "M", color: "blue", quantity: 15 },
    { size: "L", color: "blue", quantity: 100 },
    { size: "L", color: "red", quantity: 25 }
  ]
}

# 创建索引
db.inventory.createIndex( { "stock.size": 1, "stock.quantity": 1 } )

# 可以复合查询，这样，quantity大于20，size 为S 码
db.inventory.find( { "stock.size": "S", "stock.quantity": { $gt: 20 } } )
```

## 五、过期索引
##### 过期索引又称 TTL（Time To Live，生存时间）索引，即在一段时间后会过期的索引（如登录信息、日志等）
##### 我们知道添加索引，对于数据库的 添加、修改、删除是有影响的。
##### 当索引过期后，相应的数据将被删除
##### 适合存贮一段时间过后，失效的数据
```
#   参数一  --- 索引字段名称  ，参数二  ---- 过期时间 ，单位：秒
db.item.createIndex( {createTime: 1 }, { expireAfterSeconds: 60*60 } ) 
```
#### 1、mongdb时间类型
+ Date()     显示当前的时间
+ new Date　 构建一个格林尼治时间   可以看到正好和Date()相差8小时，我们是+8时区，也就是时差相差8，所以+8小时就是系统当前时间
+ ISODate()　格林尼治时间

#### 2、过期索引的限制：
1、存储在过期索引的字段必须是指定的时间类型
+ 时间类型必须为ISODate类型，或者ISODate 数组。不能使用时间戳，否则不能被自动删除

2、如果指定了Date数组，则按照最小的时间进行删除
3、过期索引不能是复合索引
4、删除时间不是精确的
+ 说明：删除过程是由后台程序每60s执行一次，而且删除也需要一些时间所以存在误差

#### 3、栗子
```
# 创建一个时间索引，60秒后过期
db.time.createIndex({time:1},{expireAfterSeconds:60})
# 插入一条数据
db.time.insert({time:new Date()})
# 查询数据
db.time.find()
# 60秒后再查询，发现数据没有了
db.time.find() 
```
## 六、全文索引
#### 对字符串与字符串数组创建全文可搜索的索引
#### 1、创建格式：
```
# key 代表一个字段名称，`$**` 是全局匹配
db.articles.createIndex({key:"text"})
db.articles.createIndex({key_1:"text",key_2:"text"})
db.articles.createIndex({"$**":"text"})
```
#### 2、栗子
```
# 插入数据
db.articles.insert({auther:"lrshuai",title:"mongdb",content:"mongdb about"})
db.articles.insert({auther:"lrshuai",title:"mongdb",content:"mongdb information"})
db.articles.insert({auther:"lrshuai",title:"mongdb",content:"mongdb information content"})
# 查看所有信息
db.articles.find()

# 创建全文索引
db.articles.createIndex({content:"text"})

# 使用全局索引查找
# 查找内容中包含mongodb 的数据
db.articles.find({$text:{$search:"mongdb"}})
# 查找内容中包含mongodb 或者 information 的数据
db.articles.find({$text:{$search:"mongdb information"}})
# 查找内容中包含mongodb 但不包含information的数据
db.articles.find({$text:{$search:"mongdb -information"}})
# 查找内容中包含mongodb 并且包含information 的数据
db.articles.find({$text:{$search:"\"mongdb\" \"information\""}})
```
#### 3、全文索引相似度查询
```
# score 相似度值，越高越相似
db.articles.find({$text:{$search:"mongdb"}},{score:{$meta:"textScore"}})

# 相似度排序，高在前
db.articles.find({$text:{$search:"mongdb"}},{score:{$meta:"textScore"}}).sort({score:{$meta:"textScore"}})
```

#### 4、全文索引的限制
+ 每次查询，只能指定一个$text 查询
+ $text 查询不能出现在$nor 查询中
+ 查询中如果包含了$text,hine 不再起作用


## 七、地理位置索引
### 概念：将一些点的位置存储在Mongodb 中，创建索引后可以按照位置来查找其他的点
### 子分类：
### 1、2d 索引：平面地理位置索引
#### 用于存储和查找平面上的点
#### 创建方式：db.locate.insert({width:[经度,纬度]})
#### 取值范围：经度：[-180,180]，纬度:[-90,90]

```
# 创建索引
db.locate.createIndex({width:"2d"})

# 查找离点[1,1] 最远是10 的范围点集合
db.locate.find({width:{$near:[1,1],$maxDistance:40}})

# 查找离点[1,1] 最远是40，最近是2 的范围点集合，3.X版本的 $minDiatance 才可以直接使用
db.locate.find({width:{$near:[1,1],$maxDistance:40,$minDistance: 2}})

# 矩形查询 
db.locate.find({width:{$geoWithin:{$box:[[30,20],[33,30]]}}})

# 圆，一个是圆心，第二个是半径
db.locate.find({width:{$geoWithin:{$center:[[30,20],10}}})

# 多边形
db.locate.find({width:{$geoWithin:{$polygon:[[0,0],[-1,20],[30,30]]}}})

# geoNear 查询，geoNear --- 集合名词，near -- 范围， num 是返回的数量
db.runCommand({geoNear:"locate",near:[30,20],maxDistance:20,minDistance:1,num:5})

```

### 2、2dsphere 索引：球面地理位置索引
#### 用于存储和查找球面上的点 
#### 2dsphere需要插入GeoJson数据。GeoJson的格式是：
#### { type: ‘GeoJSON type’ , coordinates: ‘coordinates’ } 
+ 其中type指的是类型，
	+ Point（经纬度坐标点）
	+ LineString（两个坐标点，组成一条线）
	+ Polygon（多边形）
+ coordinates是一个坐标数组

```
# 创建索引
db.locate.createIndex({width:"2dsphere"})
```

## 八、索引构建情况分析
#### 索引的好处：加快索引相关的查询
#### 索引的缺点：增加磁盘空间消耗，降低写入性能

### 评判索引构建的方法：

#### 2、profile 集合
##### 当开启的时候 数据库就会有一个system.profile 的集合
+ 1、db.getProfilingStatus() 查看状态
+ 2、db.getProfilingLevel() 获得级别
	+ 0 -- 关闭
	+ 1 -- 记录符合 slowms 条件的记录
	+ 2 --- 记录所有
+ 3、一般开发的调试的时候会开启，生产环境一般都是关闭的。因为会影响性能

#### 3、日志介绍
##### 在配置文件中加入参数
```
# 1- 5个v，v 越多，信息越详细
verbose = vvvvv
```
#### 4、explain 分析
```
db.test.find({sex:1}).explain("executionStats")
```

> 参考文献：https://docs.mongodb.com/manual/tutorial/measure-index-use/
> https://docs.mongodb.com/manual/reference/geojson/






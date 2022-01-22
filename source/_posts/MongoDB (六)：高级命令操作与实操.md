---
title: MongoDB (六)：高级命令操作与实操
date: 2017-10-25 16:42:00
updated: 2017-10-25 16:42:00
tags: [MongoDB]
categories: 数据库
---
# MongoDB 高级命令语法
|修改器名称|语法|案例|说明|
|---|---|---|---|
|$lt|$lt:value|db.persons.find({age:{$lt:27})|查询age 小于 27的数据|
|$lte|$lte:value|db.persons.find({age:{$lte:27})|查询age 小于等于 27的数据|
|$gt|$gt:value|db.persons.find({age:{$gt:27})|查询age 大于27 的数据|
|$gte|$gte:value|db.persons.find({age:{$gte:27})|查询age 大于等于27 的数据|
|$ne|$ne:value|db.persons.find({age:{$ne:27})|查询age 不等于27 的数据|
|$set|{$set:{key:value}}|db.language.update({lang:"CH"},{$set:{name:"中国"}},true)|用来指定一个键值对,如果存在键就进行修改不存在则进行添加，第三个参数是不存在就添加|
|$inc|{$inc:{key:value}}|db.people.update({age:23},{$inc:{age:1}},true)|使用与数字类型,他可以为指定的键对应的数字类型的数值进行加(value=1)减(value=-1)操作.给age为23 的自增|
|$unset|{$unset:{key:value}}}|db.people.update({name:"jj"},{$unset:{age:1}})|删除指定的键，在people这个文档中删除name为jj,的age属性|
|$push|{$push:{key:value}}|db.people.update({_id:1},{$push:{skills:"MongoDB"}},true)|如果指定的键是数组增追加新的数值,如果指定的键不是数组则中断当前操作,如果不存在指定的键则创建数组类型的键值对|
|$pushAll|{$pushAll:{key:value}}|db.people.update({_id:2},{$pushAll:{skills:["MongoDB","JAVA"]}},true)|用法和$push相似它可以添加数组数据|
|$addToSet|{$addToSet:{key:value}}|db.people.update({_id:2},{$addToSet:{skills:"Linux"}})|目标数组存在此项则不操作,不存在此项则加进去|
|$pop|{$pop:{key:value}}|db.people.update({_id:2},{$pop:{skills:-1}})|从指定数组删除一个值1删除最后一个数值,-1删除第一个数值|
|$pull|{$pull:{key:value}}|db.people.update({_id:2},{$pull:{skills:"C++"}})|从指定数组删除一个被指定的数值|
|$pullAll|{$pullAll:{key:array}}|db.people.update({_id:2},{$pullAll:{skills:["C++","Linux"]}})|从指定数组删除一个被指定的数值|
|$each|{$each:{key:array}}|db.people.update({_id:3},{$addToSet:{skills:{$each:["MongoDB","JAVA","linux"]}}},true)|循环操作，这样就可以合并两个不同的数组了|
|$ 数组定位器|array.$.parame|db.people.update({teacher.name:"bb"},{$set:{"teacher.$.sex":"female"}})|如果以有这么一条数据： { "_id" : ObjectId("59f02f593e1b3b89f138d979"), "name" : "rstyro", "age" : 23, "teacher" : [ { "name" : "aa", "teach" : "english" }, { "name" : "bb", "teach" : "math" }, { "name" : "cc", "teach" : "chinese" } ] } 你要对teacher 数组中的name 为bb 添加一个sex 属性。|


# 实操题练习

## 一、导入数据
```
var persons = [{
	name:"jim",
	age:25,
	email:"75431457@qq.com",
	c:89,m:96,e:87,
	country:"USA",
	books:["JS","C++","EXTJS","MONGODB"]
},
{
	name:"tom",
	age:25,
	email:"214557457@qq.com",
	c:75,m:66,e:97,
	country:"USA",
	books:["PHP","JAVA","EXTJS","C++"]
},
{
	name:"lili",
	age:26,
	email:"344521457@qq.com",
	c:75,m:63,e:97,
	country:"USA",
	books:["JS","JAVA","C#","MONGODB"]
},
{
	name:"zhangsan",
	age:27,
	email:"2145567457@qq.com",
	c:89,m:86,e:67,
	country:"China",
	books:["JS","JAVA","EXTJS","MONGODB"]
},
{
	name:"lisi",
	age:26,
	email:"274521457@qq.com",
	c:53,m:96,e:83,
	country:"China",
	books:["JS","C#","PHP","MONGODB"]
},
{
	name:"wangwu",
	age:27,
	email:"65621457@qq.com",
	c:45,m:65,e:99,
	country:"China",
	books:["JS","JAVA","C++","MONGODB"]
},
{
	name:"zhaoliu",
	age:27,
	email:"214521457@qq.com",
	c:99,m:96,e:97,
	country:"China",
	books:["JS","JAVA","EXTJS","PHP"]
},
{
	name:"piaoyingjun",
	age:26,
	email:"piaoyingjun@uspcat.com",
	c:39,m:54,e:53,
	country:"Korea",
	books:["JS","C#","EXTJS","MONGODB"]
},
{
	name:"lizhenxian",
	age:27,
	email:"lizhenxian@uspcat.com",
	c:35,m:56,e:47,
	country:"Korea",
	books:["JS","JAVA","EXTJS","MONGODB"]
},
{
	name:"lixiaoli",
	age:21,
	email:"lixiaoli@uspcat.com",
	c:36,m:86,e:32,
	country:"Korea",
	books:["JS","JAVA","PHP","MONGODB"]
},
{
	name:"zhangsuying",
	age:22,
	email:"zhangsuying@uspcat.com",
	c:45,m:63,e:77,
	country:"Korea",
	books:["JS","JAVA","C#","MONGODB"]
}]

for(i=0;i<persons.length;i++)db.persons.insert(persons[i])

```

## 二、练习
### 1、查询
#### 查询出年龄在25到27岁之间的学生
```
db.persons.find({age:{$gte:25,$lte:27}},{_id:0,name:1,age:1})
```

#### 查询出所有不是韩国籍的学生的数学成绩
```
db.persons.find({country:{$ne:” Korea”}},{_id:0,m:1,name:1})
```
### 2、包含或不包含 $in或$nin
#### 查询国籍是中国或美国的学生信息
```
db.persons.find({country:{$in:["USA","China"]}})
```
#### 查询国籍不是中国或美国的学生信息
```
db.persons.find({country:{$nin:["USA","China"]}})
```
### 3、OR查询 $or
#### 查询语文成绩大于85或者英语大于90的学生信息
```
db.persons.find({$or:[{c:{$gt:85}},{e:{$gt:90}}]},{_id:0,name:1,c:1,e:1})
```
### 4、Null
#### 把中国国籍的学生上增加新的键sex
```
db.person.update({country:"China"},{$set:{sex:"m"}})
```
#### 查询出sex 等于 null的学生
```
db.persons.find({sex:{$in:[null]}},{name:1})
```
### 5、正则查询
#### 查询出名字中存在”li”的学生的信息
```
db.persons.find({name:/li/i},{_id:0,name:1})
```
### 6、$not的使用
##### $not可以用到任何地方进行取反操作
#### 查询出名字中不存在”li”的学生的信息
```
db.persons.find({name:{$not:/li/i}},{_id:0,name:1})
```
##### $not和$nin的区别是$not可以用在任何地方儿$nin是用到集合上的
### 7、数组查询$all和index应用
#### 查询有MONGOD和JS的学生
```
db.persons.find({books:{$all:["MONGOBD","JS"]}},{books:1,_id:0,name:1})
```
#### 查询第二本书是JAVA的学习信息
```
db.persons.find({"books.1":"JAVA"})
```
### 8、查询指定长度数组$size它不能与比较查询符一起使用(这是弊端)
#### 查询出拥有书籍数量是4本的学生
```
db.persons.find({books:{$size:4}},{_id:0,books:1,name:1})
```
### 9、查询出拥有的书籍数量大于3本的学生
#### 增加字段size
```
db.persons.update({},{$set:{size:4}},false, true)
```
#### 改变书籍的更新方式,每次增加书籍的时候size增加1
```
db.persons.update({查询器},{$push:{books:"ORACLE"},$inc:{size:1}})
```
#### 利用$gt查询
```
db.persons.find({size:{$gt:3}})
```

### 10、利用shell查询出Jim拥有的书的数量
```
var persons = db.persons.find({name:"jim"})
while(persons.hasNext()){
	obj = persons.next();
        print(obj.books.length)
} 
```

### 11、$slice操作符返回文档中指定数组的内部值
#### 查询出Jim书架中第2~4本书
```
db.persons.find({name:"jim"},{books:{"$slice":[1,3]}})
```
#### 查询出最后一本书
```
db.persons.find({name:"jim"},{books:{"$slice":-1},_id:0,name:1})
```

### 12、文档查询
#### 为jim添加学习简历文档 jim.json
```
var jim = [{
	school :"K",
	score:"A"
},{
	school :"L",
	score:"B"
},{
	school :"J",
	score:"A+"
}]
db.persons.update({name:"jim"},{$set:{school:jim}})
```
#### 查询出在K上过学的学生
##### 这个我们用绝对匹配可以完成,但是有些问题(找找问题?顺序?总要带着score?)
```
db.persons.find({school:{school:"K",score:"A"}},{_id:0,school:1})
```
##### 为了解决顺序的问题我可以用对象”.”的方式定位
```
 db.persons.find({"school.score":"A","school.school":"K"},{_id:0,school:1})
```
这样也有问题看例子:
```
db.persons.find({"school.score":"A","school.school":"J"},{_id:0,school:1})
```
同样能查出刚才那条数据,原因是score和school会去其他对象对比

正确做法单条条件组查询$elemMatch
```
db.persons.find({school:{$elemMatch:{school:"K",score:"A"}}})
```
### 13、$where
#### 查询年龄大于22岁,拥有C++书,在K学校上过学的学生信息复杂的查询我们就可以用$where因为他是万能但是我们要尽量避免少使用它因为他会有性能的代价
```
db.persons.find({"$where":function(){
	var books = this.books;
	var school = this.school;
	if(this.age > 22){
		var ccc = null;
		for ( var i = 0; i < books.length; i++) {
			if(books[i] == "C++"){
				ccc = books[i];	
				if(school){
					for (var j = 0; j < school.length; j++) {					
						if(school[j].school == "K"){					
							return true;
						}
					}
					break;
				}
			}
		}	
	}
}})
```


### 14、Limit返回指定的数据条数
#### 查询出persons文档中前5条数据
```
db.persons.find({},{_id:0,name:1}).limit(5)
```
### 15、Skip返回指定数据的跨度
#### 查询出persons文档中第5~10条的数据
```
db.persons.find({},{_id:0,name:1}).limit(5).skip(5)
```
### 16、Sort返回按照年龄排序的数据[1,-1]
```
db.persons.find({},{_id:0,name:1,age:1}).sort({age:1})
```
##### 注意:mongodb的key可以存不同类型的数据排序就也有优先级
+ 最小值
+ null
+ 数字
+ 字符串
+ 对象/文档
+ 数组
+ 二进制
+ 对象ID
+ 布尔
+ 日期
+ 时间戳 > 正则 > 最大值 





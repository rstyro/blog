---
title: Neo4j 小记
date: 2018-10-17 20:01:30
updated: 2018-10-17 20:01:30
tags: [Neo4j]
categories: 其他
---
## [Neo4j下载地址](https://neo4j.com/download-center/#releases)
## 配置环境变量：NEO4J_HOME
## 把neo4j 安装为服务
```
# 安装服务
neo4j install-service

# 卸载服务
neo4j uninstall-service

# 启动
neo4j start

# 停止
neo4j stop
	
# 重启
neo4j restart

# 查询服务状态
neo4j status

```

#### 默认的host是bolt://localhost:7687，默认的用户是neo4j，其默认的密码是：neo4j，第一次成功登陆到Neo4j服务器之后，需要重置密码。 访问Graph Database需要输入身份验证，Host是Bolt协议标识的主机。


```

# 创建一个 Person 对象，别名为a, 名字为 rstyro,年龄为23，性别 男
create (a:Person{name:"rstyro",age:23,sex:"男"});
create (a:Person{name:"rstyro",age:23,sex:"男"}) return a;

# 一次创建多个 对象，
create (a:Person{name:"rstyro",age:23,sex:"男"}),(b:Person{name:"老婆",age:21,sex:"女"});
create (a:Person{name:"rstyro",age:23,sex:"男"}),(b:Person{name:"老婆",age:21,sex:"女"}) return a,b;

# 修改对象，name 为rstyro 的，修改 age 属性为 168
match (a:Person{name:"rstyro"}) set a.age=168;

# 删除，清库
MATCH (n) DETACH DELETE n ;

# 删除 对象，name 为rstyro的
match (n:Person{name:"rstyro"}) delete n;
```

#### 创建关系
```
create (a:Person{name:"大佬",sex:"man"}),(b:Person{name:"22222",sex:"female"}),(c:Person{name:"3333",sex:"female"}) return a,b,c;
create (p3:Person{name:"4444",sex:"man"}) return p3;

# 创建两个关系 DIRECTED 、ACTED_IN
MATCH (oliver:Person { name: '3333' }),(reiner:Person { name: '22222' })
MERGE (oliver)-[:DIRECTED]->(movie:Person {name:"4444",sex:"man"})<-[:ACTED_IN]-(reiner)
RETURN movie

# 创建兄弟关系的A、B节点
match(a),(b) where a.id='502208330941468673' and b.id='502208330941468672' create (a)-[r:兄弟 {}]->(b)


# 删除 name=3333 的所有关系链
match (n:Person{name:"3333"})-[r]-(m:Person) delete r;

# 删除 name=3333 的所有关系链,和其本身节点
match (n:Person{name:"3333"})-[r]-(m:Person) delete r,n;

# 删除 name=3333 的所有关系链与本身节点和相关联的节点
match (n:Person{name:"3333"})-[r]-(m:Person) delete r,n,m;

```

---
title: Spring Boot (十一)：与MongoDB 整合
date: 2017-10-30 16:17:45
updated: 2017-10-30 16:17:45
tags: [MongoDB, Spring Boot]
categories: Java
---
# Springboot 的Mongodb 的整合
## 一、导入依赖
```
<dependency>
	<groupId>org.springframework.boot</groupId>
	<artifactId>spring-boot-starter-data-mongodb</artifactId>
</dependency>
```
<!--more-->

## 二、配置文件
##### application.properties 添加mongo 地址
```
# 这种事需要 认证的 用户名和密码
#spring.data.mongodb.uri=mongodb://username:password@192.168.12.133:22222/test

# 这种是不需要认证的
spring.data.mongodb.uri=mongodb://192.168.12.133:22222/test
```

## 三、编写Dao层

#### 这里有两种方法

### 1、继承自 MongoRepository<T,ID>
##### 这个基本的增删改查它都封装好了，直接调用即可。


#### User
```java
public class User {
	@Id
	private Long id;	
	private String name;
	private Integer age;
	//get set 方法 省略了....
}
```

#### UserRepository.class 
```java
package top.lrshuai.mongodb.repository;

import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Component;

import top.lrshuai.mongodb.entity.User;

@Component
public interface UserRepository extends MongoRepository<User, Long>{
	public User findUserByName(String username);

}

```

### 2、自定义Dao
##### 使用 MongoTemplate 自己封装方法，可实现复杂的查询方法。

#### UserDao.class
```java
package top.lrshuai.mongodb.dao;

import java.util.List;

import top.lrshuai.mongodb.entity.User;
/**
 * 
 * @author rstyro
 *
 */
public interface UserDao {
	public void saveUser(User user);
	public void saveBathUser(List<User> users);
	public void delUserById(Long id);
	public int upadteUserById(User user);
	public User findUserByName(String name);
	public List<User> findAll();
	public List<User> findUserByLikeName(String name);
	
}

```

UserDaoImpl.class 
```java
package top.lrshuai.mongodb.dao.impl;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.mongodb.core.query.Update;
import org.springframework.stereotype.Component;

import com.mongodb.WriteResult;

import top.lrshuai.mongodb.dao.UserDao;
import top.lrshuai.mongodb.entity.User;

@Component
public class UserDaoImpl implements UserDao{

	@Autowired
	private MongoTemplate mongoTemplate;
	
	/**
	 * 新增一个，存在则覆盖
	 */
	@Override
	public void saveUser(User user) {
		mongoTemplate.save(user);
	}
	
	/**
	 * 批量新增
	 */
	@Override
	public void saveBathUser(List<User> users) {
		mongoTemplate.insert(users, User.class);
	}
	
	/**
	 * 删除
	 */
	@Override
	public void delUserById(Long id) {
		Query query = new Query(Criteria.where("id").is(id));
		mongoTemplate.remove(query, User.class);
	}

	/**
	 * 更新 通过id
	 */
	@Override
	public int upadteUserById(User user) {
		Query query = new Query(Criteria.where("id").is(user.getId()));
		Update update = new Update();
		update.set("name", user.getName()).set("age", user.getAge());
		WriteResult result =  mongoTemplate.updateFirst(query, update, User.class);
		return result.getN();
	}

	/**
	 * 通过名称查找
	 */
	@Override
	public User findUserByName(String name) {
		Query query = new Query(Criteria.where("name").is(name));
		return mongoTemplate.findOne(query, User.class);
	}
	
	/**
	 * 查询所有
	 */
	@Override
	public List<User> findAll() {
		return mongoTemplate.findAll(User.class);
	}
	
	/**
	 * name模糊查找
	 */
	@Override
	public List<User> findUserByLikeName(String name) {
		Query query = new Query();
		query.addCriteria(Criteria.where("name").regex(".*" +name+ ".*"));
		return mongoTemplate.find(query, User.class);
	}
	
	/**
	 * text 全文索引查询
	 * 这个首先你要创建全文索引
	 * 详细用法：https://spring.io/blog/2014/07/17/text-search-your-documents-with-spring-data-mongodb
	 */
	@Test
	public void customQueryLikeName() {
		TextCriteria criteria = TextCriteria.forDefaultLanguage();
		  criteria.matching("haha","rstyro","lrshuai");
		Query query = TextQuery.queryText(criteria)
				.sortByScore();
		List<User> users = mongoTemplate.find(query, User.class);
	}

}

```

## 四、测试类
#### 完整代码：
```java
package top.lrshuai.mongodb;

import java.util.ArrayList;
import java.util.List;

import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.junit4.SpringRunner;

import top.lrshuai.mongodb.dao.UserDao;
import top.lrshuai.mongodb.entity.User;
import top.lrshuai.mongodb.repository.UserRepository;

@RunWith(SpringRunner.class)
@SpringBootTest
public class ApplicationTests {
	
	@Autowired
	private UserDao userDao;
	
	@Autowired
	private UserRepository userRepository;
	
	/**
	 * 批量新增
	 */
	@Test
	public void customBathSave() {
		List<User> users = new ArrayList<>();
		User u1 = new User(1l, "lrshuai", 23);
		User u2 = new User(2l, "rstyro", 24);
		User u3 = new User(3l, "tyro", 25);
		User u4 = new User(4l, "mongo", 26);
		users.add(u1);
		users.add(u2);
		users.add(u3);
		users.add(u4);
		userDao.saveBathUser(users);
	}
	
	/**
	 * 保存单个，存在则修改
	 */
	@Test
	public void customSave() {
		userDao.saveUser(new User(1l, "rstyro", 23));
	}
	
	/**
	 * 删除
	 */
	@Test
	public void customDel() {
		userDao.delUserById(1l);
	}
	
	/**
	 * 更新通过ID
	 */
	@Test
	public void customUpdate() {
		User user  = new User(2l,"修改用户名",25);
		System.out.println(userDao.upadteUserById(user));
	}
	
	/**
	 * 通过用户名精确查找
	 */
	@Test
	public void customQuery() {
		User user = userDao.findUserByName("haha");
		System.out.println("user="+user);
	}
	
	@Test
	public void customQueryAll() {
		List<User> users = userDao.findAll();
		System.out.println("users="+users);
	}
	
	/**
	 * 通过name 模糊查找
	 */
	@Test
	public void customQueryLikeName() {
		String name="o";
		List<User> users = userDao.findUserByLikeName(name);
		System.out.println("users="+users);
	}
	
	

	/********** 下面是继承 MongoRepository 的方法 ******/
	@Test
	public void saveTest(){
		User user = userRepository.save(new User(2l, "haha", 23));
		System.out.println("保存后返回的 user"+user);
	}
	
	@Test
	public void delTest(){
		userRepository.delete(3l);
	}
	
	@Test
	public void updateTest(){
		User user = userRepository.save(new User(4l, "测试", 24));
		System.out.println("修改后返回的 user"+user);
	}
	
	@Test
	public void findOneByNameTest(){
		User u = userRepository.findUserByName("rstyro");
		System.out.println("user="+u);
	}
	
	@Test
	public void findAllTest(){
		List<User> users = userRepository.findAll();
		System.out.println("users="+users);
	}
	
}

```


> Github 示例代码：[https://github.com/rstyro/spring-boot/tree/master/springboot-mongodb](https://github.com/rstyro/spring-boot/tree/master/springboot-mongodb)



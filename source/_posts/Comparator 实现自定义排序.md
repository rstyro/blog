---
title: Comparator 实现自定义排序
date: 2017-10-18 11:01:10
updated: 2017-10-18 11:01:10
tags: [Java]
categories: Java
---
# java 利用Comparator 实现自定义排序
## Comparator 是一个java.util 包下的接口，它提供一个compare() 方法让我们来自己实现排序方式
#### 废话不多说，看demo,demo就是最好的文档。

<!--more-->

## 第一种方式：
#### 实现Comparable 接口，重写compareTo 方法，然后调用Collections.sort(list) 方法即可
```java
package top.lrshuai.blog.util;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * 玩家类
 * @author 帅大叔
 *
 */
public class Player implements Comparable<Player>{
	private String userId;
	private String userName;
	private int level;
	public String getUserId() {
		return userId;
	}
	public void setUserId(String userId) {
		this.userId = userId;
	}
	public String getUserName() {
		return userName;
	}
	public void setUserName(String userName) {
		this.userName = userName;
	}
	public int getLevel() {
		return level;
	}
	public void setLevel(int level) {
		this.level = level;
	}
	public Player() {
		super();
		// TODO Auto-generated constructor stub
	}
	public Player(String userId, String userName, int level) {
		super();
		this.userId = userId;
		this.userName = userName;
		this.level = level;
	}
	@Override
	public String toString() {
		return "Player [userId=" + userId + ", userName=" + userName + ", level=" + level + "]";
	}
	@Override
	public int compareTo(Player o) {
		 if (this.getLevel() < o.getLevel())  
	            return 1;  
	     else if(this.getLevel() > o.getLevel()){
	    	 return -1;
	     }else{
	    	return this.getUserName().compareTo(o.getUserName());
	    } 
	}
	
	public static void main(String[] args) {
		List<Player> playerList = new ArrayList<>();
		Player p1 = new Player("p1", "abc", 1);
		Player p2 = new Player("p2", "def", 2);
		Player p3 = new Player("p3", "efg", 5);
		Player p4 = new Player("p4", "bcd", 3);
		playerList.add(p1);
		playerList.add(p2);
		playerList.add(p3);
		playerList.add(p4);
		//排序，会按照Player类中的compareTo 方式来排序
		Collections.sort(playerList);
		System.out.println(playerList);
	}
	
}

//打印结果
/*
[
Player [userId=p3, userName=efg, level=5],
Player [userId=p4, userName=bcd, level=3],
Player [userId=p2, userName=def, level=2],
Player [userId=p1, userName=abc, level=1]]
*/
```
## 第二种方式：
#### 不用实现Comparable 接口，但在排序的时候在实现Comparable 接口
```java
package top.lrshuai.blog.util;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

/**
 * 玩家类
 * @author 帅大叔
 *
 */
public class Player{
	private String userId;
	private String userName;
	private int level;
	public String getUserId() {
		return userId;
	}
	public void setUserId(String userId) {
		this.userId = userId;
	}
	public String getUserName() {
		return userName;
	}
	public void setUserName(String userName) {
		this.userName = userName;
	}
	public int getLevel() {
		return level;
	}
	public void setLevel(int level) {
		this.level = level;
	}
	public Player() {
		super();
		// TODO Auto-generated constructor stub
	}
	public Player(String userId, String userName, int level) {
		super();
		this.userId = userId;
		this.userName = userName;
		this.level = level;
	}
	@Override
	public String toString() {
		return "Player [userId=" + userId + ", userName=" + userName + ", level=" + level + "]";
	}
	
	public static void main(String[] args) {
		List<Player> playerList = new ArrayList<>();
		Player p1 = new Player("p1", "abc", 1);
		Player p2 = new Player("p2", "def", 2);
		Player p3 = new Player("p3", "efg", 5);
		Player p4 = new Player("p4", "bcd", 3);
		playerList.add(p1);
		playerList.add(p2);
		playerList.add(p3);
		playerList.add(p4);
		//自己实现排序方式
		Collections.sort(playerList, new Comparator<Player>() {
			@Override
			public int compare(Player o1, Player o2) {
				 if (o1.getLevel() < o2.getLevel())  
			            return 1;  
			     else if(o1.getLevel() > o2.getLevel()){
			    	 return -1;
			     }else{
				 	// 这个是按照userName 升序,首字母小的在前
			    	return o1.getUserName().compareTo(o2.getUserName());
			    } 
			}
		});;
		System.out.println(playerList);
	}
	
}
//打印结果
/*
[
Player [userId=p3, userName=efg, level=5],
Player [userId=p4, userName=bcd, level=3],
Player [userId=p2, userName=def, level=2],
Player [userId=p1, userName=abc, level=1]]
*/
```

## 总结：
### 一、上面的排序方式都是：按照level 降序排序，其次按照 userName 升序，如果你有多个参数比较就在compare 里继续在else 里写就可以了。
### 二、关于return 的问题 
### 1、int 类型的比较
```java
return o1.getLevel() < o2.getLevel() ? 1:-1; //这个是按照 Level 降序排序（大到小）
return o1.getLevel() > o2.getLevel() ? 1:-1; //这个是按照 Level 升序序排序（小到大）

// 可以这么理解 1 相当于true 。前面是升序，后面是降序，谁大谁说话
// 如果后面的比前面的大，return 1。就是按后面的排序，所以就是降序
// 如果后面的比前面的小，return 1，前面的大，前面才是老大，就是按前面的排序，所以就是升序
```
### 2、string 类型的比较
```
// 可以这么理解，compare(参数1，参数2)
// 参数1 是升序，参数2 是降序
// o1.getUserName().compareTo(o2.getUserName())   o1 在前，所以按o1 的排序，而o1 是参数1，所以是升序
// o2.getUserName().compareTo(o1.getUserName())   o2 在前，所以按o2 的排序，而o2 是参数2，所以是降序
```


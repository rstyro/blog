---
title: Jquery 相关笔记
date: 2017-11-21 15:32:03
tags: [Javascript]
categories: 前端
---
# 笔记

## 一、获取各种宽高
```html
console.log($(window).height()); //浏览器时下窗口可视区域高度
console.log($(document).height()); //浏览器时下窗口文档的高度
console.log($(document.body).height());//浏览器时下窗口文档body的高度
console.log($(document.body).outerHeight(true));//浏览器时下窗口文档body的总高度 包括border padding margin
console.log($(window).width()); //浏览器时下窗口可视区域宽度
console.log($(document).width());//浏览器时下窗口文档对于象宽度
console.log($(document.body).width());//浏览器时下窗口文档body的高度
console.log($(document.body).outerWidth(true));//浏览器时下窗口文档body的总宽度 包括border padding margin
console.log($(document).scrollTop()); //获取滚动条到顶部的垂直高度
console.log($(document).scrollLeft()); //获取滚动条到左边的垂直宽度

console.log($(document).offset().top); //获取绝对位置坐标
console.log($(document).offset().left); //获取绝对位置坐标

console.log($(document).position().top); //获取相对父级元素的坐标
console.log($(document).position().left); //获取相对父级元素的坐标
```

## 二、窗口变化时触发的方法
```js
$(window).resize(function(){
	console.log("窗口变化了");
});
```
## 三、获取复选框选中的值
```html
<p><input type='checkbox' name='ids' value='value1'> <span>文字提醒1</span></p>
<p><input type='checkbox' name='ids' value='value2'> <span>文字提醒2</span></p>


<script>
$(function(){
	$('input[name="ids"]:checked').each(function(){ 
		console.log("选中的值之一：",$(this).val()); 
	});
})
</script>
```
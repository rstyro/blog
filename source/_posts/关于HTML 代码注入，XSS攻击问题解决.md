---
title: 关于HTML 代码注入，XSS攻击问题解决
date: 2017-10-13 18:04:53
updated: 2017-10-13 18:04:53
tags: [Javascript, HTML, CSS]
categories: 前端
---
# 大部分的网站一般都有评论功能或留言功能，或类似可以让用户写东西的地方。

## 如果后台不经过处理，又把数据返回前端，这就会出问题了。网页解析器会把用户的信息也当成html代码给解析了。
## 如果用户写的是一些恶意的 js 脚本这是很危险的。专业术语叫：XSS 攻击

<!--more-->

## 一、举个例子：假设后台和前台都没有对用户的信息，进行处理。我们输入如下的代码：
```
<script>
   var body= document.body;             
   var img = document.createElement("img"); 
   img.setAttribute('style','width:100%;height:100%;z-index:99999;position:fixed;top:0px;')
   img.src = "https://www.baidu.com/img/bd_logo1.png";  
   body.appendChild(img); 
</script> 
```

#### 整个页面被整个图片覆盖掉
#### 如果是其他的恶意攻击，是可以入侵到你的服务器然后获取到shell 。
## 二、解决方法：
### 1、前端过滤
##### (a)、javascript 原生方法
```
//转义  元素的innerHTML内容即为转义后的字符  
function htmlEncode ( str ) {  
  var ele = document.createElement('span');  
  ele.appendChild( document.createTextNode( str ) );  
  return ele.innerHTML;  
}  
//解析   
function htmlDecode ( str ) {  
  var ele = document.createElement('span');  
  ele.innerHTML = str;  
  return ele.textContent;  
} 
```
##### (b)、JQuery 方法
```
function htmlEncodeJQ ( str ) {  
    return $('<span/>').text( str ).html();  
}  
  
function htmlDecodeJQ ( str ) {  
    return $('<span/>').html( str ).text();  
} 
```
##### 调用方法
```
var msg1= htmlEncodeJQ('<script>alert('test');</script>');
var msg1= htmlEncode('<script>alert('test');</script>');
//结果变成：&lt;script&gt;alert('test');&lt;/script&gt;
```
### 2、后端过滤
> 我这里是JAVA 的，其他的另百度

#### (a)、java 一些框架自动工具类，
##### 比如：org.springframework.web.util.HtmlUtils
```
public static void main(String[] args) {
	String content = "<script>alert('test');</script>";
	System.out.println("content="+content);
	content = HtmlUtils.htmlEscape(content);
	System.out.println("content="+content);
	content = HtmlUtils.htmlUnescape(content);
	System.out.println("content="+content);
}
```
![](62904.png)

##### 但这样有个问题，就是它全部的html标签都不解析了。
##### 可能这不是你想要的，你想要的是一部分解析，一部分不解析。好看下面。

#### (b)、自己用正则来完成你的需求
> 下面给你demo ,根据你自己的需求来改就好了。

```java
package top.lrshuai.blog.util;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * 
 * @author lrshuai
 * @since 2017-10-13
 * @version 0.0.1
 */
public class HTMLUtils {
/**
 * 过滤所有HTML 标签
 * @param htmlStr
 * @return
 */
public static String filterHTMLTag(String htmlStr) {
	//定义HTML标签的正则表达式 
	String reg_html="<[^>]+>"; 
	Pattern pattern=Pattern.compile(reg_html,Pattern.CASE_INSENSITIVE); 
	Matcher matcher=pattern.matcher(htmlStr); 
	htmlStr=matcher.replaceAll(""); //过滤html标签 
	return htmlStr;
}

/**
 * 过滤标签，通过标签名
 * @param htmlStr
 * @param tagName
 * @return
 */
public static String filterTagByName(String htmlStr,String tagName) {
	String reg_html="<"+tagName+"[^>]*?>[\\s\\S]*?<\\/"+tagName+">";
	Pattern pattern=Pattern.compile(reg_html,Pattern.CASE_INSENSITIVE); 
	Matcher matcher=pattern.matcher(htmlStr); 
	htmlStr=matcher.replaceAll(""); //过滤html标签 
	return htmlStr;
}

/**
 * 过滤标签上的 style 样式
 * @param htmlStr
 * @return
 */
public static String filterHTMLTagInStyle(String htmlStr) {
	String reg_html="style=('|\")(.*?)('|\")";
	Pattern pattern=Pattern.compile(reg_html,Pattern.CASE_INSENSITIVE); 
	Matcher matcher=pattern.matcher(htmlStr); 
	htmlStr=matcher.replaceAll(""); //过滤html标签 
	return htmlStr;
}
	
/**
 * 替换表情
 * @param htmlStr
 * @param tagName
 * @return
 */
public static String replayFace(String htmlStr) {
	String reg_html="\\[em_\\d{1,}\\]";
	Pattern pattern =Pattern.compile(reg_html,Pattern.CASE_INSENSITIVE); 
	Matcher matcher=pattern.matcher(htmlStr);
	if(matcher.find()) {
		matcher.reset();
		while(matcher.find()) {
			String num = matcher.group(0);
			String number=num.substring(num.lastIndexOf('_')+1, num.length()-1);
			htmlStr = htmlStr.replace(num, "<img src='/face/arclist/"+number+".gif' border='0' />");
		}
	}
	return htmlStr;
}
	
	public static void main(String[] args) {
		String html = "<script>alert('test');</script><img src='/face/arclist/5.gif' border='0' /><div style='position:fixs;s'></div><style>body{color:#fff;}</style><Style>body{color:#fff;}</Style><STYLE>body{color:#fff;}</STYLE>";
		System.out.println("html="+html);
		html = HTMLUtils.filterTagByName(html, "style");
		System.out.println("html="+html);
		html = HTMLUtils.filterTagByName(html, "script");
		System.out.println("html="+html);
		html = HTMLUtils.filterHTMLTagInStyle(html);
		System.out.println("html="+html);
	}
	
}

```

##### 下班了，哪天有空再补充

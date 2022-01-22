---
title: Spring Boot (三)：Thymeleaf 的使用
date: 2017-07-29 00:26:36
updated: 2017-07-29 00:26:36
tags: [Spring Boot]
categories: Java
---
# Thymeleaf 的基本语法
#### Thymeleaf是Web和独立环境的现代服务器端Java模板引擎，能够处理HTML，XML，JavaScript，CSS甚至纯文本。
#### Thymeleaf的主要目标是提供一种优雅和高度可维护的创建模板的方式。为了实现这一点，它建立在自然模板的概念上，将其逻辑注入到模板文件中，不会影响模板被用作设计原型。这改善了设计的沟通，弥补了设计和开发团队之间的差距。
#### Thymeleaf也从一开始就设计了Web标准 - 特别是HTML5 - 允许您创建完全验证的模板，如果这是您需要的
#### springboot 用thymeleaf 还是挺不错的


##### (1)、字符串太多，显示...
```
# 这里的含义是 如果 atc.text 这个变量多余200个字符，后面显示...
<p th:text="${#strings.abbreviate(atc.text,200)}">内容内容内容</p>
```
##### (2)、数组判断是否为空
```
<div th:if="${#lists.isEmpty(arrays)} " class="blog-article">
```
##### (3)、request 获取绝对路径
```
<img th:src="${#httpServletRequest.getContextPath()}+${atc.img}" src="/images/logo.jpg">
```
##### (4)、session 对象
```
# 获取用户session 中的id
<input type="hidden" id="user_id" value="0" th:if="${not #lists.isEmpty(session.SESSION_USER)}" th:value="${session.SESSION_USER.user_id}" />
# session 为空时，user_id=0
<input type="hidden" id="user_id" value="0" th:if="${{'{#'}}lists.isEmpty(session.SESSION_USER)}" />
```

## 常用th标签
|标签|说明|例子|
|---|----|---|
|th:id	| 替换id| ```<input th:id="'xxx' + ${collect.id}"/> ```|
|th:text|文本替换	|```<p th:text="${collect.description}">description</p>```|
|th:utext|	支持html的文本替换|```<p th:utext="${htmlcontent}">conten</p>```|
|th:object	|替换对象|```<div th:object="${session.user}">``` |
|th:value|	属性赋值	|```<input th:value="${user.name}" />``` |
|th:with|	变量赋值运算|```	<div th:with="isEven=${prodStat.count}%2==0"></div>``` |
|th:style|	设置样式|```	th:style="'display:' + @{(${sitrue} ? 'none' : 'inline-block')} + ''"``` |
|th:onclick|	点击事件|```	th:onclick="'getCollect()'" ```|
|th:each|	属性赋值|```	tr th:each="user,userStat:${users}"> ```|
|th:if	|判断条件	|``` <a th:if="${userId == collect.userId}" > ```|
|th:unless|	和th:if判断相反	|```<a th:href="@{/login}" th:unless=${session.user != null}>Login</a>```|
|th:href	|链接地址|	```<a th:href="@{/login}" th:unless=${session.user != null}>Login</a> />``` |
|th:switch|	多路选择 配合th:case 使用	|```<div th:switch="${user.role}"> ```|
|th:case	|th:switch的一个分支	|``` <p th:case="'admin'">User is an administrator</p>```|
|th:fragment|	布局标签，定义一个代码片段，方便其它地方引用|```	<div th:fragment="alert">```|
|th:include	|布局标签，替换内容到引入的文件	|```<head th:include="layout :: htmlhead" th:with="title='xx'"></head> />``` |
|th:replace|	布局标签，替换整个标签到引入的文件|	```<div th:replace="fragments/header :: title"></div> ```|
|th:selected|	selected选择框 选中|```	th:selected="(${xxx.id} == ${configObj.dd})"```|
|th:src	|图片类地址引入	|```<img class="img-responsive" alt="App Logo" th:src="@{/img/logo.png}" />``` |
|th:inline|	定义js脚本可以使用变量	|```<script type="text/javascript" th:inline="javascript">```|
|th:action|	表单提交的地址	|```<form action="subscribe.html" th:action="@{/subscribe}">```|
|th:remove|	删除某个属性	|```<tr th:remove="all">``` 1.all:删除包含标签和所有的孩子。2.body:不包含标记删除,但删除其所有的孩子。3.tag:包含标记的删除,但不删除它的孩子。4.all-but-first:删除所有包含标签的孩子,除了第一个。5.none:什么也不做。这个值是有用的动态评估。|
|th:attr|	设置标签属性，多个属性可以用逗号分隔	|比如```<p th:attr="src=@{/image/aa.jpg},title=${title}">内容</p>```，这样如果${title}='这个是title' 则结果就是`<p src="/image/aa.jpg" title="这个是title">内容</p>`|



> 参考文献：http://www.thymeleaf.org/doc/tutorials/3.0/usingthymeleaf.html

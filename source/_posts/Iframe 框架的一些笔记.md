---
title: Iframe 框架的一些笔记
date: 2017-08-25 15:22:59
updated: 2017-08-25 15:22:59
tags: [Javascript, HTML]
categories: 前端
---
## 一、Iframe 的自适应方法：
```html
<iframe name="mainFrame" id="mainBodyFrame" src="/main" 
frameborder="0" scrolling="no" width="100%" height="900px" onload="setIframeHeight(this)"></iframe>
 
 
<script type="text/javascript">
     
//iframe 自适应
function setIframeHeight(iframe) {
    if (iframe) {
        var iframeWin = iframe.contentWindow
                || iframe.contentDocument.parentWindow;
        if (iframeWin.document.body) {
            iframe.height = iframeWin.document.documentElement.scrollHeight
                    || iframeWin.document.body.scrollHeight;
        }
    }
};
 
//mainBodyFrame就是iframe 的id 
window.onload = function() {
    setIframeHeight(document.getElementById('mainBodyFrame'));
};
</script>
```

<!--more-->

## 二、刷新页面
```html
//刷新本页：
<script language=javascript>window.location.href=window.location.href;</script>
 
//刷新父页：
<script language=javascript>opener.location.href=opener.location.href;</script>
 
//转到指定页:
<script language=javascript>window.location.href='yourpage.aspx';</script>
```
## 三、top.location.href和localtion.href有什么不同
```html
//在顶层页面打开url（跳出框架）
top.location.href=”url”          
 
// 仅在本页面打开url地址
self.location.href=”url”        
 　　
//在父窗口打开Url地址 　
parent.location.href=”url” 
　
//用法和self的用法一致  
this.location.href=”url”
```

#### top.location.href 可以用在当后台使用iframe 框架作为主体显示部分时，当用户身份过期，需要登陆，登录页面会在iframe显示，而登录成功后还是在ifrmae 中显示，如下图：

![](1504841712589094135.png)
![](1504841825227030037.png)

### 解决方法：
```html
<script type="text/javascript">
    //TOCMAT重启之后 在ifrme框架登录后，重新跳出框架显示页面
    if (window != top) {
        top.location.href = location.href;
    }
</script>
```

## 四、jquery动态加载html页面
```html
<script type="text/javascript">
 
$(function() {
    //在id为admin-left 中加载left.html页面
    $.get("/include/left.html", function(data) {
        $("#admin-left").html(data);
    });
      
})
 
</script>
```

---
title: 正则去掉html 标签和样式，只留文本
date: 2017-07-23 21:51:19
tags: [JavaScript, HTML]
categories: Java
---
## 在工作中遇到，记录一下
### demo
```
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <title>正则，去掉所有html标签，只留文本</title>
    <link rel="stylesheet" href="">
</head>
<body>
    <textarea name="content" cols="200"  rows="10" id="htmlcontent">这里写html文本</textarea><br><br><br>
    <input type="button" name="change" value="生成" id="change"><br>
    <textarea name="text" cols="200"  rows="10" id="result"></textarea><br><br>
    <script type="text/javascript">
 
        document.getElementById('change').onclick=function(){
            var htmlcontent = document.getElementById("htmlcontent").value;
            var result=delHTMLTag(htmlcontent);
            document.getElementById("result").value =result ;
        }
         
        //把html代码  变成文本，正则的意思是以 < 开头和 > 结尾的内容全部替换为空
        function delHTMLTag(htmlStr){
            htmlStr = htmlStr.replace(/<[^>]+>/g,"");
            return htmlStr;
        }
    </script>
</body>
</html>
```

## 核心是 delHTMLTag 方法
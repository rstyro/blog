---
title: FileReader 获取图片BASE64 代码 并预览
date: 2017-09-12 15:32:25
tags: [JavaScript, HTML]
categories: Java
---
# FileReader 获取图片的base64 代码  并预览
### FileReader ，老实说我也不怎么熟悉。在这里只是记录使用方法。

|方法名|参数| 描述|
|---|--|--|
|abort| none|中断读取|
|readAsBinaryString|file（blob）|将文件读取为二进制码|
|readAsDataURL|file（blob）|将文件读取为 DataURL|
|readAsText|file, （blob）|将文件读取为文本|


### FileReader 包含了一套完整的事件模型，用于捕获读取文件时的状态
|事件|描述|
|---|--|
|onabort|中断时触发|
|onerror|出错时触发|
|onload|文件读取成功完成时触发|
|onloadend|读取完成触发，无论成功或失败|
|onloadstart|读取开始时触发|
|onprogress|读取中|



#### 文件一旦开始读取，无论成功或失败，实例的 result 属性都会被填充。如果读取失败，则 result 的值为 null ，否则即是读取的结果，绝大多数的程序都会在成功读取文件的时候，抓取这个值。

## demo
```
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <title></title>
    <link rel="stylesheet" href="">
</head>
<body>
<input type="file" class="file" name="imgfile" id="imgfile" placeholder="请选择文件">
<img src="" id="showImg" >
 
<script src="http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js" type="text/javascript"></script>
<script>
var input = document.getElementById("imgfile");
//检测浏览器是否支持FileReader
 if (typeof (FileReader) === 'undefined') {
     result.innerHTML = "抱歉，你的浏览器不支持 FileReader，请使用现代浏览器操作！";
     input.setAttribute('disabled', 'disabled');
 } else {
 //开启监听
     input.addEventListener('change', readFile, false);
 }
function readFile() {
    var file = this.files[0];
 
     //限定上传文件的类型，判断是否是图片类型
     if (!/image\/\w+/.test(file.type)) {
         alert("只能选择图片");
         return false;
    }
     var reader = new FileReader();
     reader.readAsDataURL(file);
     reader.onload = function (e) {
       base64Code=this.result;
        //把得到的base64赋值到img标签显示
       $("#showImg").attr("src",base64Code);
     }
  }
</script>
   
  
</body>
</html>
```


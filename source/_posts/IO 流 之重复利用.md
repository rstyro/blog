---
title: IO 流 之重复利用
date: 2017-07-22 21:48:52
updated: 2017-07-22 21:48:52
tags: [计算机基础, Java]
categories: Java
---
## InputStream 之重复利用
> 有时我们需要重复利用输入流，比如图片上传时获取 图片的宽高...... 还有很多.........

### 1、代码示例
```java
// 拿到上传文件的输入流
InputStream in = files[i].getInputStream();
ByteArrayOutputStream baos = new ByteArrayOutputStream();  
byte[] buffer = new byte[1024];  
int len;  
while ((len = in.read(buffer)) > -1 ) {  
    baos.write(buffer, 0, len);  
}  
baos.flush();                
InputStream input = new ByteArrayInputStream(baos.toByteArray());
```

<!--more-->

## 2、重复利用
##### 如果需要 Inputstream,通过 new ByteArrayInputStream(baos.toByteArray())   就可以重复取了，想取多少就取多少。

## 3、通过Inputstream 获取图片的宽高
> 一般做图片上传之类的用得挺多的

```java
int height = "0";
int width = "0";
BufferedImage bi = ImageIO.read(new ByteArrayInputStream(baos.toByteArray()));
if (bi != null) {
    height = bi.getHeight();
    width = bi.getWidth();
    System.out.println("height=" + height + ",width=" + width);
}
```

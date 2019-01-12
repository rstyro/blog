---
title: 网页使用WebP格式图片与图片压缩
date: 2017-10-14 16:56:29
tags: [干货, HTML]
categories: 前端
---
# 一、WebP
#### WebP是Google开发的一种新的图片格式，它支持有损压缩、无损压缩和透明度，压缩后的文件大小比JPEG、PNG等都要小。所以可以节省带宽，减少页面载入时间，节省用户的流量。
### 所以网页使用webp 格式的图片是一个很好的方案。
#### 但可惜的是 不是所有的浏览器都兼容，`目前只有Chrome、Opera浏览器 兼容`。

## 解决方法：
### 1、让能兼容webp 的使用webp格式，不能兼容的就用普通格式。
#### 这就用到html5 的新标签 `<picture>` 
> `<picture>`它允许在其内部设置多个`<source>`标签，以指定不同的图像文件名，根据不同的条件进行加载；

```
<picture class="picture">
  <source type="image/webp" srcset="image.webp">
  <img class="image" src="image.jpg">
</picture>
```
##### 上面的代码: 如果浏览器支持WebP格式，就会加载image.webp，否则会加载image.jpg。
### 2、在线图片转换为webp格式地址:[https://www.upyun.com/webp](https://www.upyun.com/webp)

# 二、图片压缩
## 网站图片太大，影响访问速度，那就压一下把。
### 下面介绍几个网址：

#### 1、[TinyPNG](https://tinypng.com/)
#### 2、[ImageOptim](https://imageoptim.com/api)
#### 3、[RIOT](http://luci.criosweb.ro/riot/)

##### 暂时就这几个吧，哪天发现其他的再补充！！

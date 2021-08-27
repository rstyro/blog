---
title: Javascript一个字一个字显示效果实现
date: 2021-08-27 18:42:28
updated: 2021-08-27 18:42:28
tags: [Javascript]
categories: 前端
---

### 一、如题
+ 尝试用原生js，实现一下标题描述的效果
+ 不知道还有没有更好的方法，如果各位有更好的方法，欢迎留言。
+ 代码如下，用到了定时器。

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>测试</title>

    <style>
        .main{
            width: 1120px;
            margin: 0px auto;
        }

        .main .content-container p{
            display: none;
        }
        .main .content-container .title{
            font-size: 20px;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <div class="main">
        <div class="content-container">
            <p>我是谁？？？？</p>
            <p>你是谁？？？？</p>

            <p class="title">赤壁</p>
            <p>折戟沉沙铁未销，</p>
            <p>自将磨洗认前朝。</p>
            <p>东风不与周郎便，</p>
            <p>铜雀春深锁二乔</p>
        </div>

        <br/>
        <br/>
        <br/>
        <div class="content-container">
            <p class="title">《落花》</p>
            <p>高阁客竟去，</p>
            <p>小园花乱飞。</p>
            <p>参差连曲陌，</p>
            <p>迢递送斜晖。</p>
        </div>

    </div>

<script>
    let initTime = 0;
    let speed = 50;
    window.onload=function (){
        let container =document.getElementsByClassName("content-container");
        for (let i = 0; i < container.length; i++) {
            let childNodes = container[i].getElementsByTagName("p");
            for (let j = 0; j < childNodes.length; j++) {
                const value = childNodes[j].innerText;
                printf(childNodes[j],initTime);
                initTime+=value.length*speed;
            }
        }
    }

    function printf(el,addTime){
        const value = el.innerText;
        let arr = value.split('');
        for (let j = 0; j < arr.length; j++) {
            setTimeout(()=>{
                el.style.setProperty('display', 'block', 'important');
                el.innerText=arr.slice(0,j+1).toString().replaceAll(",",'');
            },speed*j+addTime)
        }

    }
</script>

</body>
</html>
```


示例图如下：

![](view.gif)
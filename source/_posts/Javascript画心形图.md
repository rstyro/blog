---
title: Javascript画心形图
date: 2021-08-30 10:12:54
updated: 2021-08-30 10:12:54
tags: [Javascript]
categories: 前端
---

### 一、好看的心形图♥

+ 使用到的函数

```
x=16 * (sin(t)) ^ 3
y=13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t)
```

![](heart.png)

<!--more-->

```
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>测试</title>

    <style>

        body{
            background: #ffd;
        }
        .main{
            width: 500px;
            margin: 0px auto;
            padding: 0;
        }
    </style>
</head>
<body>
    <div class="main">
        <canvas id="heart" width="600" height="600" ></canvas>
    </div>

<script>

    let canvas = document.querySelector('canvas');
    let context = canvas.getContext('2d');
    console.log(context)
    context.lineWidth = 2;
    // 设置画布的 (0,0) 点
    context.translate(300,300);
    // 弧度
    let t=0;
    // 每次增长多少弧度
    let vt = 0.01;
    // 最大弧度
    let maxt = 2*Math.PI;
    // 根据增长弧度得循环次数
    let maxi = Math.ceil(maxt/vt);
    let pointArr=[];
    // 步长越大，画的形状越大
    let size = 15;
    let x=0;
    let y=0;
    for(let i=0;i<=maxi;i++){
        // x=16 * (sin(t)) ^ 3;
        let x = 16 * Math.pow(Math.sin(t),3);
        // y=13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t)
        let y = 13 * Math.cos(t) - 5 * Math.cos(2 * t) -2 * Math.cos(3 * t)- Math.cos(4 * t);
        t+=vt;
        pointArr.push([x*size,-y*size]);
    }
    context.moveTo(pointArr[0][0],pointArr[0][1]);

    let idx = 2;
    context.fillStyle='#c00';
    context.strokeStyle='#c00';
    let tt = '';

     slowly();
    //draw();
    function slowly() {
        x = pointArr[idx][0];
        y = pointArr[idx][1];
        context.lineTo(x,y);
        if(idx+1 >= pointArr.length){
            context.fill();
            clearTimeout(tt);
        } else {
            idx++;
            clearTimeout(tt);
            tt = setTimeout("slowly()",2);
            context.stroke();
        }
    }

    function draw(){
        context.fillStyle='#c00';
        for(let i=1;i<pointArr.length;i++){
            x = pointArr[i][0];
            y = pointArr[i][1];
            context.lineTo(x,y);
        }
        context.fill();
    }

</script>

</body>
</html>
```

+ 示例图

![](heart3.png)

### 二、笛卡尔心形函数

+ 笛卡尔函数如下：

```
x=size*(2*sin(t)+sin(2*t))
y=size*(2*cos(t)+cos(2*t))
```

+ size是步长，值越大图案越大
+ t是弧度，从`0 - 2Π`


```
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>笛卡尔心形线</title>

    <style>

        body{
            background: #ffd;
        }
        .main{
            width: 500px;
            margin: 0px auto;
            padding: 0;
        }
        #heart{
            /*background: #ccc;*/
        }
    </style>
</head>
<body>
<div class="main">
    <canvas id="heart" width="600" height="600" ></canvas>
</div>

<script>

    let canvas = document.querySelector('canvas');
    let context = canvas.getContext('2d');
    console.log(context)
    context.lineWidth = 2;
    // 设置画布的 (0,0) 点
    context.translate(300,300);
    // 弧度
    let t=0;
    // 每次增长多少弧度
    let vt = 0.01;
    // 最大弧度
    let maxt = 2*Math.PI;
    // 根据增长弧度得循环次数
    let maxi = Math.ceil(maxt/vt);
    let pointArr=[];
    // 步长越大，画的形状越大
    let size = 100;
    let x=0;
    let y=0;
    for(let i=0;i<=maxi;i++){
        // x=a*(2*sin(t)+sin(2*t))
        x=size*(2*Math.sin(t)+Math.sin(2*t));

        // y=a*(2*cos(t)+cos(2*t))
        y=size*(2*Math.cos(t)+Math.cos(2*t));

        t+=vt;
        pointArr.push([x,y]);
    }
    context.moveTo(pointArr[0][0],pointArr[0][1]);

    let idx = 2;
    context.fillStyle='#c00';
    context.strokeStyle='#c00';
    let tt = '';

    slowly();
    //draw();
    function slowly() {
        x = pointArr[idx][0];
        y = pointArr[idx][1];
        context.lineTo(x,y);
        if(idx+1 >= pointArr.length){
            context.fill();
            clearTimeout(tt);
        } else {
            idx++;
            clearTimeout(tt);
            tt = setTimeout("slowly()",2);
            context.stroke();
        }
    }

    function draw(){
        context.fillStyle='#c00';
        for(let i=1;i<pointArr.length;i++){
            x = pointArr[i][0];
            y = pointArr[i][1];
            context.lineTo(x,y);
        }
        context.fill();
    }

</script>

</body>
</html>
```

+ 示例图

![](heart2.png)

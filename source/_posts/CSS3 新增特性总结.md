---
title: CSS3 新增特性总结
date: 2017-10-11 16:54:05
updated: 2017-10-11 16:54:05
tags: [CSS]
categories: 前端
---
# CSS3 新特性
## 一、transform
### 1、平移效果：transform:translate(100px,200px)
##### 这一行代码表示x轴方向向右平移100像素，y轴方向向下平移200像素。如果只想在某一个轴上平移，那么另外一个设置为0即可，这样很方便，也容易记住，也可以使用单独提供的translateX或者translateY。如果只传入一个参数，则表示在x轴向右平移的距离

<!--more-->

### 2、缩放效果：transform:transtale(1.5,2.5)
##### 如果是1则是没有缩放比例，如果超过1就是放大，小于1就是缩小。两个参数分别代表x轴方向和y轴方向。如果只传入一个参数，则是x轴和y轴方向同时按传入的参数比例进行缩放。也可以使用单独提供的scaleX和scaleY

### 3、旋转效果: transform:tranrotate(90deg)
##### 只需要一个参数，就是要旋转的角度。默认的情况下是以中心点为基准点，正角度是顺时针旋转，负角度是逆时针旋转

### 4、倾斜效果： transform:skew(45deg,90deg)
##### 这个与平移相似，如果传入一个参数，只表示在x轴方向的倾斜。同样如果只需要设置一个方向的倾斜，另一个设置为0deg即可，不需要使用skewX和skewY


> 所有属于transform的效果可以写在一起，中间用空格分隔开

## 二、设置圆角：
#### `border-radius: 5px 4px 3px 2px;` /* 四个半径值分别是左上角、右上角、右下角和左下角，顺时针 */

## 三、设置阴影：
#### `box-shadow`: X轴偏移量 Y轴偏移量 [阴影模糊半径] [阴影扩展半径] [阴影颜色] [投影方式`;

## 四、线性渐变背景:
#### `background-image:linear-gradient(to top,red,yellow);`
> 第一个参数是指渐变的方向。to top:从下到上;to top left:右下角到左下角。
> 球形渐变：radial-gradient（）,参数配置比较复杂，这里就先不介绍

## 五、单行文本溢出显示省略号：
```
text-overflow:ellipsis; /* ellipsis表示显示省略标记，clip表示剪切  */  
overflow:hidden;   
white-space:nowrap; /* 强制文本在一行内显示 */  
```

## 六、过渡属性transition
#### transition-property:指定过渡或动态模拟的css属性。
#### transition-duration:指定完成过渡所需的时间。
#### transition-timing-function:指定过渡的缓动函数,如下： 

|值|描述|
|:---:|--|
|linear	|规定以相同速度开始至结束的过渡效果（等于 cubic-bezier(0,0,1,1)）。|
|ease	|规定慢速开始，然后变快，然后慢速结束的过渡效果（cubic-bezier(0.25,0.1,0.25,1)）。|
|ease-in|	规定以慢速开始的过渡效果（等于 cubic-bezier(0.42,0,1,1)）。|
|ease-out	|规定以慢速结束的过渡效果（等于 cubic-bezier(0,0,0.58,1)）。|
|ease-in-out	|规定以慢速开始和结束的过渡效果（等于 cubic-bezier(0.42,0,0.58,1)）。|
|cubic-bezier(n,n,n,n)|	在 cubic-bezier 函数中定义自己的值。可能的值是 0 至 1 之间的数值。|

## 七、动画 -webkit-keyframes
```css
/*这里是使一个div 进行旋转动画*/
#divId{
	-webkit-animation:myRotate 3s infinite linear ;
}

@-webkit-keyframes myRotate {
    0%{
        
       -webkit-transform: rotate(0deg);
    }
    50%{
        -webkit-transform: rotate(180deg);
    }
    100%{
        -webkit-transform: rotate(360deg);
    }
}
```

## 八、各个属性 demo 集合
```html
<!DOCTYPE html>
<html>
<meta charset="UTF-8">
<title>Demo</title>
<meta name="viewport" content="width=device-width, initial-scale=1" />
<head>
    <style>
   
        .demo{
            -webkit-perspective: 800px;
            -webkit-perspective-origin: 50% 50%;           
            overflow:hidden;
        }
        .pageGroup{
            position: relative;
            margin:0px auto;
            height:400px;
            width:400px;
            -webkit-transform-style:preserve-3d;
        }
        .page{
            
            height:360px;
            width:360px;
            padding:20px;
            background-color: black;
            color:white;
            font-weight:bold;
            font-size:360px;
            line-height:360px;
            text-align:center;
			
            position:absolute;
     
        }
        #page1  {
			-webkit-transform-origin:bottom;
            -webkit-transition:-webkit-transform 0.5s linear;
			-webkit-transform: rotateX(0deg);
        }
        #page2,#page3 ,#page4 ,#page5 ,#page6  {
			-webkit-transform-origin:bottom;
            -webkit-transition:-webkit-transform 0.5s linear;
            -webkit-transform: rotateX(90deg);      
        }
		
		#bookpage  {
			-webkit-transform-origin:left;
            -webkit-transition:-webkit-transform 0.5s linear;
        }
        #bookpage2,#bookpage3 ,#bookpage4 ,#bookpage5 ,#bookpage6  {
			-webkit-transform-origin:left;
            -webkit-transition:-webkit-transform 0.5s linear;
			 -webkit-transform: rotateY(0deg); 
        }
       
        #op{
            text-align:center;
			margin:40px auto;
        }
          
		#mypic{
			width:200px;
			height:200px;
			margin:20px auto;
		}
		#mypic img{
			height:100%;
			border-radius: 50%;
		}
		#mypic img:hover{
			transform:rotate(360deg) ;
			-ms-transform:rotate(360deg); 	/* IE 9 */
			-moz-transform:rotate(360deg); 	/* Firefox */
			-webkit-transform:rotate(360deg); /* Safari 和 Chrome */
			-o-transform:rotate(360deg);
			-webkit-transition-duration: 3s;
		}
		
		.widthDemo{
			width:200px;
			height:100px;
			margin:40px 0px;
			background:#ccc;
			text-align:center;
		}
		#demo1:hover{
			width:1100px;
			transition:width 2s linear;
		}
		#demo2:hover{
			width:1100px;
			transition:width 2s ease;
		}
		#demo3:hover{
			width:1100px;
			transition:width 2s ease-in;
		}
		#demo4:hover{
			width:1100px;
			transition:width 2s ease-out;
		}
		
		#colorDiv{
			width:300px;
			height:300px;
			background:blue;
			margin:40px auto;
		}
		#colorDiv:hover{
			background:red;
			transition:background 5s ;
		}
    </style>

  
</head>
<body>
<body>
<div class="demo">
    <div class="pageGroup">
        <div class="page" id="page1">1</div>
        <div class="page" id="page2">2</div>
        <div class="page" id="page3">3</div>
        <div class="page" id="page4">4</div>
        <div class="page" id="page5">5</div>
        <div class="page" id="page6">6</div>
    </div>
</div>
<div id="op">
       <a href="javascript:prev()">上一页</a> <a href="javascript:next()">下一页</a>&nbsp; 
</div>

<div class="demo">
    <div class="pageGroup">
        <div class="page" id="bookpage1">6</div>
        <div class="page" id="bookpage2">5</div>
        <div class="page" id="bookpage3">4</div>
        <div class="page" id="bookpage4">3</div>
        <div class="page" id="bookpage5">2</div>
        <div class="page" id="bookpage6">1</div>
    </div>
</div>
<div id="op">
    <a href="javascript:prev2()">上一页</a> <a href="javascript:next2()">下一页</a>&nbsp; 
</div>

<div id="mypic">
	<img src="http://www.lrshuai.top/images/logo.jpg"/>
</div>

<div class="widthDemo" id="demo1">linear 匀速</div>
<div class="widthDemo" id="demo2">ease 慢-快-慢</div>
<div class="widthDemo" id="demo3">ease-in 慢开始-快结束</div>
<div class="widthDemo" id="demo4">ease-out 慢-快-慢</div>

<div id="colorDiv"></div>
<script>
curIndex=1;
function prev(){
		if( curIndex == 1){
			return;
		}
			
		var curPage = document.getElementById("page" + curIndex);
		curPage.style.webkitTransform = "rotateX(90deg)";	
		curIndex --;
		var nextPage = document.getElementById("page" + curIndex);
		nextPage.style.webkitTransform = "rotateX(0deg)";	
		
		
}
function next(){
		if( curIndex == 6){
			return;
		}
			
		var curPage = document.getElementById("page" + curIndex);
		curPage.style.webkitTransform = "rotateX(-90deg)";
		
		curIndex ++;
		var nextPage = document.getElementById("page" + curIndex);
		nextPage.style.webkitTransform = "rotateX(0deg)";	
		
		
}

var bookindex=6;
function next2(){
		if( bookindex == 1){
			return;
		}
		var curPage = document.getElementById("bookpage" + bookindex);
		curPage.style.webkitTransform = "rotateY(-270deg)";
		bookindex --;

		
}
function prev2(){
		if( bookindex == 6){
			return;
		}
		bookindex ++;
		var curPage = document.getElementById("bookpage" + bookindex);
		curPage.style.webkitTransform = "rotateY(0deg)";

}

</script>
</body>
</html>
```



> 正文到此结束，谢谢观看，觉得有用，点个赞可好！

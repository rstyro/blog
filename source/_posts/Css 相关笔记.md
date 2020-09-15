---
title: Css 相关笔记
date: 2017-11-21 15:24:47
tags: [CSS]
categories: 前端
---
# 笔记

## 一、滚动条样式
```css
/* 滚动条样式 */	
::-webkit-scrollbar {  
    width: 5px;  
    height: 5px;  
    background-color: #111;
}  
/*定义滚动条轨道 内阴影+圆角*/  
::-webkit-scrollbar-track {  
    -webkit-box-shadow: inset 0 0 6px rgba(0,0,0,0.3);  
    background-color: rgba(255,255,255,0.5);  
}    
/*定义滑块 内阴影+圆角*/  
::-webkit-scrollbar-thumb {  
    border-radius: 10px;  
    -webkit-box-shadow: inset 0 0 6px rgba(0,0,0,.3);  
    background-color: rgba(20,200,230,0.5);  
}  
/*滑块效果*/
::-webkit-scrollbar-thumb:hover{
	border-radius: 5px;
	-webkit-box-shadow: inset 0 0 5px rgba(0,0,0,0.2);
	background: rgba(0,0,0,0.4);
}
/*IE滚动条颜色*/
html {
    scrollbar-face-color:#bfbfbf;/*滚动条颜色*/
    scrollbar-highlight-color:#000;
    scrollbar-3dlight-color:#000;
    scrollbar-darkshadow-color:#000;
    scrollbar-Shadow-color:#adadad;/*滑块边色*/
    scrollbar-arrow-color:rgba(0,0,0,0.4);/*箭头颜色*/
    scrollbar-track-color:#eeeeee;/*背景颜色*/
}
```

## 二、绘制三角形
```css
/*
	主要样式
	border-width  是改变三角形的大小
	border-color 4个值是表示 上右下左 四个方向的颜色，transparent 是透明。只要指定3个透明即可实现三角形的效果
*/
.main em.left{
		width:0px;
		height:0px;
		border-width:10px;
		border-style:solid;
		border-color:transparent  #111 transparent  transparent ;
		position: absolute;
	}
	
```
## 三、css 样式优先级，强制覆盖，！important
```
.menu-active{
	border-color: #EE4977 !important; 
	background  : #5b5b5b !important;
}
```

## 四、input 与按钮之类的对齐
```
vertical-align:top;
```
---
title: Anki选择题卡片制作详解
date: 2020-07-20 14:46:08
updated: 2020-07-20 14:46:08
tags: [Anki]
categories: 其他
---
### 一、Anki是什么？
Anki是一个辅助记忆软件，它非常利于复习记忆，它可以按照艾宾浩斯遗忘曲线，给你安排合理的复习频率，就像你使用背单词软件时的操作一样。
一次记忆一个卡片上的一个小知识点，记得牢，而且能够充分利用碎片时间。容易忘记、重复复习过于熟悉的，这些小问题都可以解决。

### 二、Anki如何下载与安装？
下载与安装很简单，傻瓜式安装，就是一直点下一步即可。
Anki中国地址：[http://www.ankichina.net/](http://www.ankichina.net/) 或者这个网址：[https://apps.ankiweb.net/](https://apps.ankiweb.net/)
往下看有各个端的下载链接。

### 三、Anki怎么用？
这个我还真不想说（-_-因为我也是刚刚用的，而且还是被逼着使用一下。）。步骤如下：
- 1、创建一个记忆库
记忆库就相当与我们的一本笔记，笔记里面可以写很多内容。可以创建多个记忆库，记忆库就相当于笔记分类.
- 2、添加卡片
卡片就相对与我们的笔记(记忆库)内容，一个卡片相当于一个知识点，可以把卡片当成一本笔记本的一页笔记内容
- 3、卡片内容
卡片默认有正反面，正面就是问题，反面是隐藏的存放答案。当我们学习的时候可以显示答案看我们是否作对题目
- 4、开始学习
卡片制成(也就是把卡片添加进记忆库)之后就可以开始学习了。
- 5、卡片的级别
1、生疏/错误：你一看到就知道自己没见过或者见过也忘了。
2、困难/模糊：你用力想能记起来一点，但不完全。
3、犹豫/想起：你仔细想，还是能够回忆出来。
4、顺利/正确：没什么难度，基本熟悉了。

> 这样就算是入门Anki使用方法了

### 四、Anki怎么制作选择题卡片
本文重点，要想弄好看的模板得需要写点HTML代码，如果你不会写代码也没关系，可以用我写好的代码。
而你只需要自己改皮肤即可，改皮肤只需要改几行代码这样子。先看看成品
![正面展示](show1.png)
正确时显示如下
![正确显示](show2.png)
错误时显示如下
![错误显示](show3.png)
- 1、修改基础卡片类型的字段
操作步骤如下图
![](1.png)
![](2.png)
![](3.png)
- 2、添加问题与答案解析
如下图，我随便网上找的题目
![](4.png)
- 3、编辑卡片
![](5.png)
都是空白的，下面开始写代码
- 4、修改卡片的正反面模板
![](6.png)
写完代码之后就显示如上图所示。下面给出完整的代码：
- 5、正面模板的代码
把它全部复制到正面模板的位置。
```html
<div id="classify" class="classify">单选题：</div>
<div class="text">{{Question}}</div>
{{#Options}}
<ol id="optionList" class="options"></ol>
<div id="options" style="display:none">{{Options}}</div>
<div id="answer" style="display:none">{{text:Answer}}</div>
<div id="checkAns" ></div>
<div id="countDown" ></div>
{{/Options}}
<style>
    #countDown{
        position: absolute;
        top:50%;
        left: 30%;
        font-size: 25px;
    }
</style>
<script>
    initOptions();
	// 倒计时的结束时间，改成你自己的
    var endTime="2020/08/29 00:00:00";
    countDown(endTime);
    function countDown(endTime) {
        var nowtime = new Date();
        var endtime = new Date(endTime);
        var lefttime = parseInt((endtime.getTime() - nowtime.getTime()) / 1000);
        var d = parseInt(lefttime / (24*60*60))
        var h = parseInt(lefttime / (60 * 60) % 24);
        var m = parseInt(lefttime / 60 % 60);
        var s = parseInt(lefttime % 60);
        d = addZero(d)
        h = addZero(h);
        m = addZero(m);
        s = addZero(s);
        document.getElementById("countDown").innerHTML = `考试倒计时  ${d}天 ${h} 时 ${m} 分 ${s} 秒`;
        //document.getElementById("countDown").innerHTML = `考试倒计时  ${d}天 `;
        if (lefttime <= 0) {
            document.getElementById("countDown").innerHTML = "考试已结束";
            return;
        }
        setTimeout(function(){countDown(endTime)}, 1000);
    }
    function addZero(i) {
        return i < 10 ? "0" + i: i + "";
    }
</script>
```
可能刚放进去的时候会报错不用理会，因为我们还没有填写中间的分享格式刷代码
- 6、中间部分，格式刷-卡片格式共享 代码
```html
.card{
    font-family:Arial;
    font-size:22px;
    text-align:left;
    color:#fff;
    background-color:#222;
}
<style>
    *{
        text-align:left;
    }
    div{
        margin:5px auto;
    }
    .classify{
    }
    .text{
        text-align:left;
    }
    .cloze {
        font-weight:bold;
        color:#a6e22e;

    }
    .cloze_line{
        font-weight:bold;
        color:#a6e22e;
        text-decoration: underline;
    }
    .wrong {
        font-weight:bold;
        color:#f92672;
        text-decoration:line-through;
    }
    .options {
        list-style:upper-latin;
    }
    .options * {
        cursor:pointer;
    }
    .options *:hover {
        font-weight:bold;
        color: #a6e22e;
    }

    .options input[name="options"] {
        display:inline;
    }
    .sformat{
        display: inline-block;
        margin-left: 100px;
    }
    #performance {
        text-align:center;
        margin-top:10px;
    }
    .analyze{
        margin-top:15px;
        font-size:20px;
        text-align:left;
    }
</style>
<script>
    if (!window.gData) {
        window.gData = {
            clickedValues: [],
            total: 0,
            correct: 0,
            score: 0,
            sum: 0,
            list: '',
            correctanswer: [],
            rsltanswer: []
        }
    }
    var gData = window.gData;
    // 显示选项
    function initOptions() {
        var optionList = document.getElementById("optionList"),
            classify = document.getElementById("classify"),
            options = document.getElementById("options"),
            answer = document.getElementById("answer");
        var correctanswer = answer.innerText.toUpperCase().match(/[A-Fa-f]/g);
        correctanswer.length > 1 && (classify.innerText = "多选题：");
        gData.correctanswer=correctanswer;
        options = options.innerHTML,
            options = options.replace(/<\/?div>/g, "\n"),
            options = options.replace(/\n+/g, "\n"),
            options = options.replace(/<br.*?>/g, "\n"),
            options = options.replace(/^\n/, ""),
            options = options.replace(/\n$/, ""),
            options = options.split(/(\n|\r\n)/g).filter(function(e) {
                return "\n" !== e && "\r\n" !== e && "" !== e
            }) || [];
        var indexs = [];// 存随机数的
        gData.rsltanswer=[];//重置，此参数为乱序后的正确答案
        gData.clickedValues=[];
        for(var key=0;key<options.length;key++){
            var randomNum=getRandomNum(indexs,options.length); //随机
            // var randomNum=key; //不要随机了
            var li ='';
            if(correctanswer.indexOf(String.fromCharCode(randomNum + 65)) != -1){
                gData.rsltanswer.push(String.fromCharCode(key + 65));
                li=getLiElement(options[randomNum],String.fromCharCode(key + 65),"optionTrue")
            }else{
                li=getLiElement(options[randomNum],String.fromCharCode(key + 65),"optionFalse")
            }
            optionList.appendChild(li);
        }
        gData.list=optionList.innerHTML;
        gData.total++;
    }

    // 获取随机数，乱序答案时需要
    function getRandomNum(indexs,number) {
        var num;
        do {
            num = Math.random() * number;
            num = Math.floor(num);
            if (indexs.join().indexOf(num.toString()) == -1) {
                indexs.push(num);
                break;
            }
        } while (true)
        return num;
    }

    // 点击选项事件
    function choice(li){
        var key = li.getAttribute("id");
        var input = document.getElementById("input"+key);
        var inputType = input.getAttribute("type");
        input.checked=!input.checked;
        if("checkbox" == inputType){
            let delIndex =gData.clickedValues.indexOf(key);
            if(delIndex != -1){
                gData.clickedValues.splice(delIndex,1);
            }else{
                gData.clickedValues.push(key);
            }
        }else{
            gData.clickedValues=[];
            gData.clickedValues.push(key);
        }
    }

    // 创建li选项，key=第几个答案选项
    function getLiElement(value,key,liClass) {
        var liElement = document.createElement("li"),
            inputElement = document.createElement("input"),
            labelElement = document.createElement("label");
        inputElement.setAttribute("type", 1 === gData.correctanswer.length ? "radio": "checkbox");
        inputElement.setAttribute("name", "options");
        inputElement.setAttribute("id", "input"+key);
        labelElement.innerHTML=value;
        liElement.appendChild(inputElement);
        liElement.appendChild(labelElement);
        liElement.setAttribute("class", liClass);
        liElement.setAttribute("id", key);
        liElement.setAttribute("onclick", "choice(this)");
        return liElement;
    }
    function checkAnswer(arr1,arr2) {
        if(arr1.length != arr2.length)return false;
        if(arr2.sort().toString() != arr1.sort().toString()) return false;
        return true;
    }
</script>
```
讲道理，填完这个正面模板那边应该是不报错了。
- 7、反面模板的代码
```html
<div id="classify" class="classify">单选题：</div>
<div class="text">{{Question}}</div>
{{#Options}}
<ol class="options" id="optionList"></ol>
<div id="options" style="display:none">{{Options}}</div>
<div id="answer" style="display:none">{{text:Answer}}</div>
<div>
    <span id="result" class="cloze sformat"></span>
    <span  class="cloze sformat">正确答案：<b id="key" ></b></span>
    <span class="cloze sformat">你的答案：<b id="yourkey"></b></span>
</div>
{{/Options}}
{{#Analyze}}
<hr>
<div id="performance"> 正确率：100%</div><br>
<div class="analyze">解析:{{Analyze}}</div>
<div id="listText"></div>
{{/Analyze}}
<script>
    var classify = document.getElementById("classify"),
        performance = document.getElementById("performance"),
        result = document.getElementById("result"),
        key = document.getElementById("key"),
        yourkey = document.getElementById("yourkey"),
        optionOl = document.getElementById("optionList");
    gData.correctanswer.length > 1 && (classify.innerText = "多选题：");
    optionOl.innerHTML = gData.list;
    if(checkAnswer(gData.clickedValues,gData.rsltanswer)){
        gData.correct++;
        result.innerHTML="回答正确！！！";
    }else{
        yourkey.classList.add("wrong");
        result.classList.add("wrong");
        result.innerHTML="很遗憾，回答错误";
    }
    key.innerHTML = gData.rsltanswer.sort().toString();
    yourkey.innerHTML = gData.clickedValues.sort().toString();
    performance.innerHTML='本次做题数：'+gData.total+"&nbsp;正确数："+gData.correct+"&nbsp;正确率："+getCorrectRate()+"%";
    setHighlight();
    setCheckboxStatus();



    // 得到正确率
    function getCorrectRate() {
        return ((gData.correct/gData.total)*100).toFixed(2);
    }

    // 设置选中状态
    function setCheckboxStatus() {
        const inputTags =document.getElementsByTagName("input");
        for (var i = 0; i < inputTags.length; i++) {
            if (inputTags[i].nodeType) {
                var inputId = inputTags[i].getAttribute("id");
                inputId=inputId.replace("input","");
                if (gData.clickedValues.indexOf(inputId) > -1) {
                    inputTags[i].checked = true;
                }
            }
        }
    }

    // 设置正确答案语错误答案 高亮
    function setHighlight(){
        var liTags =document.getElementsByTagName("li");
        for(var i in liTags){
            if(liTags[i].nodeType == 1){
                var liKey = liTags[i].getAttribute("id");
                // 正确答案高亮显示
                if(liTags[i].getAttribute("class") == "optionTrue"){
                    if(gData.clickedValues.indexOf(liKey) == -1){
                        liTags[i].classList.add("cloze_line");
                    }else{
                        liTags[i].classList.add("cloze");
                    }
                }else{
                    // 选错的加删除线
                    if(gData.clickedValues.indexOf(liKey) != -1){
                        liTags[i].classList.add("wrong");
                    }
                }
            }
        }
    }
</script>
```
把3个模板代码都放进去之后，选择题的模板就制作完成了。

### 五、怎么修改成自己喜欢的模板？
要修改大体分为两种：
- 1、会点前端代码的开发者大佬
这个不用说，注释写得明明白白，随便改，觉得我写得Low，还可以自己手撸一个出来，都不算难。这个就不具体说了
- 2、不会写代码的大佬
感觉大多数都是这类型的人，像考研什么的特别多。如果一点编程经验都没有的话，要改还是稍微有点点难度。
但是可以改皮肤，也就是更改背景和字体大小颜色成自己的颜色，什么护眼色呀，炫酷黑呀等等。
Anki 默认有一个卡片的`CSS样式` 我们只需要改那个属性即可,位置在中间的代码第一个`.card`。
```css
.card{
    font-family:Arial;
    font-size:22px;
    text-align:left;
    color:#fff;
    background-color:#222;
}
```
先解释一下上面代码的意思
- font-family
这个是整个卡片是什么字体，这个不需要改，可选值："times"、"courier"、"arial"
- font-size
这个是显示的字体大小，单位是像素(`px`)，如果你觉得字体显示大了你就把它调小，怎么调小就是把当前的`font-size:22px;` 改成 `font-size:20px;`。
如果感觉还大就改成`font-size:19px;`，由此我们知道。只需要把`22px`中的数字变大或变小就可以调节字体。
- text-align
卡片文本的水平对齐方式，我不建议改，可选值：`left`、`right`、`center` 、`justify`、`inherit`。
默认是左边对齐，看单词知道后面是右边对齐，居中对齐，两端对齐，继承父类对齐
- color
看单词就知道是字体颜色，这个值可以填的方式很多，最简单的可以写颜色名称如红色：`color:red;`、蓝色：`color:blue;`等其他颜色
还有一种是填十六进制的颜色，如`color:#fff;` 这个是白色，对应为`color:rgb(255,255,255)`，如果你对十六进制不熟，也可以使用RGB格式的颜色
如：白色：`color:rgb(255,255,255)`、黑色：`color:rgb(0,0,0)`,可以去搜索引擎搜索你想要的颜色进行替换即可。
- background-color
看单词大概知道是背景颜色，这个的值和上面的`color` 值一样，可以使用单词颜色如：`red`、`blud`、`green` 、`yellow`等，
十六进制或RGB都可以。

#### 倒计时的功能
再说一下这个吧，有些人不需要，有些人需要
- 1、去掉倒计时功能
这个简单在正面模板找到如下代码片段进行修改
```js
    initOptions();
    var endTime="2020/08/29 00:00:00";
    countDown(endTime);
	
	// 只需要改一行代码，就是在“ countDown(endTime);” 这行代码前面加两个斜杆，如下这样的
	initOptions();
    var endTime="2020/08/29 00:00:00";
    //countDown(endTime);
```
- 2、修改倒计时的结束时间
还是上面的代码
```js
	initOptions();
    var endTime="2020/08/29 00:00:00";
    countDown(endTime);
	
	// 如果你想把时间改成2022年的12月1号，12点12分12秒，那代码就改成如下这个样子
	initOptions();
    var endTime="2022/12/01 12:12:12";
    countDown(endTime);
```


### 最终
- 因文化水平有限，写了那么多不知道效果怎样，各位看官有没有看明白。
- 我知道很多人懒得复制代码，或者没看明白，没关系我都想到了。导出一个`apkg`文件模板给你们
- Github下载地址：[https://github.com/rstyro/anki-model/tree/master/choose](https://github.com/rstyro/anki-model/tree/master/choose)
- 源码或者模板都在上面，感觉好用，给个好评，在Github上点个Star(⭐)
---
title: Js 点击复制文本内容
date: 2018-01-13 15:13:38
tags: [JavaScript]
categories: Java
---
# Js 点击复制文本内容
## 一、利用第三方插件 clipboard.js
```html
<!DOCTYPE html>
<html>
<head lang="en">
<meta charset="UTF-8">
<title></title>
</head>
<body>
<textarea id="target">复制我里面的内容</textarea></br>
<button class="btn" id="myb"  data-clipboard-action="copy" data-clipboard-target="#target">
点我复制
</button>
<script src="clipboard.min.js"></script>
<script>

var clipboard=new Clipboard('#myb');
clipboard.on('success',function(e) {
	console.log("success","内容已经复制到剪切板啦");
	console.info('Action:', e.action);
	console.info('Text:', e.text);
	console.info('Trigger:', e.trigger);
	//e.clearSelection();
});
clipboard.off('success',function(e) {
	console.log("success","内容已经复制到剪切板啦");
	console.info('Action:', e.action);
	console.info('Text:', e.text);
	console.info('Trigger:', e.trigger);
	//e.clearSelection();
});

</script>
</body>
</html>
```
详细用法：https://github.com/zenorocha/clipboard.js

## 二、execCommand
```html
<!DOCTYPE html>
<html>
<head lang="en">
<meta charset="UTF-8">
<title></title>
</head>
<body>
<p>点击复制后在右边textarea CTRL+V看一下</p>
<input type="text" id="inputText" value="这里是复制的文本内容！！！！"/>
<input type="button" id="btn" value="复制"/>
<textarea rows="4"></textarea>
<script type="text/javascript">

 window.onload = function () {
	var btn = document.getElementById('btn');
	btn.addEventListener('click', function(){
		var inputText = document.getElementById('inputText');
		inputText.focus();
		inputText.setSelectionRange(0, inputText.value.length);
		 document.execCommand('copy', true);
	});
	
};

</script>
</body>
</html>
```
### 感觉介绍两种差不多了，第一种比较方便。一般第一种就够用了
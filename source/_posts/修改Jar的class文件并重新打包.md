---
title: 修改Jar的class文件并重新打包
date: 2021-03-16 10:23:46
tags: [Java]
categories: Java
---

## 一、环境
+ 拿到第三方jar文件
+ 配置java环境
+ 需要用到 IDEA
+ 能修改的前提是第三方jar没有经过加密混淆

## 二、修改步骤
+ 1、新建项目
	+ 使用IDEA 新建一个`Java Project`.
+ 2、引入第三方jar
	+ 在IDEA-> File -> Project Structure -> Modules -> Dependencies -> 选择添加第三方jar包
+ 3、新建需要修改的类
	+ 在新项目的src下新建包名类名和你需要修改第三方文件的包名类名一致
	+ 然后通过IDEA可以看到第三方class文件的内容，复制到上面步骤新建的类，进行修改
+ 4、依赖报错处理
	+ 新建的类里面可能又依赖其他的类，在项目中报找不到类的错误.
	+ 则重复第3步的操作。在新项目中新建报错的`import`类。
	+ 如果还是报错就继续第3步。直到不报错为止。
+ 5、重新编译
	+ 修改源码完之后需要重新编译，步骤如下
	+ 在项目中打开类 IDEA工具栏 -> Build -> Recompile 或者 `Ctrl+shift+F9` 快捷键
	+ 然后会在项目根目录中出现一个out文件夹，里面就是编译后的新的class文件
+ 6、重新打包
	+ 使用解压工具，解压第三方jar包
	+ 把out文件夹里新生成的class替换到解压第三方jar文件的相同路径下
	+ windows 打开 cmd ，进入到解压第三方jar的根路径执行：`jar cvf 你的第三方jar名称.jar *`
	+ 然后就会在解压的根路径下生成 新的jar 结束....


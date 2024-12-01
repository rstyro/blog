---
title: Vue入门级语法详解
date: 2019-04-25 15:56:46
updated: 2019-04-25 15:56:46
tags: [Vue]
categories: 前端
---

# Vue入门级语法

## 使用方式
新手学习，只需要以引入`<script>`的方式即可。  
在`.html` 中的`head`中加上`<script src="https://cdn.jsdelivr.net/npm/vue/dist/vue.js"></script>`即可  
学编程怎么能少了`hello world`

<!--more-->

```html
<html>
    <head>
        <meta charset="UTF-8">
		<title>Hello World</title>
        <script src="https://cdn.jsdelivr.net/npm/vue/dist/vue.js"></script>
    </head>
    <body>  
        <div id="app">
            { { message } }
        </div>      
        <script>
          var app = new Vue({
            el: '#app',
            data: {
              message: 'Hello Vue!'
            }
          })
		    </script>
    </body>
</html>
```
如果是本地测试，最好把vue.js下载到本地，下载地址：[https://vuejs.org/js/vue.js](https://vuejs.org/js/vue.js)

## 声明式渲染
+ Vue 是一种`MVVM 模式`，当vue 和一个`挂载点`绑定之后就可以操作这个`挂载点`之下的`DOM`元素  
+ 挂载点，通俗的讲就是一个DOM元素，比如上面的代码,vue的`el`是`#app` 对应的`<div id="app"> { { message } } </div>` 这个`div`就相当于一个挂载点  
+ data中可以自定义任意变量，`{ { } }`这就是vue的显示语法，
+  `{ {message } }` 这个的意思是，显示为vue中的 `message`字段对应的数据为：`hello vue`  
+ 其实除了`<div id="app">{ { message } }</div>`这个之外，还可以用`<div id="app" v-html="message"></div>` 或者 `<div id="app" v-text="message"></div>`  
+ 也就是说除了`{ {} }`语法 还可以用`v-text="变量"` 或者 `v-html="变量"` 这种语法的。

## 条件判断
语法：`v-if`,如果`v-if=true`就显示，否则不显示  
```html
<body>
    <div id="app">
        <ul>
            <li>苹果</li>
            <li>橘子</li>
            <li v-if="isFruitByBanana">香蕉</li>
            <li v-if="isFruitByTomato">西红柿</li>
            <li v-show="isFruitByBanana">西红柿</li>
        </ul>
    </div>

<script>
    var app = new Vue({
        el:"#app",
        data:{
            isFruitByBanana: true,
            isFruitByTomato: false
        }
    });
</script>
</body>
```
如上，西红柿就不会显示，和`v-if`有点像的有`v-show` 用法和`v-if`一样，区别在于  
+ `v-if` 会把dom元素删除掉  
+ `v-show` 不会把dom元素删除，而是通过style标签隐藏掉


## 数据绑定
```html
<body>
    <div id="app2" v-bind:title="message" >你还要我怎样 要怎样，你突然来的短信就够我悲伤</div>
<script>
    var app = new Vue({
        el:"#app2",
        data:{
            message:"薛之谦的歌词，v-bind 绑定的是DOM 元素的属性。"
        }
    })
</script>
</body>
```
`v-bind`绑定的是DOM元素的属性，当鼠标移到 那行字的时候，`title`被触发显示我们自定义的数据  
当然`v-bind`不只是可以绑定`title`属性，
+ `v-bind:value`
+ `v-bind:class`
+ `v-bind:style` 
+ 等等。。。  

缩写语法：`:title` ,也就是去掉`v-bind`,直接`:`加html属性,例如上面的可以写成  
`<div id="app2"  :title="message" >你还要我怎样 要怎样，你突然来的短信就够我悲伤</div>`

## 列表循环
```html
<body>
    <div id="app">
        <ul >
            <li v-for="item in items">{ { item } }</li>
        </ul>

        <ul >
            <li v-for="(item,index) of obj">{ {item.age } }</li>
        </ul>
    </div>

<script>
    var app = new Vue({
        el:"#app",
        data:{
            items:["襁褓","孩提","龆年","舞勺之年","舞象之年","而立之年","不惑之年","知命之年","杖乡之年","致事之年","耄耋之年","鲐背之年","不老之年"],
            obj:[{age:"不到周岁", alias:"襁褓"},
                {age:"2-3岁", alias:"孩提"},
                {age:"8岁", alias:"龆年"},
                {age:"13~15岁", alias:"舞勺之年"},
                {age:"15~20岁", alias:"舞象之年"},
                {age:"30岁", alias:"而立之年"},
                {age:"40岁", alias:"不惑之年"},
                {age:"50岁", alias:"知命之年"},
                {age:"60岁", alias:"杖乡之年"},
                {age:"70岁", alias:"致事之年"},
                {age:"80岁", alias:"耄耋之年"},
                {age:"90岁", alias:"鲐背之年"},
                {age:"想死都死不了", alias:"不老之年"},
            ]
        }
    });
    app.obj.push({age:"这是新添加的",alias:"new add"});
</script>
</body>
```
+ 用 `v-for` 指令根据一组数组的选项列表进行渲染。`v-for `指令需要使用` item in items` 形式的特殊语法，`items` 是源数据数组并且` item `是数组元素迭代的别名。  
+ 后面第二种的写法也可`<li v-for="(item,index) of obj">{ { item.age } }</li>` 就是加了一个index 索引字段



## 组件基础
自定义一个组件示例：
```
 Vue.component("fruit-item",{
	props:["item"],
	template: "<li>{ { item.cn_name } }-->{ { item.en_name } }</li>"
});
```
+ 组件是可复用的 Vue 实例，且带有一个名字：在这个例子中是 `<fruit-item>`。我们可以在一个通过 new Vue 创建的 Vue 根实例中，把这个组件作为自定义元素来使用
+ Prop 是你可以在组件上注册的一些自定义特性。当一个值传递给一个 prop 特性的时候，它就变成了那个组件实例的一个属性。如上就是`item` 属性就是，我们就可以通过`item` 自定义我们的数据  
+ prop是一个数组类型，我们可以从外面传多个数据进来  
```html
<!DOCTYPE html>
<html lang="en" >
<head>
    <meta charset="UTF-8">
    <title>Hello World</title>
    <script src="../dist/vue.min.js"></script>
    <style>
        #app{
            width: 500px;
            height: 500px;
            margin: 100px auto;
        }
    </style>
</head>
<body>
    <div id="app">
        <ol>
            <fruit-item v-for="fruit in fruits" v-bind:item="fruit"></fruit-item>
        </ol>
    </div>
<script>
    Vue.component("fruit-item",{
        props:["item"],
        template: "<li @click='alertName(item.cn_name)'>{ {item.cn_name} }-->{ {item.en_name} }</li>",
        methods: {
            alertName: function (name) {
                alert(name);
            }
        }
    });
    var app = new Vue({
        el:"#app",
        data:{
            fruits:[{cn_name:"苹果",en_name:"apple"},
                {cn_name:"梨",en_name:"pear"},
                {cn_name:"杏",en_name:"apricot"},
                {cn_name:"桃",en_name:"peach"},
                {cn_name:"葡萄",en_name:"grape"}
            ]
        }
    })
    app.fruits.push({cn_name:"西红柿",en_name:"Tomato"});
</script>
</body>
</html>
```
每一个组件就是一个`Vue`实例，所以在组件中我们也可以在`methods`定义方法时间，也可以定义`data`中定义变量。  
那我们是不是可以说，每个`Vue`示例就是一个组件呢？是

## 表单绑定
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>model 绑定</title>
    <script src="../dist/vue.min.js"></script>
    <style>
        #app{
            width: 500px;
            height: 500px;
            margin: 100px auto;
        }

    </style>
</head>
<body >
<div id="app">
    <p>text：{ {text} }</p>
    <textarea v-model="text" cols="50" rows="10" placeholder="随便输一点"></textarea>

    <br>
    <input type="radio" name="sex" v-model="sex" value="男">男<br>
    <input type="radio" name="sex" v-model="sex" value="女">女<br>
    <label>性别：{ {sex} }</label>
    <br>

    <br><br><br>
    <select v-model="selected">
        <option v-for="item in list" v-bind:value="item">{ {item} }</option>
    </select>
    <span>selected：{ {selected} }</span>
    <br>

    <br><br><br><br><br>
    复选框：<input type="checkbox" id="checkbox" v-model="checked">
    <label>{ { checked } }</label>

    <br><br><br><br><br>
    美女：<input type="checkbox" value="美女" v-model="checkeds"><br>
    财富：<input type="checkbox" value="财富" v-model="checkeds"><br>
    长生：<input type="checkbox" value="长生" v-model="checkeds"><br>
    权利：<input type="checkbox" value="权利" v-model="checkeds"><br>

    <br>
    <label>您选择了：{ { checkeds } }</label>
</div>
<script>
    var vm = new Vue({
        el:"#app",
        data:{
            text: "",
            sex: "",
            selected: "",
            list:["a","b","c","d","e","f","g"],
            checked: false,
            checkeds:[]
        }
    });

</script>
</body>
</html>
```

+ 你可以用 `v-model` 指令在表单`<input>`、`<textarea>` 及 `<select>` 元素上创建双向数据绑定。它会根据控件类型自动选取正确的方法来更新元素。尽管有些神奇，但 `v-model` 本质上不过是语法糖。它负责监听用户的输入事件以更新数据，并对一些极端场景进行一些特殊处理。
> `v-model` 会忽略所有表单元素的 `value`、`checked`、`selected` 特性的初始值而总是将 `Vue` 实例的数据作为数据来源。你应该通过 `JavaScript` 在组件的 `data` 选项中声明初始值。





## 事件处理
```html
<body>
<div id="app">
    <div >当你点击按钮的时候，触发按钮事件按钮文字会反转</div>
    <br>
    <button v-on:click="reverseMessage" >{ {message} }</button>
</div>
<script>
    var app = new Vue({
        el:"#app",
        data:{
            message: "你是年少的欢喜"
        },
        methods:{
            reverseMessage:function () {
                this.message=this.message.split('').reverse().join('');
            }
        }
    })
</script>
</body>
```
可以用 v-on 指令监听 DOM 事件，并在触发时运行一些 JavaScript 代码。上述代码按钮绑定的事件方法名为：`reverseMessage`  
+ 语法：`v-on:click="方法名"`
+ 缩写语法：`@click` ,代码如下  
```html
<div id="app">
    <button @click="eventClick">可以获得DOM原生的事件</button>
    <button @click="say('hi')">Say hi</button>
    <button @click="say2('what',$event)">Say what</button>
</div>
<script>
    var vm = new Vue({
        el:"#app",
        data:{
            name: "vue.js",
            count:0
        },
        methods:{
            eventClick:function(event){
                // `this` 在方法里指当前 Vue 实例
                alert('Hello ' + this.name + '!')
                // `event` 是原生 DOM 事件
                alert(event.target.tagName);
            },
            say: function (message) {
                alert(message)
            },
            say2: function (message,event) {
                alert(event.target.innerText);
                console.log("event",event);
            }
        }
    });

</script>
</body>
```

## 样式渲染
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>V-STYLE-CLASS</title>
    <script src="../dist/vue.min.js"></script>
    <style>
        #app{
            width: 500px;
            height: 500px;
            margin: 100px auto;
            text-align: center;
        }
        .active{
            color: green;
            background: aliceblue;
        }
        .error{
            color: red;
        }
    </style>
</head>
<body>
    <div id="app">
        <ol>
            <li>苹果</li>
            <li v-bind:class="classObject" >橘子</li>
            <li>香蕉</li>
            <li class="error" v-bind:class="classObject">西红柿</li>
        </ol>
    </div>

<script>
    var vm = new Vue({
        el:"#app",
        data:{
            classObject: {
                active: true,
                error: false
            }
        }
    });

</script>
</body>
</html>
```
+ 我们可以传给 `v-bind:class` 一个对象，以动态地切换 class：    
`<li v-bind:class="classObject" >橘子</li>` 在`classObject`有两个属性，哪个为真就取其样式  
+ `v-bind:class` 指令也可以与普通的 class 属性共存。当有如下模板:  
`<li class="error" v-bind:class="classObject">西红柿</li>`   
结果渲染为`<li class="error active">西红柿</li>`
+ 还有组件样式：  如下示例
```html
<!DOCTYPE html>
<html lang="en" >
<head>
    <meta charset="UTF-8">
    <title>Vue.component</title>
    <script src="../dist/vue.min.js"></script>
    <style>
        #app{
            width: 500px;
            height: 500px;
            margin: 100px auto;
        }
        .default{
            background: aliceblue;
        }
        .active{
            color: green;
        }
        .error{
            color: red;
        }
    </style>
</head>
<body>
    <div id="app">
        <ol>
            <li class="default">苹果</li>
            <li class="default"  v-bind:style="mystyle">橘子</li>
            <li class="default">香蕉</li>
            <fruit-item class="default" ></fruit-item>
        </ol>
    </div>
<script>
    Vue.component("fruit-item",{
        template: "<li class='active'>葡萄</li>"
    });

    var app = new Vue({
        el:"#app",
        data:{
            mystyle:{
                color:"#FF8809",
                background: 'aliceblue'
            }
        }
    })
</script>
</body>
</html>
```
组件中可以包含`class`

## 计算与监听
```html
<!DOCTYPE html>
<html lang="en" >
<head>
    <meta charset="UTF-8">
    <title>计算与监听器</title>
    <script src="../dist/vue.min.js"></script>
    <style>
        #app{
            width: 500px;
            height: 500px;
            margin: 100px auto;
            text-align: center;
        }
    </style>
</head>
<body>
<div id="app">
    <p>姓：<input v-model="firstName" /></p>
    <p>名：<input v-model="lastName" /></p>
    <p>全名:{ {firstName} } { {lastName} }</p>
    <p>全名:{ {fullName} }</p>
    <p>修改名字的次数：{ {count} }</p>
</div>
<script>
    var app = new Vue({
        el:"#app",
        data:{
            firstName:"",
            lastName: "",
            count:0
        },
        computed: {
            fullName: function () {
                return this.firstName + this.lastName;
            }
        },
        watch: {
            fullName: function () {
               this.count++;
            }
        }
    })
</script>
</body>
</html>
```
+ 模板内的表达式非常便利，但是设计它们的初衷是用于简单运算的,在模板中放入太多的逻辑会让模板过重且难以维护,所以有了计算属性  
+ 如上的`全名`需要通过 `姓`和`名 计算而来，计算属性就放在`computed` 中。 `watch` 是一个监听器，比如当 `fullName` 发生改变的时候，`count++`


## 组件之间的数据传递
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>组件间的数据交互</title>
    <script src="../dist/vue.min.js"></script>
    <style>
        #app{
            width: 500px;
            height: 500px;
            margin: 100px auto;
        }

    </style>
</head>
<body >
<div id="app">
    <input type="text" v-model="text"> <button @click="addItem">添加数据</button>
    <br>
    <ul>
        <fruit-item v-for="(fruit,index) of fruits" :item="fruit" :index="index"  @delete="deleteItem"></fruit-item>
    </ul>
</div>
<script>
    Vue.component("fruit-item",{
        props:["item","index"],
        template: "<li @click='liClick'>{ {item.cn_name} }-->{ {item.en_name} }</li>",
        methods: {
            liClick: function () {
                this.$emit("delete",this.index)
            }
        }
    });
    var vm = new Vue({
        el:'#app',
        data:{
            fruits:[{cn_name:"苹果",en_name:"apple"},
                {cn_name:"梨",en_name:"pear"},
                {cn_name:"杏",en_name:"apricot"},
                {cn_name:"桃",en_name:"peach"},
                {cn_name:"葡萄",en_name:"grape"}
            ],
            text:""
        },
        methods:{
            deleteItem: function (index) {
                this.fruits.splice(index,1);
            },
            addItem: function () {
                this.fruits.push({cn_name:this.text,en_name:"英文是啥"});
                this.text='';
            }
        }
    });

</script>
</body>
</html>
```
+ 如上demo，我们可以自己加数据，当点击`<li>`的时候,就需要改变组件外的Vue示例的`list` 在`liClick` 方法中我们把参数传递了出去




## HTTP 请求
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>请求</title>
    <script src="../dist/vue.min.js"></script>
    <style>
        #app{
            width: 500px;
            height: 500px;
            margin: 100px auto;
        }

    </style>
</head>
<body >
<div id="app">
    <button @click="getApiData">点击得到数据</button>
    <div v-for="item in result">
        <h3>{ {item.title} }</h3><i style="color: #ccc;">{ {item.authors} }</i>
        <p>{ {item.content} }</p>
        <br>
        <br>
        <br>
    </div>
</div>
<script src="https://cdn.staticfile.org/vue-resource/1.5.1/vue-resource.min.js"></script>
<script>
    window.onload = function(){
        var vm = new Vue({
            el:'#app',
            data:{
                msg:'Hello World!',
                result:[]
            },
            methods:{
                getApiData:function(){
                    //发送get请求
                    this.$http.get('https://api.apiopen.top/getTangPoetry?page=1&count=20').then(function(res){
                        console.log("res:",res.body);
                        var json = JSON.stringify(res.body);
                        console.log("json:",json);
                        this.result = res.body.result;
                    },function(){
                        console.log('请求失败处理');
                    });
                }
            }
        });
    }

</script>
</body>
</html>
```

#### 自此基础语法大成！！！
本篇完整代码地址：
+ Github [https://github.com/rstyro/vue-learning](https://github.com/rstyro/vue-learning)
+ Gitee [https://gitee.com/rstyro/vue-learning](https://gitee.com/rstyro/vue-learning)

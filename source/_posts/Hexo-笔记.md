---
title: Hexo-笔记
date: 2019-01-10 18:37:24
tags: "Hexo"
categories: 笔记
---

## 一、前置条件

#### 1、安装Git
> 下载地址：https://git-scm.com/
#### 2、安装Node.js
> 下载地址：http://nodejs.cn/download/


## 二、安装Hexo
```bash
# 安装 hexo
npm install -g hexo


# 查看是否安装成功，查看版本号
hexo -v

# 初始化Hexo，在当前目录下，创建一个文件夹为blog 的博客
hexo init blog

#生成静态文件
hexo generate


# 启动,默认访问：http://localhost:4000/
hexo s

# 清除缓存，和已生成的静态文件
hexo clean
```


## 三、修改主题
以下都是以next主题为例子
```bash
# 可以在https://hexo.io/themes/可以查看你喜欢的主题,然后 clone 到themes文件夹下即可,比如next 主题
git clone https://github.com/theme-next/hexo-theme-next themes/next
```


## 四、配置

### 一、基本配置

编辑文件路径站点根目录 `/`下 `_config.yml`

|字段|说明|
|--:|-|
|title|博客的名称。|
|subtitle|根据主题的不同，有的会显示有的不会显示。|
|description|主要用于SEO，告诉搜索引擎一个关于站点的简单描述，通常建议在其中包含网站的关键词。|
|author|作者名称，用于主题显示文章的作者。|
|language|语言会对应的解析正在应用的主题中的languages文件夹下的不同语言文件。所以这里的名称要和languages文件夹下的语言文件名称一致。|
|timezone|Asia/Shanghai //可不填写。|

> 网站存放在子目录
> 如果您的网站存放在子目录中，例如 `http://yoursite.com/blog`，则请将您的 :
> + url 设为 `http://yoursite.com/blog` 并把
> + root 设为 `/blog/`。

### 二、主题基本配置
修改主题配置文件，在菜单项添加以下内容(把注释打开即可)
```yml
menu:
  home: / || home
  about: /about/ || user
  tags: /tags/ || tags
  categories: /categories/ || th
  archives: /archives/ || archive
  #schedule: /schedule/ || calendar
  #sitemap: /sitemap.xml || sitemap
  #commonweal: /404/ || heartbeat

# Enable/Disable menu icons / item badges.
menu_settings:
  icons: false	#是否显示Icon
  badges: false
```

### 三、新建

#### 1、新建页面
```sh
# 生成标签页面
hexo new page tags
# 生成关于页面
hexo new page about
# 生成分类页面
hexo new page categories
```
#### 2、新建文章
+ 新建文章命令：`hexo n 文章名`，成功之后在`~/source/_posts/` 下就会看到`.md`的文章
+ 打开文章会看到在头部有这样的信息
```
---
title: 文章名
date: 2019-01-10 18:37:24
tags: "Hexo"
---
```
+ 这个意思下面有解析，而且也可以按需加其他字段
+ 文章头部解析：
```
/* ！！！！！！！！！！
** 每一项的 : 后面均有一个空格
** 且 : 为英文符号
** ！！！！！！！！！！
*/

title:
/* 文章标题，可以为中文 */

date:
/* 建立日期，如果自己手动添加，请按固定格式
** 就算不写，页面每篇文章顶部的发表于……也能显示
** 只要在主题配置文件中，配置了 created_at 就行
** 那为什么还要自己加上？
** 自定义文章发布的时间
*/

updated:
/* 更新日期，其它与上面的建立日期类似
** 不过在页面每篇文章顶部，是更新于……
** 在主题配置文件中，是 updated_at
*/

permalink:
/* 若站点配置文件下的 permalink 配置了 title
** 则可以替换文章 URL 里面的 title（文章标题）
*/

categories:
/* 分类，支持多级，比如：
- technology
- computer
- computer-aided-art
则为 technology/computer/computer-aided-art
（不适用于 layout: page）
*/

tags:
/* 标签
** 多个可以这样写 [标签1,标签2,标签3]
** （不适用于 layout: page）
*/

description:
/* 文章的描述，在每篇文章标题下方显示
** 并且作为网页的 description 元数据
** 如果不写，则自动取 <!-- more -->
** 之前的文字作为网页的 description 元数据
*/

keywords:
/* 关键字，并且作为网页的 keywords 元数据
** 如果不写，则自动取 tags 里的项
** 作为网页的 keywords 元数据
*/

comments:
/* 是否开启评论
** 默认值是 true
** 要关闭写 false
*/

layout:
/* 页面布局，默认值是 post，默认值可以在
** 站点配置文件中修改 default_layout
** 另：404 页面可能用到，将其值改为 false
*/

type:
/* categories，目录页面
** tags，标签页面
** picture，用来生成 group-pictures
*/

```

### 四、设置头像
```yml
# Sidebar Avatar
avatar:
  # in theme directory(source/images): /images/avatar.gif
  # in site  directory(source/uploads): /uploads/avatar.gif
  # You can also use other linking images.
  url: #你的头像地址
  # If true, the avatar would be dispalyed in circle.
  rounded: false
  # The value of opacity should be choose from 0 to 1 to set the opacity of the avatar.
  opacity: 1
  # If true, the avatar would be rotated with the cursor.
  rotated: false
```
### 五、修改底部
去掉 `由 Hexo 强力驱动 v3.8.0 | 主题 – NexT.Muse v6.7.0`
打开主题的`_config.yml` 配置文件，找到如下信息，把`enable:true` 改为 `enable:false`
把powered 与
```yml
  # If not defined, `author` from Hexo main config will be used.
  copyright:
  # -------------------------------------------------------------
  powered:
    # Hexo link (Powered by Hexo).
    enable: false
    # Version info of Hexo after Hexo link (vX.X.X).
    version: true

  theme:
    # Theme & scheme info link (Theme - NexT.scheme).
    enable: false
    # Version info of NexT after scheme info (vX.X.X).
    version: true
  # -------------------------------------------------------------
  # Beian icp information for Chinese users. In China, every legal website should have a beian icp in website footer.
  # http://www.miitbeian.gov.cn
  beian:
    enable: false
    icp:
```

### 六、添加顶部加载
在`\themes\next\layout\_custom head.swig`文件中添加如下代码
```html
<script src="//cdn.bootcss.com/pace/1.0.2/pace.min.js"></script>
<link href="//cdn.bootcss.com/pace/1.0.2/themes/pink/pace-theme-flash.css" rel="stylesheet">
<style>
  .pace .pace-progress {
	  background: #1E92FB; /*进度条颜色*/
	  height: 3px;
  }
  .pace .pace-progress-inner {
	   box-shadow: 0 0 10px #1E92FB, 0 0 5px     #1E92FB; /*阴影颜色*/
  }
  .pace .pace-activity {
	  border-top-color: #1E92FB;    /*上边框颜色*/
	  border-left-color: #1E92FB;    /*左边框颜色*/
  }
</style>
```

### 七、文章添加阴影
在 `themes\next\source\css\_custom\custom.styl` 添加如下代码
```css
// 主页文章添加阴影效果
 .post {
   margin-top: 60px;
   margin-bottom: 60px;
   padding: 25px;
   -webkit-box-shadow: 0 0 5px rgba(202, 203, 203, .5);
   -moz-box-shadow: 0 0 5px rgba(202, 203, 204, .5);
  }
```

### 八、在文章末尾添加“文章结束”标记
##### 1、在路径 `\themes\next\layout\_macro` 文件夹中新建 `passage-end-tag.swig` 文件
添加内容如下
```html
<div>
    {% if not is_index %}
        <div style="text-align:center;color: #ccc;font-size:14px;">-------------本文结束<i class="fa fa-paw"></i>感谢您的阅读-------------</div>
    {% endif %}
</div>
```

##### 2、打开\themes\next\layout\_macro\post.swig文件，在post-body后，post-footer前，添加下面内容：
添加内容如下
```html
<div>
  {% if not is_index %}
    {% include 'passage-end-tag.swig' %}
  {% endif %}
</div>
```

放的位置如下：
```

    {#####################}
    {### END POST BODY ###}
    {#####################}
	
	    <div>
	{% if not is_index %}
	{% include 'passage-end-tag.swig' %}
	{% endif %}
	</div>
```
##### 3、打开主题配置文件（_config.yml),在末尾添加：
```
# 文章末尾添加“本文结束”标记
passage_end_tag:
    enabled: true
```
> 如果出现乱码，记得把 `passage-end-tag.swig` 文件 用类似 `Notepad++` 的工具转成UTF-8 



### 九、底部标签样式
修改`\themes\next\layout\_macro\post.swig` 中文件，command+f搜索`rel="tag">#`，将#替换成<i class="fa fa-tag"></i>,修改后，片段代码如下：
```
<footer class="post-footer">
      {% if post.tags and post.tags.length and not is_index %}
        <div class="post-tags">
          {% for tag in post.tags %}
            <a href="{{ url_for(tag.path) }}" rel="tag"><i class="fa fa-tag"></i> {{ tag.name }}</a>
          {% endfor %}
        </div>
      {% endif %}
```


### 十、文章底部加版权

##### 1、手动修改主题目录下的 `\themes\next\layout\_macro\post.swig` 文件，找到 post-footer 所在的标签，添加以下内容：
```
<div>    
 {# 此处判断是否在索引列表中 #}
 {% if not is_index %}
<ul class="post-copyright">
  <li class="post-copyright-author">
      <strong>本文作者：</strong>{{ theme.author }}
  </li>
  <li class="post-copyright-link">
    <strong>本文链接：</strong>
    <a href="{{ url_for(page.path) }}" title="{{ page.title }}">{{ page.path }}</a>
  </li>
  <li class="post-copyright-license">
    <strong>版权： </strong>
    转载注明出处！
  </li>
</ul>
{% endif %}
</div>
```

##### 2、添加样式
在 `\themes\next\source\css\_custom\custom.styl` 文件,添加如下内容：
```
.post-copyright {
    margin: 1em 0 0;
    padding: 0.5em 1em;
    border-left: 3px solid #ff1700;
    background-color: #f9f9f9;
    list-style: none;
}
```

### 十一、添加评论
#### 注册Leancloud
> 官网：https://leancloud.cn/

修改主题配置文件`_config.xml` 查找Valine ,如下：
```yml
# You can get your appid and appkey from https://leancloud.cn
# More info available at https://valine.js.org
valine:
  enable: true # When enable is set to be true, leancloud_visitors is recommended to be closed for the re-initialization problem within different leancloud adk version.
  appid: 你的appid # your leancloud application appid
  appkey: 你的appkey # your leancloud application appkey
  notify: false # mail notifier, See: https://github.com/xCss/Valine/wiki
  verify: false # Verification code
  placeholder: 来都来了，不说几句就走，过分了啊！！！ # comment box placeholder
  avatar: mm # gravatar style
  guest_info: nick,mail,link # custom comment header
  pageSize: 10 # pagination size

```

### 十二、压缩
```bash
# 安装依赖
npm i gulp gulp-debug gulp-clean-css gulp-uglify gulp-htmlmin gulp-htmlclean gulp-imagemin gulp-changed gulp-if gulp-plumber run-sequence del -s
```
在根目录下创建`gulpfile.js`文件。编辑内容如下：

```js
var gulp        = require('gulp');
var debug       = require('gulp-debug');
var cleancss    = require('gulp-clean-css'); //css压缩组件
var uglify      = require('gulp-uglify');    //js压缩组件
var htmlmin     = require('gulp-htmlmin');   //html压缩组件
var htmlclean   = require('gulp-htmlclean'); //html清理组件
var imagemin    = require('gulp-imagemin');  //图片压缩组件
var changed     = require('gulp-changed');   //文件更改校验组件
var gulpif      = require('gulp-if')         //任务 帮助调用组件
var plumber     = require('gulp-plumber');   //容错组件（发生错误不跳出任务，并报出错误内容）
var runSequence = require('run-sequence');   //异步执行组件
var isScriptAll = true;  //是否处理所有文件，(true|处理所有文件)(false|只处理有更改的文件)
var isDebug     = true;  //是否调试显示 编译通过的文件
var del         = require('del');
var Hexo        = require('hexo');
var hexo        = new Hexo(process.cwd(), {}); // 初始化一个hexo对象

// 清除public文件夹
gulp.task('clean', function() {
    return del(['public/**/*']);
});

// 下面几个跟hexo有关的操作，主要通过hexo.call()去执行，注意return

// 创建静态页面 （等同 hexo generate）
gulp.task('generate', function() {
    return hexo.init().then(function() {
        return hexo.call('generate', {
            watch: false
        }).then(function() {
            return hexo.exit();
        }).catch(function(err) {
            return hexo.exit(err);
        });
    });
});

// 启动Hexo服务器
gulp.task('server',  function() {
    return hexo.init().then(function() {
        return hexo.call('server', {});
    }).catch(function(err) {
        console.log(err);
    });
});

// 部署到服务器
gulp.task('deploy', function() {
    return hexo.init().then(function() {
        return hexo.call('deploy', {
            watch: false
        }).then(function() {
            return hexo.exit();
        }).catch(function(err) {
            return hexo.exit(err);
        });
    });
});

// 压缩public目录下的js文件
gulp.task('compressJs', function () {
    var option = {
        // preserveComments: 'all',//保留所有注释
        mangle: true,           //类型：Boolean 默认：true 是否修改变量名
        compress: true          //类型：Boolean 默认：true 是否完全压缩
    }
    return gulp.src(['./public/**/*.js','!./public/**/*.min.js'])  //排除的js
        .pipe(gulpif(!isScriptAll, changed('./public')))
        .pipe(gulpif(isDebug,debug({title: 'Compress JS:'})))
        .pipe(plumber())
        .pipe(uglify(option))                //调用压缩组件方法uglify(),对合并的文件进行压缩
        .pipe(gulp.dest('./public'));         //输出到目标目录
});

// 压缩public目录下的css文件
gulp.task('compressCss', function () {
    var option = {
        rebase: false,
        //advanced: true,               //类型：Boolean 默认：true [是否开启高级优化（合并选择器等）]
        compatibility: 'ie7',         //保留ie7及以下兼容写法 类型：String 默认：''or'*' [启用兼容模式； 'ie7'：IE7兼容模式，'ie8'：IE8兼容模式，'*'：IE9+兼容模式]
        //keepBreaks: true,             //类型：Boolean 默认：false [是否保留换行]
        //keepSpecialComments: '*'      //保留所有特殊前缀 当你用autoprefixer生成的浏览器前缀，如果不加这个参数，有可能将会删除你的部分前缀
    }
    return gulp.src(['./public/**/*.css','!./public/**/*.min.css'])  //排除的css
        .pipe(gulpif(!isScriptAll, changed('./public')))
        .pipe(gulpif(isDebug,debug({title: 'Compress CSS:'})))
        .pipe(plumber())
        .pipe(cleancss(option))
        .pipe(gulp.dest('./public'));
});

// 压缩public目录下的html文件
gulp.task('compressHtml', function () {
    var cleanOptions = {
        protect: /<\!--%fooTemplate\b.*?%-->/g,             //忽略处理
        unprotect: /<script [^>]*\btype="text\/x-handlebars-template"[\s\S]+?<\/script>/ig //特殊处理
    }
    var minOption = {
        collapseWhitespace: true,           //压缩HTML
        collapseBooleanAttributes: true,    //省略布尔属性的值  <input checked="true"/> ==> <input />
        removeEmptyAttributes: true,        //删除所有空格作属性值    <input id="" /> ==> <input />
        removeScriptTypeAttributes: true,   //删除<script>的type="text/javascript"
        removeStyleLinkTypeAttributes: true,//删除<style>和<link>的type="text/css"
        removeComments: true,               //清除HTML注释
        minifyJS: true,                     //压缩页面JS
        minifyCSS: true,                    //压缩页面CSS
        minifyURLs: true                    //替换页面URL
    };
    return gulp.src('./public/**/*.html')
        .pipe(gulpif(isDebug,debug({title: 'Compress HTML:'})))
        .pipe(plumber())
        .pipe(htmlclean(cleanOptions))
        .pipe(htmlmin(minOption))
        .pipe(gulp.dest('./public'));
});

// 压缩 public/uploads 目录内图片
gulp.task('compressImage', function() {
    var option = {
        optimizationLevel: 5, //类型：Number  默认：3  取值范围：0-7（优化等级）
        progressive: true,    //类型：Boolean 默认：false 无损压缩jpg图片
        interlaced: false,    //类型：Boolean 默认：false 隔行扫描gif进行渲染
        multipass: false      //类型：Boolean 默认：false 多次优化svg直到完全优化
    }
    return gulp.src('./public/uploads/**/*.*')
        .pipe(gulpif(!isScriptAll, changed('./public/uploads')))
        .pipe(gulpif(isDebug,debug({title: 'Compress Images:'})))
        .pipe(plumber())
        .pipe(imagemin(option))
        .pipe(gulp.dest('./public/uploads'));
});

// 用run-sequence并发执行，同时处理html，css，js，img
gulp.task('compress', function(cb) {
    runSequence.options.ignoreUndefinedTasks = true;
    runSequence(['compressHtml', 'compressCss', 'compressJs'],cb);
});

// 执行顺序： 清除public目录 -> 产生原始博客内容 -> 执行压缩混淆 -> 部署到服务器
gulp.task('build', function(cb) {
    runSequence.options.ignoreUndefinedTasks = true;
    runSequence('clean', 'generate', 'compress', 'deploy', cb);
});

// 默认任务
gulp.task('default', 
	gulp.series('clean','generate',
		gulp.parallel('compressHtml','compressCss','compressImage')
	)
);
```

### 十三、Hexo 新建文章插入图片
##### 安装图片插件
```
# npm install -g cnpm --registry=https://registry.npm.taobao.org
# cnpm install https://github.com/CodeFalling/hexo-asset-image --save

npm install hexo-asset-image --save
```
> 如果控制台出现如下信息

```
found 1 low severity vulnerability
  run `npm audit fix` to fix them, or `npm audit` for details
```
记得修复相关介绍如下
>npm audit ： npm@5.10.0 & npm@6，允许开发人员分析复杂的代码，并查明特定的漏洞和缺陷。
npm audit fix ：npm@6.1.0,  检测项目依赖中的漏洞并自动安装需要更新的有漏洞的依赖，而不必再自己进行跟踪和修复。

##### 修复
```
# 修复命令
npm audit fix
```
##### 插入图片
当插件安装成功后，你新建文章 
例：`hexo new "Hexo笔记" `，则在`\source\_posts` 会有一个名为 `Hexo笔记` 的文件夹
只需把图片放里面即可引用
1、把主页配置文件 `_config.yml` 里的`post_asset_folder:`这个选项设置为 `true`
2、然后只需要在 `Hexo笔记.md` 中按照markdown的格式引入图片：`![你想输入的替代文字](/Hexo笔记/你要引用的图片名称.jpg)`

### 十四、添加本地搜索
##### 1、安装插件
```
npm install hexo-generator-searchdb --save
```
##### 2、站点配置文件`_config.yml` 
在最后编辑或添加如下信息：
```
search:
    path: search.xml
    field: post
    format: html
    limit: 5000
```
##### 3、打开主题配置文件
在`\themes\next\_config.yml` 查找`local_search` 修改如下
```yml
local_search:
    enable: true
```

### 十五、在页面顶部，实现`fork me on GitHub`

代码样式地址：
+ [https://github.blog/2008-12-19-github-ribbons/](https://github.blog/2008-12-19-github-ribbons/)
+ [http://tholman.com/github-corners/](http://tholman.com/github-corners/)
+ 打开如上的任意一个网站，选择自己喜欢的样式
+ 然后粘贴刚才复制的代码到`themes/next/layout/_layout.swig`文件中(放在`<div class="headband"></div>`的下面)，并把`href`改为你的`Github`地址,例如下
```
<a href="https://github.com/yourName" class="github-corner" aria-label="View source on GitHub"><svg width="80" height="80" viewBox="0 0 250 250" style="fill:#151513; color:#fff; position: absolute; top: 0; border: 0; right: 0;" aria-hidden="true"><path d="M0,0 L115,115 L130,115 L142,142 L250,250 L250,0 Z"></path><path d="M128.3,109.0 C113.8,99.7 119.0,89.6 119.0,89.6 C122.0,82.7 120.5,78.6 120.5,78.6 C119.2,72.0 123.4,76.3 123.4,76.3 C127.3,80.9 125.5,87.3 125.5,87.3 C122.9,97.6 130.6,101.9 134.4,103.2" fill="currentColor" style="transform-origin: 130px 106px;" class="octo-arm"></path><path d="M115.0,115.0 C114.9,115.1 118.7,116.5 119.8,115.4 L133.7,101.6 C136.9,99.2 139.9,98.4 142.2,98.6 C133.8,88.0 127.5,74.4 143.8,58.0 C148.5,53.4 154.0,51.2 159.7,51.0 C160.3,49.4 163.2,43.6 171.4,40.1 C171.4,40.1 176.1,42.5 178.8,56.2 C183.1,58.6 187.2,61.8 190.9,65.4 C194.5,69.0 197.7,73.2 200.1,77.6 C213.8,80.2 216.3,84.9 216.3,84.9 C212.7,93.1 206.9,96.0 205.4,96.6 C205.1,102.4 203.0,107.8 198.3,112.5 C181.9,128.9 168.3,122.5 157.7,114.1 C157.9,116.9 156.7,120.9 152.7,124.9 L141.0,136.5 C139.8,137.7 141.6,141.9 141.8,141.8 Z" fill="currentColor" class="octo-body"></path></svg></a><style>.github-corner:hover .octo-arm{animation:octocat-wave 560ms ease-in-out}@keyframes octocat-wave{0%,100%{transform:rotate(0)}20%,60%{transform:rotate(-25deg)}40%,80%{transform:rotate(10deg)}}@media (max-width:500px){.github-corner:hover .octo-arm{animation:none}.github-corner .octo-arm{animation:octocat-wave 560ms ease-in-out}}</style>
```

### 十六、网站底部字数统计
##### 1、安装插件
```
npm install hexo-wordcount --save
```
##### 2、然后在`/themes/next/layout/_partials/footer.swig`文件尾部加上：
```
<div class="theme-info">
  <div class="powered-by"></div>
  <span class="post-count">博客全站共{{ totalcount(site) }}字</span>
</div>
```

### 十七、侧栏加入已运行的时间
+ 在文件`~/themes/next/layout/_custom/sidebar.swig` 中加入如下代码
```
<div id="days"></div>
<script>
function show_date_time(){
window.setTimeout("show_date_time()", 1000);
BirthDay=new Date("04/10/2017 15:13:14");
today=new Date();
timeold=(today.getTime()-BirthDay.getTime());
sectimeold=timeold/1000
secondsold=Math.floor(sectimeold);
msPerDay=24*60*60*1000
e_daysold=timeold/msPerDay
daysold=Math.floor(e_daysold);
e_hrsold=(e_daysold-daysold)*24;
hrsold=setzero(Math.floor(e_hrsold));
e_minsold=(e_hrsold-hrsold)*60;
minsold=setzero(Math.floor((e_hrsold-hrsold)*60));
seconds=setzero(Math.floor((e_minsold-minsold)*60));
document.getElementById('days').innerHTML="已运行 "+daysold+" 天 "+hrsold+" 小时 "+minsold+" 分 "+seconds+" 秒";
}
function setzero(i){
if (i<10)
{i="0" + i};
return i;
}
show_date_time();
</script>
```
+ 把`BirthDay` 改成你自己的即可  
+ 要是不喜欢颜色，感觉不好看在文件：`/themes/next/source/css/_custom/custom.styl` 添加
```
// 自定义的侧栏时间样式
#days {
    display: block;
    color: #2cd724;
    font-size: 13px;
    margin-top: 15px;
}
```

### 十八、让页脚的心跳起来
+ 修改文件位置：`/themes/next/_config.yml`找到`footer`修改如下
```
footer:
  # Specify the date when the site was setup.
  # If not defined, current year will be used.
  #since: 2015

  # Icon between year and copyright info.
  icon:
    # Icon name in fontawesome, see: https://fontawesome.com/v4.7.0/icons/
    # `heart` is recommended with animation in red (#ff0000).
    name: heart
    # If you want to animate the icon, set it to true.
    animated: true
    # Change the color of icon, using Hex Code.
    color: "#ff0000"
```

### 十九、安装Markdown流程图插件
+ 好像hexo默认是不支持流程图的语法的，需要安装插件
#### 1、Mermaid
+ 查看Github:[https://github.com/webappdevelp/hexo-filter-mermaid-diagrams](https://github.com/webappdevelp/hexo-filter-mermaid-diagrams)

**第一步：安装依赖**
```
// 安装依赖
npm install hexo-filter-mermaid-diagrams -D
```

**第二步：修改hexo配置文件**
+ 之后在hexo的配置文件：`_config.yml`添加如下内容：
```
# mermaid chart
mermaid: ## mermaid url https://github.com/knsv/mermaid
  enable: true  # default true
  version: "8.11.0" # default v7.1.2
  options:  # find more api options from https://github.com/knsv/mermaid/blob/master/src/mermaidAPI.js
    startOnload: true  // default true
```

**第三步：修改主题下面的footer文件**
+ 路径在：`themes\next\layout\_partials\`(这里以`next`为例)下面footer文件
+ 因为hexo的主题有很多，有些footer文件的后缀都不一样有：`.swig`、`.ejs`、`.pug`的
+ `next`主题下面是`footer.swig`后缀,则在文件最后添加如下

*如果是footer.swig*则添加如下：
```
{% if theme.mermaid.enable %}
  <script src='https://unpkg.com/mermaid@{{ theme.mermaid.version }}/dist/mermaid.min.js'></script>
  <script>
    if (window.mermaid) {
      mermaid.initialize({{ JSON.stringify(theme.mermaid.options) }});
    }
  </script>
{% endif %}
```

*如果是after-footer.ejs*则添加如下：
```
<% if (theme.mermaid.enable) { %>
  <script src='https://unpkg.com/mermaid@<%= theme.mermaid.version %>/dist/mermaid.min.js'></script>
  <script>
    if (window.mermaid) {
      mermaid.initialize({theme: 'forest'});
    }
  </script>
<% } %>
```


*如果是after_footer.pug*则添加如下：
```
if theme.mermaid.enable == true
  script(type='text/javascript', id='maid-script' mermaidoptioins=theme.mermaid.options src='https://unpkg.com/mermaid@'+ theme.mermaid.version + '/dist/mermaid.min.js' + '?v=' + theme.version)
  script.
    if (window.mermaid) {
      var options = JSON.parse(document.getElementById('maid-script').getAttribute('mermaidoptioins'));
      mermaid.initialize(options);
    }

```

#### 2、flow
+ flow 类型的流程图
**安装依赖即可**
```
npm install  hexo-filter-flowchart -D
```

#### 3、sequence
+ sequence 类型的流程图
**安装依赖即可**
```
npm install  hexo-filter-sequence -D
```


## 五、部署到GitHub
### 准备工作
在Github 创建一个仓库为blog,并从master 分支，新建一个dev分支
dev 分支就是我们的源代码分支，master,就是我们生成的静态文件。

### 一、安装Git部署插件
```
# 安装git 部署插件
npm install hexo-deployer-git --save
```

### 二、修改站点配置文件
修改 配置文件 `_config.yml` 在`deploy` 选项,修改如下
```yml
# Deployment
## Docs: https://hexo.io/docs/deployment.html
deploy:
  type: git
  repo: https://github.com/rstyro/blog.git	# 你的github 仓库地址
  branch: master
```

### 三、多台终端部署
```sh
# 此时在另一终端更新博客，只需要将Github的dev分支clone下来，进行初次的相关配置
git clone -b dev https://github.com/rstyro/blog.git  //将Github中hexo分支clone到本地
cd  blog  //切换到刚刚clone的文件夹内
npm install    //注意，这里一定要切换到刚刚clone的文件夹内执行，安装必要的所需组件，不用再init
hexo new post "new blog name"   //新建一个.md文件，并编辑完成自己的博客内容
git add source  //经测试每次只要更新sorcerer中的文件到Github中即可，因为只是新建了一篇新博客
git commit -m "XX"
git push origin hexo  //更新分支
hexo d -g   //push更新完分支之后将自己写的博客对接到自己搭的博客网站上，同时同步了Github中的master
```

> 参考链接：
> + http://theme-next.iissnan.com
> + https://io-oi.me/tech/add-chinese-zodiac-to-next.html#main


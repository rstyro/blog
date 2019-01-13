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

### 三、新建页面
```sh
hexo new page tags
hexo new page about
hexo new page categories
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

> 参考链接：http://theme-next.iissnan.com

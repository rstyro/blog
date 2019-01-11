---
title: Hexo-笔记
date: 2019-01-10 18:37:24
tags: "Hexo"
categories: 学习笔记
---

## 一、前置条件

#### 1、安装Git
#### 2、安装Node.js


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


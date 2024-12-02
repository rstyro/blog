---
title: Hexo-笔记
date: 2024-11-30 18:37:24
updated: 2024-11-30 18:37:24
tags: [Hexo]
categories: 其他
description: Hexo相关配置笔记，还有一些next主题自定义配置
---

## 一、前置条件

#### 1、安装Git
> 下载地址：https://git-scm.com/
#### 2、安装Node.js
> 下载地址：http://nodejs.cn/download/

<!--more-->

**配置npm镜像**
- 如果你网络好可以忽略

```bash
# 使用 npm 命令来设置淘宝的 npm 镜像
npm config set registry https://registry.npmmirror.com

# 验证配置,如果输出结果是 https://registry.npmmirror.com/，则表示配置成功
npm config get registry

# 如果你需要切换回 npm 的官方镜像，可以使用以下命令
npm config set registry https://registry.npmjs.org/
# 验证配置,如果输出结果是 https://registry.npmjs.org/，则表示配置成功
npm config get registry

# 还有一种，使用 cnpm 替代 npm 进行包管理，它会直接使用淘宝的镜像，需要安装 cnpm
npm install -g cnpm --registry=https://registry.npmmirror.com
```


## 二、安装Hexo


```bash
# 安装 hexo,  -D 是局部安装并添加到package.json ，-g 是全局安装不仅限于当前项目的目录下
npm install -g hexo-cli


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
编辑文件路径站点根目录 `/`下 `_config.yml`

- 找到 `theme` 字段，并将其值更改为 `next`

## 四、配置

- 站点配置文件： `根目录/_config.yml`
- 主题配置文件：`根目录/themes/主题名称/_config.yml`

### 一、站点配置

####  1、基本配置

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
> 

#### 2、设置语言
- 编辑 站点配置文件， 将 language 设置成你所需要的语言

```
language: zh-CN
```

#### 3、首页只显示部分摘要（不显示全文）
- 首页显示的文章内容过长，对其进行截断

**方法一：写概述**
- 在文章的 frontmatter 中添加description，其中description中的内容就会被显示在首页上，其余一律不显示。

```
---
title: Hello World
date: 2024-11-30 12:55:10
description: 这是这篇文章显示在首页的内容，可以写这篇文章的一个总结。
---

# todo
```

**方法二：文章截断**
- 在文章内容中，需要截断的地方加入 `<!--more-->`
- 首页就会显示这条以上的所有内容，隐藏接下来的所有内容。


#### 4、图片展示配置
- 旧版的hexo，markdown图片需要安装`npm install hexo-asset-img --save`或者`hexo-asset-image`
- 但是新版不需要装插件了，`hexo-renderer-marked` 可以正确转换图片
- 在站点配置文件中修改如下：

```bash
# 创建文章时会自动创建一个同名的文件夹，用于存放资源文件
post_asset_folder: true
# 不要将链接改为与根目录的相对地址。此为默认配置。
relative_link: false
# 添加如下内容
marked:
  #将文章根路径添加到文章内的链接之前。
  prependRoot: true
  # 在根据prependRoot的设置在所有链接开头添加文章根路径之前，先将文章内资源的路径解析为相对于资源目录的路径。
  postAsset: true

```
- 然后在文章中引用图片：`![](test.png)` 这个test.png直接放在同名文件夹即可

 

### 二、主题基本配置
- 主题使用next

#### 1、外观设置
- Scheme 是 NexT 提供的一种特性，借助于 Scheme，NexT 为你提供多种不同的外观。

```
# Schemes
# scheme: Muse
scheme: Mist
# scheme: Pisces
# scheme: Gemini
```

- Muse - 默认 Scheme，这是 NexT 最初的版本，黑白主调，大量留白
- Mist - Muse 的紧凑版本，整洁有序的单栏外观
- Pisces - 双栏 Scheme，小家碧玉似的清新
- Gemini mini版本，好像和Pisces差不多
- 

#### 2、顶部导航菜单修改

修改主题配置文件，在菜单项添加以下内容(把注释打开即可)
```yml
menu:
  home: / || fa fa-home
  about: /about/ || fa fa-user
  tags: /tags/ || fa fa-tags
  categories: /categories/ || fa fa-th
  archives: /archives/ || fa fa-archive
  guestbook: /guestbook/ || fa fa-comments
  #schedule: /schedule/ || fa fa-calendar
  #sitemap: /sitemap.xml || fa fa-sitemap
  #commonweal: /404/ || fa fa-heartbeat

# Enable / Disable menu icons / item badges.
menu_settings:
  icons: true
  badges: false
```

- 其中questbook 是新增的，需要修改简体中文对应的翻译文件 `languages/zh-CN.yml`，在 menu 字段下添加一项：

```
menu:
  home: 首页
  archives: 归档
  categories: 分类
  tags: 标签
  about: 关于
  search: 搜索
  schedule: 日程表
  sitemap: 站点地图
  commonweal: 公益 404
  guestbook: 留言板
```

#### 3、设置头像
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

#### 4、侧边栏社交链接
- 侧栏社交链接的修改包含两个部分，第一是链接，第二是链接图标

```
# Social Links
# Usage: `Key: permalink || icon`
# Key is the link label showing to end users.
# Value before `||` delimiter is the target permalink, value after `||` delimiter is the name of Font Awesome icon.
social:
  GitHub: https://github.com/rstyro || fab fa-github
  Gitee: https://gitee.com/rstyro || fab fa-codiepie
  简书: https://www.jianshu.com/u/651c15a1758a || fa fa-book
```

#### 5、开启打赏功能
-  只需要 主题配置文件 中填入 微信 和 支付宝 收款二维码图片地址 即可开启该功能。

```
# Reward (Donate)
# Front-matter variable (unsupport animation).
reward_settings:
  # If true, reward will be displayed in every article by default.
  enable: true
  animation: false
  comment: 您的打赏，是我创作的动力！不给钱？那我只能靠想象力充饥了。

reward:
  wechatpay: /images/wechat_pay.jpg
  alipay: /images/alipay.jpg
  #paypal: /images/paypal.png
  #bitcoin: /images/bitcoin.png
```

#### 6、友情链接
- 主题配置文件添加 links

```
# Blog rolls
links_settings:
  icon: fa fa-link
  title: 友链
  # Available values: block | inline
  layout: block

links:
  胖不了小陆: https://rstyro.github.io/blog/
```

#### 7、修改网页底部

-  修改主题配置文件的footer字段，如下：

```
footer:
  # 网站底部显示网站的开始时间
  since: 2017-04-10

  # Icon between year and copyright info.
  icon:
    # 显示的图标. See: https://fontawesome.com/icons
    name: fa fa-heart
    # 图标动画，比如： 心形会跳动
    animated: true
    # 图标颜色
    color: "#ff0000"

  # 版权文案.
  copyright: 以梦为马，诗酒趁年华

  # 去掉 Hexo & NexT 的powered文案
  powered: false
```

- 看情况修改即可



#### 8、首页文章添加阴影
- 在next主题文件下找到`themes\next\source\css\_common\components\post`的`post.styl`文件在.post_block位置,更改如下:

```js
if (hexo-config('motion.transition.post_block')) {
    .post-block {
       opacity: 0;
       margin-top: 60px;
       margin-bottom: 60px;
       padding: 25px;
       -webkit-box-shadow: 0 0 5px rgba(202, 203, 203, .5);
       -moz-box-shadow: 0 0 5px rgba(202, 203, 204, .5);
    }
    .pagination, .comments {
      opacity: 0;
    }
  }

```

#### 9、显示当前浏览进度
- 搜索关键字 `scrollpercent`，把 false 改为 true

```
back2top:
  enable: true
  # Back to top in sidebar.
  sidebar: false
  # Scroll percent label in b2t button.
  scrollpercent: true
```

#### 10、文章的标签改为图标
- 修改主题配置文件把 tag_icon=true

```
tag_icon: true
```

#### 11、修改加载特效
- 由于网页不可能一直都秒进，总会等待一段时间的，所以可以设置顶部加载条
- 安装 theme-next-pace

```
# 进入到next主题根目录
$ cd themes/next

# 下载包 到next目录下的 source/lib/pace
$ git clone https://github.com/theme-next/theme-next-pace source/lib/pace
```
- 然后修改主题配置文件，把pace.enable设置为true即可

```
# Progress bar in the top during page loading.
# Dependencies: https://github.com/theme-next/theme-next-pace
# For more information: https://github.com/HubSpot/pace

pace:
  enable: true
  # corner-indicator | fill-left | flat-top | flash |  minimal
  theme: flash
```
- 特效例子可以查看：https://codebyzach.github.io/pace/

#### 12、修改网页logo图标
- 修改主题配置文件的favicon字段

```
favicon:
  small: /images/favicon.jpg
  medium: /images/favicon.jpg
  apple_touch_icon: /images/favicon.jpg
  safari_pinned_tab: /images/favicon.jpg
  #android_manifest: /images/manifest.json
  #ms_browserconfig: /images/browserconfig.xml
```

#### 13、代码块配置
- 修改主题配置文件如下

```
codeblock:
  #高亮的主题色，查看: https://github.com/chriskempson/tomorrow-theme
  highlight_theme: night
  # 是否开启复制代码按钮
  copy_button:
    enable: true
    # 复制结果显示
    show_result: true
    # 代码边框样式，可选: default | flat | mac
    style:mac
```

#### 14、右上角显示Github
- 把github_banner.enable设置为true

```
# `Follow me on GitHub` banner in the top-right corner.
github_banner:
  enable: true
  permalink: https://github.com/rstyro
  title: Follow me on GitHub
```


#### 15、归档页面添加十二生肖图标
- 首先，点击[这里](https://blog.shipengx.com/download/chinese-zodiac.zip)下载十二生肖字体。下载后将解压的三个字体文件全部放在 hexo/source/fonts/目录下（若无 fonts 文件夹需要自行创建）
- 编辑 `hexo/themes/next/layout/_macro/post-collapse.swig` 文件
- 找到`class=collection-header` 然后在后面加入`< <div class="chinese-zodiac">...</div>` 这一段就可以了

```
{%- if year !== current_year %}
    {%- set current_year = year %}
    <div class="collection-year">
      <span class="collection-header">{{ current_year }}</span>
      
      <div class="chinese-zodiac">
       {%- if current_year % 12 == 0 %}
         <i class="symbolic-animals icon-monkey"></i>
       {%- endif %}
       {%- if current_year % 12 == 1 %}
         <i class="symbolic-animals icon-rooster"></i>
       {%- endif %}
       {%- if current_year % 12 == 2 %}
         <i class="symbolic-animals icon-dog"></i>
       {%- endif %}
       {%- if current_year % 12 == 3 %}
         <i class="symbolic-animals icon-pig"></i>
       {%- endif %}
       {%- if current_year % 12 == 4 %}
         <i class="symbolic-animals icon-rat"></i>
       {%- endif %}
       {%- if current_year % 12 == 5 %}
         <i class="symbolic-animals icon-ox"></i>
       {%- endif %}
       {%- if current_year % 12 == 6 %}
         <i class="symbolic-animals icon-tiger"></i>
       {%- endif %}
       {%- if current_year % 12 == 7 %}
         <i class="symbolic-animals icon-rabbit"></i>
       {%- endif %}
       {%- if current_year % 12 == 8 %}
         <i class="symbolic-animals icon-dragon"></i>
       {%- endif %}
       {%- if current_year % 12 == 9 %}
         <i class="symbolic-animals icon-snake"></i>
       {%- endif %}
       {%- if current_year % 12 == 10 %}
         <i class="symbolic-animals icon-horse"></i>
       {%- endif %}
       {%- if current_year % 12 == 11 %}
         <i class="symbolic-animals icon-goat"></i>
       {%- endif %}
     </div>
    </div>
  {%- endif %}
```

- 编辑上面之后，还需要添加自定义样式，新增文件：`根目录/source/_data/zodiac.styl`
- 编辑如下内容：

```
.chinese-zodiac {
  float: right;
}
@font-face {
  font-family: 'chinese-zodiac';
  font-display: swap;
  src: url('/fonts/chinese-zodiac.eot');
  src: url('/fonts/chinese-zodiac.eot') format('embedded-opentype'),
       url('/fonts/chinese-zodiac.woff2') format('woff2'),
       url('/fonts/chinese-zodiac.woff') format('woff');
  font-weight: normal;
  font-style: normal;
}
.symbolic-animals {
  display: inline-block;
  font: normal normal normal 14px/1 chinese-zodiac;
  font-size: inherit;
  text-rendering: auto;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
.icon-dragon:before { content: '\e806'; font-size: 35px;}
.icon-tiger:before { content: '\e809'; font-size: 35px;}
.icon-pig:before { content: '\e810'; font-size: 35px;}
.icon-horse:before { content: '\e813'; font-size: 35px;}
.icon-rat:before { content: '\e816'; font-size: 35px;}
.icon-goat:before { content: '\e818'; font-size: 35px;}
.icon-snake:before { content: '\e820'; font-size: 35px;}
.icon-ox:before { content: '\e822'; font-size: 35px;}
.icon-dog:before { content: '\e825'; font-size: 35px;}
.icon-rabbit:before { content: '\e826'; font-size: 35px;}
.icon-monkey:before { content: '\e829'; font-size: 35px;}
.icon-rooster:before { content: '\e82f'; font-size: 35px;}
```

- 然后在主题配置文件中编辑 `custom_file_path`新增上面添加的样式

```
# Define custom file paths.
custom_file_path:
  style: source/_data/zodiac.styl
```


### 三、插件配置
- 有些功能配置需要安装插件才能用

#### 1、本地搜索
- 搜索功能，需要安装插件

```
npm install hexo-generator-searchdb --save
```

- 修改主题配置文件，把local_search.enable设置为true

```
# Local Search
# Dependencies: https://github.com/theme-next/hexo-generator-searchdb
local_search:
  enable: true
```

#### 2、扩展流程图插件
- 需要安装流程图插件

```bash

# 安装mermaid插件
npm install hexo-filter-mermaid-diagrams --save

# 其他类型的流程图
# flow 类型的流程图
npm install  hexo-filter-flowchart --save
# sequence 类型的流程图
npm install  hexo-filter-sequence --save
```

- 安装mermaid插件之后，配置**主题配置文件**编辑Mermaid设置为true

```
# Mermaid tag
mermaid:
  enable: true
  # Available themes: default | dark | forest | neutral
  theme: default 
```


#### 3、添加评论功能:Gitalk

- 注册  OAuth Apps:[https://github.com/settings/applications/new](https://github.com/settings/applications/new)
- 注册之后生成 Client secrets，记录这个，如果忘记了就删除重新生成
- 查看 OAuth Apps：[https://github.com/settings/developers](https://github.com/settings/developers)

![](register.png)

![](client.png)

![](oauth-app.png)

- 然后在主题配置文件中配置：

```
# Gitalk
# For more information: https://gitalk.github.io, https://github.com/gitalk/gitalk
gitalk:
  enable: true
  github_id: rstyro # GitHub 仓库拥有者用戶名，用于指定存储评论的仓库
  repo: blog # 用于存储评论的GitHub仓库名称。评论将以issue的形式存储在这个仓库中
  client_id: 你的ClientId # GitHub Application Client ID
  client_secret: 你刚才生成的Secret # GitHub Application Client Secret
  admin_user: rstyro # 具有初始化GitHub issues权限的用户列表
  distraction_free_mode: true # 用“专注模式”，在这种模式下，评论框会减少其他干扰，更加简洁。
  #proxy: https://cors-anywhere.azm.workers.dev/https://github.com/login/oauth/access_token # 官方 proxy 地址
  # 现在的语言，默认即可，可选: en | es-ES | fr | ru | zh-CN | zh-TW
  language:

```

## 五、新建文章
- 上面各种主题配置好之后，就可以写文章了
- CMD控制台使用`hexo new` 生成页面或文章

### 1、生成文章命令
```bash
# 生成标签页面
hexo new page tags
# 生成关于页面
hexo new page about
# 生成分类页面
hexo new page categories

# 可以简写n ，生成test页面
hexo n page test

# 生成文章 
hexo n 文章名
```
- 打开文章，会看到在头部有这样的信息

```
---
title: 文章名
date: 2024-11-30 22:39:11
tags:
---
```


### 2、文章头部字段解析

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

### 3、自定义生成的文章模板
- 默认的文章模板比较简单，我们修改`根目录/scaffolds/post.md`即可

```
---
title: {{ title }}
date: {{ date }}
updated: {{date}}
tags: []
description: 文章描述
---

```

- 上面是我个人需要加的一些默认字段。


## 六、部署
- 可以把代码推送到Github部署到Github Pages 服务
-  安装Git部署插件


```
# 安装Git部署插件
$ npm install hexo-deployer-git --save
```

- 修改**站点配置文件**在`deploy` 修改如下：
```
# Deployment
## Docs: https://hexo.io/docs/deployment.html
deploy:
  type: git
  repo: https://github.com/rstyro/blog.git	# 你的github 仓库地址
  branch: master #部署到哪个分支
```

- 更多的配置方式：

```
# You can use this:
deploy:
  type: git
  repo: <repository url>
  branch: [branch]
  token: ''
  message: [message]
  name: [git user]
  email: [git email]
  extend_dirs: [extend directory]
  ignore_hidden: false # default is true
  ignore_pattern: regexp  # whatever file that matches the regexp will be ignored when deploying

# or this:
deploy:
  type: git
  message: [message]
  repo: <repository url>[,branch]
  extend_dirs:
    - [extend directory]
    - [another extend directory]
  ignore_hidden:
    public: false
    [extend directory]: true
    [another extend directory]: false
  ignore_pattern:
    [folder]: regexp  # or you could specify the ignore_pattern under a certain directory

# Multiple repositories
deploy:
  repo:
    # Either syntax is supported
    [repo_name]: <repository url>[,branch]
    [repo_name]:
      url: <repository url>
      branch: [branch]
```

- 安装之后就可以部署，推送到远程了，常用命令如下：


```bash

# 查看是否安装成功，查看版本号
hexo -v

# 初始化Hexo，在当前目录下，创建一个文件夹为blog 的博客
hexo init blog

#生成静态文件
hexo generate
# 缩写
heox g

# 启动,默认访问：http://localhost:4000/
hexo s

# 清除缓存，和已生成的静态文件
hexo clean

# 部署
hexo deploy

# 部署 缩写
hexo d
```

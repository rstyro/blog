---
title: 安装Nginx 
date: 2017-11-02 17:03:47
updated: 2017-11-02 17:03:47
tags: [Nginx, 开发工具]
categories: 开发工具
---

# 安装Nginx 

## 一、yum安装Nginx
+ 更新Nginx源:
`rpm -Uvh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm`
+ 安装Nginx: `yum install -y nginx`
+ 查看nginx所在文件：`whereis nginx`
+ 配置文件：`/etc/nginx/nginx.conf`
+ 启动命令：
```
systemctl start nginx        #启动
systemctl restart nginx      #重启
systemctl stop nginx         #关闭
systemctl status nginx       # 状态
```

## 二、源码安装

### 1、下载源码包
+ 最新下载地址：[http://nginx.org/en/download.html](http://nginx.org/en/download.html)
+ Nginx官网提供了三个类型的版本
+ `Mainline version`：Mainline 是 Nginx 目前主力在做的版本，可以说是开发版
+ `Stable version`：最新稳定版，生产环境上建议使用的版本
+ `Legacy versions`：遗留的老版本的稳定版

### 2、开始安装
```
# 安装依赖
yum install -y gcc gcc-c++ pcre pcre-devel zlib zlib-devel  openssl openssl-devel

# 下载源文件
xwget http://nginx.org/download/nginx-1.12.2.tar.gz

# 解压
tar -zxvf nginx-1.12.2.tar.gz -C /opt/

# 进入解压文件
cd /opt/nginx-1.12.2

# 可通过`./configure --help | more ` 查看配置参数列表
# --prefix=/usr/local/nginx  指定安装目录，
# --with-http_stub_status_module 监控页面
# --with-http_ssl_module		ssl ,搭建https 时需要此模块
# ./configure --prefix=/usr/local/nginx --with-http_stub_status_module --with-http_ssl_module
# 检测配置，生成Makefile，为下一步的编译做准备
./configure --help --prefix=/usr/local/nginx

# 编译并安装
make && make install
```

### 3、启动Nginx
+ 进入nginx 目录：`/usr/local/nginx` ，下面有4个目录
+ conf -- 配置文件  
+ html -- 网页文件
+ logs -- 日志文件 
+ sbin -- 主要二进制程序
```
# 进入目录
cd /usr/local/nginx/

# 启动nginx 
sbin/nginx

# 重新加载配置
sbin/nginx -s reload

# 关闭nginx
bin/nginx -s stop

```

**浏览器访问，直接在地址栏写上服务器ip 即可，nginx 默认启动端口是80端口。**



### 4、可能出现的错误

#### 1、缺少C语言环境
> 1、checking for C compiler cc ... not found
```
# 解决方法
yum install -y gcc gcc-c++
```

#### 2、需要安装pcre pcre-devel,为了让nginx 支持 rewrite 这个模块
> 2、./configure: error: the HTTP rewrite module requires the PCRE library.
You can either disable the module by using --without-http_rewrite_module
option, or install the PCRE library into the system, or build the PCRE library
statically from the source with nginx by using --with-pcre=<path> option。


```
# 解决方法
yum install -y pcre pcre-devel
```

#### 3、安装 zlib zlib-devel ,为了让nginx 支持 gzip 模块
> 3、./configure: error: the HTTP gzip module requires the zlib library.
You can either disable the module by using --without-http_gzip_module
option, or install the zlib library into the system, or build the zlib library
statically from the source with nginx by using --with-zlib=<path> option

```
# 解决方法
yum install -y zlib zlib-devel
```

#### 4、端口没开放 
> 4、都没报错，但浏览器访问ip，访问不到。请检查80端口是否开放。可以用windows 的telnet 命令 `telnet 你的服务器ip 80` ,如果提示 telent 未找到，请百度搜 ：开启telnet服务，这里就不多说了。


## 三、Nginx 命令
### 1、信号控制
#### 语法：有如下两个
+ Kill -信号选项 nginx的主进程号
+ Kill -信号选项 `cat /usr/local/nginx/logs/nginx.pid`

#### 信号选项如下：

|信号选项|选项说明|
|--|--|
|TERM, INT | Quick shutdown|
|QUIT	| Graceful shutdown  优雅的关闭进程,即等请求结束后再关闭|
|HUP	| Configuration reload ,Start the new worker processes with a new configuration Gracefully shutdown the old worker processes 改变配置文件,平滑的重读配置文件|
|USR1	| Reopen the log files 重读日志,在日志按月/日分割时有用|
|USR2	| Upgrade Executable on the fly 平滑的升级|
|WINCH	| Gracefully shutdown the worker processes 优雅关闭旧的进程(配合USR2来进行升级)|

##### 栗子：`kill -QUIT $( cat /usr/local/nginx/logs/nginx.pid )`  停止nginx 

### 2、二进制文件加参数

|参数|参数说明|
|--|--|
|-?, -h|	Print help.|
|-v	|Print version.|
|-V	|Print NGINX version, compiler version and configure parameters.
|-t	|Don’t run, just test the configuration file. NGINX checks configuration for correct syntax and then try to open files referred in configuration.|
|-q	|Suppress non-error messages during configuration testing.|
|-s signal  |signal	Send signal to a master process: stop -- 停止, quit -- 也是停止比较优雅, reopen -- 重新生成日志, reload -- 重新加载日志. (version >= 0.7.53)|
|-p prefix |prefix	Set prefix path (default: /usr/local/nginx/). (version >= 0.7.53)|
|-c filename |filename	Specify which configuration file NGINX should use instead of the default.|
|-g directives |	Set global directives. (version >= 0.7.4)|

##### 栗子：`/usr/bin/nginx -s stop`  停止nginx


> 参考自：[https://www.nginx.com/resources/wiki/start/topics/tutorials/commandline/](https://www.nginx.com/resources/wiki/start/topics/tutorials/commandline/)

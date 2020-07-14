---
title: Nginx 配置详解
date: 2017-11-03 15:55:33
tags: [Nginx]
categories: 开发工具
---
# Nginx 配置参数详解

### 默认配置文件在 nginx 目录下的 `conf/nginx.conf` 内容大概如下：
![](85946.png)
# 所有我就把它分为 全局配置、events 、http 吧
## 一、全局区配置

```
# 运行用户与用户组，用户组可忽略
user  nobody;

# worker进程的个数，通常应该略少于或等于CPU物理核心数，也可以使用auto自动获取
worker_processes  1

# 指定所有worker进程所能打开的最大文件句柄数，系统的默认值可通过 ` ulimit -n` 查看，一般都是1024
worker_rlimit_nofile 100000;

# 生成错误日志的地址，默认是nginx 目录下的logs/error.log
error_log  logs/error.log

# 指定nginx守护进程的pid文件,默认默认是nginx 目录下的logs/nginx.pid
pid logs/nginx.pid

# 是否以守护进程方式运行nginx；调试时应该设置为off
daemon {on|off}

# 是否以master/worker模型来运行；调试时可以设置为off
master_process {on|off}

```

## 二、events 事件相关的配置
```
events {

	# 单个worker进程打开的最大并发连接数，worker_processes*worker_connections
    worker_connections 1024;
	
	# 指明使用的事件模型：建议让Nginx自行选择,linux建议epoll，FreeBSD建议采用kqueue，window下不指定。
    use [epoll|rtsig|select|poll];
	
	# keepalive超时时间。
	keepalive_timeout 60;
	
	# 这个将为打开文件指定缓存，默认是没有启用的，max指定缓存数量，建议和打开文件数一致，inactive是指经过多长时间文件没被请求后删除缓存。
	open_file_cache max=65535 inactive=60s;
	
	# 这个是指多长时间检查一次缓存的有效信息。
	open_file_cache_valid 80s;


}
```

## 三、http 服务器配置
```
http {
  # include指在当前文件中包含另一个文件内容
  # 设定mime类型,类型由mime.type文件定义
  include    conf/mime.types;
  
  # 这里是代理的配置文件，建议另建立一个proxy.conf 然后在这里include 进行引用。
  include    /etc/nginx/proxy.conf;
  
  #添加fastcgi 的配置，具体可看官网栗子:https://www.nginx.com/resources/wiki/start/topics/examples/fastcgiexample/
  include    /etc/nginx/fastcgi.conf;
  
  # 首页索引
  index    index.html index.htm index.php;
  
 #设置文件使用默认的mine-type
  default_type application/octet-stream;
  
  # 日志格式设置。
  # $remote_addr与$http_x_forwarded_for用以记录客户端的ip地址；
  # $remote_user：用来记录客户端用户名称；
  # $time_local： 用来记录访问时间与时区；
  # $status： 用来记录请求状态；成功是200，
  # $request： 用来记录请求的url与http协议；
  # $body_bytes_sent ：记录发送给客户端文件主体内容大小；
  # $http_referer：用来记录从那个页面链接访问过来的；
  # $http_user_agent：记录客户浏览器的相关信息；
  log_format   main '$remote_addr - $remote_user [$time_local]  $status '
    '"$request" $body_bytes_sent "$http_referer" '
    '"$http_user_agent" "$http_x_forwarded_for"';
   
   log_format mylog  '$remote_addr - "$http_x_forwarded_for" - $remote_user [$time_local]  $status '
    '"$request" $body_bytes_sent "$http_referer" '
    '"$http_user_agent" ';
  # 声明log   log位置          log格式;
  access_log logs/access_8080.log mylog;   

  # sendfile指令指定 nginx 是否调用sendfile 函数（zero copy 方式）来输出文件，对于普通应用，应设为on。如果用来进行下载等应用磁盘IO重负载应用，可设置为off，以平衡磁盘与网络IO处理速度，降低系统uptime
  sendfile     on;
  
  # 打开linux下TCP_CORK，sendfile打开时才有效，作减少报文段的数量之用 
  tcp_nopush   on;
  
  # 保存服务器名字的hash表 大小，如果server很多，就调大一点
  server_names_hash_bucket_size 128; # this seems to be required for some vhosts

  
  #在一个长连接所能够允许请求的最大资源数
  keepalive_requests 20;
  
  #为制定类型的User Agent禁用长连接
  keepalive_disable [msie6|safari|none];
  
  #是否对长连接使用TCP_NODELAY选项,不将多个小文件合并传输
  tcp_nodelay on;
  
  
  #设置nginx采用gzip压缩的形式发送数据，减少发送数据量，但会增加请求处理时间及CPU处理时间，需要权衡
  gzip on;
  
  #加vary给代理服务器使用，针对有的浏览器支持压缩，有个不支持，根据客户端的HTTP头来判断是否需要压缩
  gzip_vary on;
  
  #nginx在压缩资源之前，先查找是否有预先gzip处理过的资源
  #!gzip_static on;
  
  #为指定的客户端禁用gzip功能
  gzip_disable "MSIE[1-6]\.";
  
  #允许或禁止压缩基于请求和相应的响应流，any代表压缩所有请求
  gzip_proxied any;
  
  #设置对数据启用压缩的最少字节数，如果请求小于1024字节则不压缩，会影响请求速度
  gzip_min_length 1024;
  
  #设置数据压缩等级，1-9之间，9最慢压缩比最大
  gzip_comp_level 6;
  
  #设置需要压缩的数据格式
  gzip_types text/plain text/css text/xml text/javascript  application/json application/x-javascript application/xml application/xml+rss; 
  
  
  #定义错误提示页面
  error_page 500 502 503 504 /50x.html;
  location = /50x.html {
    root html;
  }

  # PHP
  server { # php/fastcgi
    listen       80;
    server_name  domain1.com www.domain1.com;
    access_log   logs/domain1.access.log  main;
    root         html;

    location ~ \.php$ {
      fastcgi_pass   127.0.0.1:1025;
    }
  }
  
  # JSP 
  server {
	listen 80;
	server_name jspServer;
	access_log logs/tomcat.access.log main;
	root /usr/local/tomcat/webapps/ROOT;
	
	location ~ \.jsp${
		proxy_pass http://127.0.0.1:8080;
		index index.jsp;
	}
  }

  # 这里可以弄一个静态资源访问服务器
  server { # simple reverse-proxy
  
  
    #监听80端口
    listen 80;
	
    #定义主机名，主机名可以有多个，名称还可以使用正则表达式(~)或通配符
    #(1)先做精确匹配检查
    #(2)左侧通配符匹配检查：*.lrshuai.top
    #(3)右侧通配符匹配检查：mail.*
    #(4)正则表达式匹配检查：如~^.*\.lrshuai\.top$
    #(5)detault_server
    server_name  lrshuai.top www.lrshuai.top;
	
	#设定主机的访问日志
    access_log   logs/blog.access.log  main;

    # serve static files - 静态文件过滤
    location ~ ^/(images|javascript|js|css|flash|media|static)/  {
	  # 定义服务器的默认网站根目录位置
      root    /var/www/virtual/big.server.com/htdocs;
	  # expires 30s 缓存30秒;
      # expires 30m 缓存30分钟;
      # expires 2h 缓存2小时;
      # expires 30d 缓存30天;
      expires 30d;
    }

    # pass requests for dynamic content to rails/turbogears/zope, et al
	# 负载，请求转发到8080端口的服务器
    location / {
      proxy_pass      http://127.0.0.1:8080;
    }
  }

  # 定义负载均衡服务器列表，名字为：big_server_com
  # weight参数表示权重值，权值越高被分配到的几率越大
  upstream big_server_com {
	# 每个请求按访问ip的hash结果分配，这样每个访客固定访问一个后端服务器，可以解决session的问题。
	ip_hash;
    server 127.0.0.3:8000 weight=5;
    server 127.0.0.3:8001 weight=5;
    server 192.168.0.1:8000;
    server 192.168.0.1:8001;
  }

  # 负载均衡配置
  server { # simple load balancing
    listen          80;
    server_name     big.server.com;
    access_log      logs/big.server.access.log main;
	
	# location [=|~|~*|^~] uri {...}
    # 功能：允许根据用户请求的URI来匹配定义的个location，匹配到时，此请求将被相应的location配置块中的配置所处理
    # =：表示精确匹配检查
    # ~：正则表达式模式匹配检查，区分字符大小写
    # ~*：正则表达式模式匹配检查，不区分字符大小写
    # ^~：URI的前半部分匹配，不支持正则表达式
    # !~：开头表示区分大小写的不匹配的正则
    # !~*：开头表示不区分大小写的不匹配的正则
    # /：通用匹配，任何请求都会被匹配到
    location / {
	
		#引用反向代理的配置，配置文件目录根据编译参数而定
		#如果编译时加入了--conf-path=/etc/nginx/nginx.conf指定了配置文件的路径那么就把proxy.conf放在/etc/nginx/目录下
		#如果没有制定配置文件路径那么就把proxy.conf配置放到nginx的conf目录下,要么写绝对路径
		include proxy.conf; 
		
		# 定义后端负载服务器组
		proxy_pass      http://big_server_com;
    }
  }
}
```

#### proxy.conf
```
#　后端的服务器可以通过X-Forwarded-For获取用户真实IP
proxy_redirect          off;
proxy_set_header        Host            $host;
proxy_set_header        X-Real-IP       $remote_addr;
proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;

# 允许客户端请求的最大单文件字节数
client_max_body_size    10m;
client_body_buffer_size 512k;

# nginx跟后端服务器连接超时时间(代理连接超时)
proxy_connect_timeout   90;

# 后端服务器数据回传时间(代理发送超时)
proxy_send_timeout      90;

# 连接成功后，后端服务器响应时间(代理接收超时)
proxy_read_timeout      90;

#proxy_buffers缓冲区，网页平均在32k以下的设置
proxy_buffers           32 4k;
```

#### fastcgi.conf
```
fastcgi_param  SCRIPT_FILENAME    $document_root$fastcgi_script_name;
fastcgi_param  QUERY_STRING       $query_string;
fastcgi_param  REQUEST_METHOD     $request_method;
fastcgi_param  CONTENT_TYPE       $content_type;
fastcgi_param  CONTENT_LENGTH     $content_length;
fastcgi_param  SCRIPT_NAME        $fastcgi_script_name;
fastcgi_param  REQUEST_URI        $request_uri;
fastcgi_param  DOCUMENT_URI       $document_uri;
fastcgi_param  DOCUMENT_ROOT      $document_root;
fastcgi_param  SERVER_PROTOCOL    $server_protocol;
fastcgi_param  GATEWAY_INTERFACE  CGI/1.1;
fastcgi_param  SERVER_SOFTWARE    nginx/$nginx_version;
fastcgi_param  REMOTE_ADDR        $remote_addr;
fastcgi_param  REMOTE_PORT        $remote_port;
fastcgi_param  SERVER_ADDR        $server_addr;
fastcgi_param  SERVER_PORT        $server_port;
fastcgi_param  SERVER_NAME        $server_name;

fastcgi_index  index.php;

fastcgi_param  REDIRECT_STATUS    200;
```

## 四、其他补充

### 1、查看Nginx状态
```
# 设定查看Nginx状态的地址
# 只能定义在location中
location /Status {
	stub_status on;
	# 允许所有ip
	allow all;
	#access_log off;
	#allow 192.168.1.0/24;
	#deny all;
	#auth_basic "Status";
	#auth_basic_user_file /etc/nginx/.htpasswd;
}
	
# status结果实例说明：
# Active connections: 1 (当前所有处于打开状态的连接数)
# server accepts handled requests
# 174(已经接受进来的连接) 174(已经处理过的连接) 492(处理的请求，在保持连接模式下，请求数可能会多于连接数量)
# Reading: 0 Writing: 1 Waiting: 0 
# Reading:正处于接受请求状态的连接数
# Writing:请求接受完成，正处于处理请求或发送相应的过程中的连接数
# Waiting:保持连接模式，且处于活动状态的连接数
```

### 2、防盗链
```
location ~* \.(jpg|gif|jpeg|png)$ {
	# 当一个请求头的Referer字段中包含一些非正确的字段，这个模块可以禁止这个请求访问站点,这个指令在referer头的基础上为 $invalid_referer 变量赋值，其值为0或1
	# 如果valid_referers列表中没有Referer头的值， $invalid_referer将被设置为1
	# 下面的意思是如果来路不是来自 lrshuai.top 域 将跳转403页面
	valid_referer none blocked www.lrshuai.top *.lrshuai.top;
	if ($invalid_referer) {
		rewrite ^/ http://www.lrshuai.top/403.html;
	}
}
```

### 3、rewrite 重定向，限制IE访问
```
 # 若是ie 浏览器，将重定向到ie.html
 if ($http_user_agent ~ MSIE) {
	rewrite ^.*$ /ie.htm;
	break; #(不break会循环重定向)
 }
```

### 4、限制ip访问
```
location /{
	# 网段192.168.1.0 这个网段全部不给访问
	deny 192.168.1.0/24;
	allow 192.168.12.0/24;
	
	# 可以重定向
	# rewrite ...
}
```

> 参考自：[https://www.nginx.com/resources/wiki/start/topics/examples/full/](https://www.nginx.com/resources/wiki/start/topics/examples/full/)

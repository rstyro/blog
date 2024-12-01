---
title: Nginx 搭建https
date: 2018-01-18 18:12:13
updated: 2018-01-18 18:12:13
tags: [Nginx]
categories: 开发工具
---
# nginx 搭建https

## 一、创建SSL证书
```
mkdir -p /etc/nginx/ssl
openssl req -x509 -nodes -days 36500 -newkey rsa:2048 -keyout /etc/nginx/ssl/nginx.key -out /etc/nginx/ssl/nginx.crt
```

<!--more-->

##### 创建了有效期100年，加密强度为RSA2048的SSL密钥key和X509证书文件。
||参数说明:|
|--|--|
|`req`| 配置参数-x509指定使用 X.509证书签名请求管理(certificate signing request (CSR))."X.509" 是一个公钥代表that SSL and TLS adheres to for its key and certificate management.|
|`-nodes`| 告诉OpenSSL生产证书时忽略密码环节.(因为我们需要Nginx自动读取这个文件，而不是以用户交互的形式)。|
|`-days 36500`| 证书有效期，100年|
|`-newkey rsa:2048`| 同时产生一个新证书和一个新的SSL key(加密强度为RSA 2048)
|`-keyout`|SSL输出文件名|
|`-out`|证书生成文件名|
> 它会问一些问题。需要注意的是在common name中填入网站域名，如wiki.xby1993.net即可生成该站点的证书，同时也可以使用泛域名如*.xby1993.net来生成所有二级域名可用的网站证书。
整个问题应该如下所示:

![](/upload/images/78490.png)

## 二、nginx配置 ssl
```
# 我下面这个配置是http 和https 都可以用的
# 如果只要https的话，把：listen:80 去掉
server {
	listen      80;
	listen 443 ssl;
	ssl_certificate /etc/nginx/ssl/nginx.crt;
	ssl_certificate_key /etc/nginx/ssl/nginx.key;
	keepalive_timeout   70;
	server_name 服务器ip;
	server_tokens off;
	fastcgi_param   HTTPS               on;
	fastcgi_param   HTTP_SCHEME         https;

	access_log      /var/log/nginx/rstyro.access.log;
	error_log       /var/log/nginx/rstyro.error.log;
}

```


```
附录1、证书格式说明
.crt：自签名的证书
.csr：证书的请求(用于向证书颁发机构申请crt证书时使用，nginx配置时不会用到)
.key：SSL Key (分为不带口令和带口令版本)。
我们自签名证书配置nginx需要的是.crt证书，和不带口令的SSL Key的.key文件。
```

```
附录2、可靠的第三方SSL证书颁发机构
目前一般市面上针对中小站长和企业的 SSL 证书颁发机构有：
StartSSL
Comodo / 子品牌 Positive SSL
GlobalSign / 子品牌 AlphaSSL
GeoTrust / 子品牌 RapidSSL
```

> 转载自：[https://segmentfault.com/a/1190000004976222](https://segmentfault.com/a/1190000004976222)

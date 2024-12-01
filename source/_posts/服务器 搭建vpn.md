---
title: 服务器 搭建vpn
date: 2017-08-24 15:14:20
updated: 2017-08-24 15:14:20
tags: [干货]
categories: 其他
---
# 在vps服务器 搭建vpn 
## 一、搭建shadowsocks
### (1).安装shadowsocks
##### CentOS 安装命令:
```
yum install python-setuptools && easy_install pip  
pip install shadowsocks
```

<!--more-->

##### Debian / Ubuntu 安装命令:
```
apt-get install python-pip  
pip install shadowsocks
```

### (2).编写配置
```
vi /etc/shadowsocks.json
```
##### 只有一个用户使用 则添加如下内容
```
{
"server":"my_server_ip",
"server_port":8388,
"local_address": "127.0.0.1",
"local_port":1080,
"password":"mypassword",
"timeout":300,
"method":"aes-256-cfb",
"fast_open": false
}
```
##### 多用户使用，则添加如下内容
```
{
"server":"0.0.0.0",
"port_password":{
 "8333":"mypassword",
 "8334":"mypassword",
 "8335":"mypassword",
 "8336":"mypassword"
 },
"timeout":300,
"local_port":"1080",
"local_address":"127.0.0.1",
"method":"aes-256-cfb",
"fast_open": false
}
```
> 上面的内容都是可以修改的，我只是给你们一个模板

#### 说明字段：
|名称|说明|
|--|---|
|server|您的服务器侦听的地址|
|server_port|服务器端口|
|local_address| 你本地的地址|
|LOCAL_PORT|本地监听端口|
|password|密码|
|timeout|超时时间几秒钟|
|method|默认值：“aes-256-cfb”，请参阅加密方式|
|fast_open|使用TCP_FASTOPEN，true / false|

### (3)、启动
```
#启动
ssserver -c /etc/shadowsocks.json -d start
#停止
ssserver -c /etc/shadowsocks.json -d stop

# 如需开机启动,打开/etc/rc.local 在最后添加 ssserver -c /etc/shadowsocks.json -d start
echo ssserver -c /etc/shadowsocks.json -d start >> /etc/rc.local
```
### (4)、完成
#### 如果上面没有报错，说明安装完成了，可以用Shadowrocket 进行连接，中文叫影梭

## 二、安装 L2TP/IPSec 一键包
> 第二层隧道协议L2TP（第二层隧道协议）是一种工业标准的互联网隧道协议，它使用UDP的1701端口进行通信.L2TP本身并没有任何加密，但是我们可以使用IPSec对L2TP包进行加密。

```
#下载一键安装脚本
wget --no-check-certificate https://raw.githubusercontent.com/teddysun/across/master/l2tp.sh
# 赋予执行权限
chmod +x l2tp.sh
# 执行
./l2tp.sh
```
#### 1、然后根据提示输入：
+ 主要改用户名和密钥和密码就行，不懂就回车
+ 默认的用户名：teddysun
+ 默认的密钥：teddysun.com
+ 默认的密码：这是一个随机函数生成的
+ 最后会有显示基本信息
![](1504152512957023251.png)

#### 2、操作命令
```
# 新增用户
l2tp -a

# 删除用户
l2tp -d

# 修改现有的用户的密码
l2tp -m

# 列出所有用户名和密码
l2tp -l

# 列出帮助信息
l2tp -h
```

## 三、客户端下载
### Windows   
+ https://github.com/shadowsocks/shadowsocks-windows/releases 

### Mac OS X   
+ https://github.com/shadowsocks/ShadowsocksX-NG/releases  


### linux   
+ https://github.com/shadowsocks/shadowsocks-qt5/wiki/Installation   
+ https://github.com/shadowsocks/shadowsocks-qt5/releases  



### Android   
+ https://play.google.com/store/apps/details?id=com.github.shadowsocks   
+ https://github.com/shadowsocks/shadowsocks-android/releases  

## 四、连接示例
### 我以windows 为栗子
#### 1、下载：https://github.com/shadowsocks/shadowsocks-windows/releases/download/4.0.5/Shadowsocks-4.0.5.zip
#### 2、解压
#### 3、运行 .exe 文件
#### 4、输入账号密码（刚才你安装 `shadowsocks` 的信息）
![](1504085086551096951.png)
#### 5、电脑右下角有个小飞机 右键启动系统代理，
##### (a)、PAC模式 开启 ，把想访问的地址 按照格式写入PAC 文件。
##### (b)、全局模式 开启（新手推荐）

> 参考自：
> http://blog.csdn.net/noahsun1024/article/details/52206369
> https://teddysun.com/448.html

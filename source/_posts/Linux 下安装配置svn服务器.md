---
title: Linux 下安装配置svn服务器
date: 2017-05-19 22:31:15
tags: [SVN, Linux]
categories: 网络运维
---
## 1、安装svn服务器（以cenos为例）
```
yum install subversion
```
## 2、创建svn版本仓库
```
cd /usr/local/              #进入目录，准备创建svn目录 
mkdir svnRepo                #创建一个svn目录
chmod -R 777 svnRepo            #修改目录权限为777 
svnadmin create /usr/local/svnRepo/test  #创建一个svn版本仓库test(test可以随便起名字) 
cd test/conf               #进入test版本仓库下的配置文件目录
```
## 3、修改这个目录下的三个配置文件
#### (1) svnserve.conf //配置版本库信息和用户文件和用户密码文件的路径、版本库路径
```
anon-access = none       #默认是只读
readauth-access = write      #认证后有写入权限
password-db = passwd     #帐号密码配置文件
authz-db = authz         #权限配置文件
realm = test            #改成自己的版本库 生效范围
```
#### (2) authz //文件,创建svn组和组用户的权限
```
[group]  
first = ddl,shl       #创建一个first的组，并制定两个用户ddl和shl 
[test:/]                  #指定版本库跟目录下的权限  
@first = rw           #first组用户权限为读写  
* = r                 #其他用户只读，不给则为空串
```
#### (3) passwd //创建或修改用户密码
```
[users] 
ddl = 123456    #用户名 = 密码
shl = 123456
```
## 3、然后设置自启动
```
vim /etc/rc.d/rc.local
```
#### 在最后添加如下信息：
```
#--listen-port 3690 是指定端口启动，默认是3690，--log-file 是SVN日志文件 ，当然两个参数都可以不指定
svnserve -d -r /usr/local/svnRepo --listen-port 3699  --log-file=/var/log/svnserver.log
```
### SVN版本库启动方式，现在svnRepo下面有 test、test2 两个版本库
```
# 1：单版本库起动 
svnserve -d -r /usr/local/svnRepo/test

# 2：多版本库起动 
svnserve -d -r /usr/local/svnRepo

# 区别在于起动svn时候的命令中的启动参数-r指定的目录。
```
### svn 基本命令
```
lsof -i :3690   #查看svn是否启动 
 
ps aux |grep 'svn'  #查找所有svn启动的进程 
 
kill -9 2505    #杀死2505这个查找到的svn进程 
 
svnserve -d -r /usr/local/svnRepo/first #启动svn(可以把这个放到/etc/local/rc.local文件中，实现开机自启动)
 
netstat -anp|grep svnserve  #查看一下SVN信息
```
## 4、客户端访问
#### 假设客户端使用tortoiseSVN
#### 打开资源库浏览器输入地址, svn://你的svn服务器ip:3690
#### 输入用户名uername 密码123456
#### 因为没有网资源库里放文件所以需要你用客户端右键【create forder】，然后【add forder】
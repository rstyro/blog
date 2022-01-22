---
title: 'nginx解决13-Permission-denied问题'
date: 2021-04-12 14:51:17
updated: 2021-04-12 14:51:17
tags: [Nginx]
categories: 开发工具
---
## 一、解决Nginx报`nginx: [emerg] bind() to 0.0.0.0:8006 failed (13: Permission denied)`
+ 报错信息：`nginx: [emerg] bind() to 0.0.0.0:XXXX failed (13: Permission denied)`其中XXXX就是端口号。
+ 更改nginx启动端口，报错，权限被拒绝

![](error.png)

### 解决方案
有两种方案
#### 方案1、修改selinux 级别
+ 修改selinux 为关闭（停用）
+ **编辑`/etc/selinux/config`文件，设置`SELINUX=disabled`。之后将系统重启一下**
```bash

# 如下命令查询selinux状态
#  	enforcing - 拒绝	SELinux security policy is enforced.
#   permissive - 执行	SELinux prints warnings instead of enforcing.
#   disabled - 停用		No SELinux policy is loaded.
getenforce

```


#### 方案二、更新受控端口
Linux的SELinux安全性控制除作用于文件系统外还作用于端口，这使得那些作为服务启动的进程只能在规定的几个端口上监听。为叙述方便我们称之为受控端口。

##### 1、查看HTTP 受控端口
```bash
# semanage port -l | grep http_port_t
http_port_t                    tcp      80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988

```

+ 默认http的开放端口有：80、81、443等8个
+ 由于nginx默认在80端口监听因此启动正常
+ 如上，我修改nginx启动端口为 8006 不在上面的范围内，所有报权限错误
+ 我们只需把我们想要启动的端口加到`http_port_t`即可，如下
```bash
# 添加8006端口
semanage port -a -t http_port_t  -p tcp 8006
```
+ 修改完，重启nginx即可

#### 2、安装使用semanage命令
+ semanage在CentOS上是默认不安装的
```
# 直接使用yum安装
yum install -y semanage

# 如果上面提示No package semanage available ,可以试试
yum provides semanage

# 上面都不行就只能放大招了，保证可以
yum -y install policycoreutils-python.x86_64
```

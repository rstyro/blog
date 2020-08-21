---
title: Centos安装GitLab
date: 2019-09-14 17:05:17
tags: [Linux, 开发工具]
categories: 网络运维
---
# 安装GitLab

官网有挺详细的安装步骤：
[官网地址: https://about.gitlab.com/install/#centos-7](https://about.gitlab.com/install/#centos-7)

## Centos7安装步骤

### 1、安装依赖
```
sudo yum install -y curl policycoreutils-python openssh-server
```

### 2、更新仓库包

[包路径: https://packages.gitlab.com/gitlab/gitlab-ce/](https://packages.gitlab.com/gitlab/gitlab-ce/)
> gitlab 分为gitlab-ce和gitlab-ee，我们要安装ce社区版,gitlab-ce是社区版，免费的、gitlab-ee是企业版，收费的

```
## 企业版、收费
# curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.rpm.sh | sudo bash

## 社区版、免费
curl -s https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.rpm.sh | sudo bash
```

### 3、安装邮件服务
注册发送邮件通知，如果您想使用其他解决方案发送电子邮件。
可跳过此步骤并在安装GitLab后配置外部SMTP服务器
如果关闭注册功能方法不需要发邮件的话这步可以跳过

```
# 安装
sudo yum install postfix
# 开机自启动
sudo systemctl enable postfix
# 启动服务
sudo systemctl start postfix
```

### 4、开始安装
这个安装有点慢，看网速内存与cpu。我1核2G低配版，等了好久。
```
sudo EXTERNAL_URL="http://你的ip地址" yum install -y gitlab-ce

```

> 可以修改配置：
> `vim /etc/gitlab/gitlab.rb`
> 自己看吧，注释里面有说明

#### 如果出现卡死-解决方案：
```
1、按住CTRL+C强制结束
2、运行：sudo systemctl restart gitlab-runsvdir
3、再次执行：sudo gitlab-ctl reconfigure
```
![git2.png](git2.png)

#### 安装成功，访问：http://你的ip地址


### 5、GitLab常用命令
```
sudo gitlab-ctl start               		# 启动 gitlab 组件
sudo gitlab-ctl stop                		# 停止 gitlab 组件
sudo gitlab-ctl restart             		# 重启 gitlab 组件
sudo gitlab-ctl status              		# 查看服务状态；
sudo gitlab-ctl reconfigure         		# 修改后直接编译启动
sudo gitlab-ctl tail                        # 查看日志；

```

### 6、完全卸载GitLab
```
# 停止gitlab
sudo gitlab-ctl stop

#卸载gitlab
sudo rpm -e gitlab-ce

#查看gitlab进程，杀掉进程
ps -ef|grep gitlab


# 删除gitlab文件
find / -name *gitlab*|xargs rm -rf     
 
# 删除所有包含gitlab的文件及目录
find / -name gitlab |xargs rm -rf 


```
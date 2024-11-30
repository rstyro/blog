---
title: Jenkins安装配置使用
date: 2019-05-06 16:20:12
updated: 2019-05-06 16:20:12
tags: [Jenkins]
categories: 网络运维
---
# Jenkins安装及使用
+ Jenkins是基于Java开发的一种持续集成工具，用于监控持续重复的工作，功能包括：
+ 1、持续的软件版本发布/测试项目。
+ 2、监控外部调用执行的工作

## 一、环境
+ 1、安装JDK  
不会的看这个：[Linux 安装jdk](https://rstyro.github.io/blog/2017/05/13/Linux%20%E5%AE%89%E8%A3%85jdk/)
+ 2、安装tomcat(非必须)  
不会看这个：[Centos7 安装tomcat](https://rstyro.github.io/blog/2017/05/10/Centos7%20%E5%AE%89%E8%A3%85tomcat%EF%BC%8C%E5%B9%B6%E6%B7%BB%E5%8A%A0%E6%9C%8D%E5%8A%A1/)
+ 3、安装Git  
不会看这个：[Linux安装Git](https://rstyro.github.io/blog/2019/05/05/Linux%E5%AE%89%E8%A3%85%E6%9C%80%E6%96%B0%E7%89%88Git/)
+ 4、安装Maven  
不会看这个：[linux 安装Maven](https://rstyro.github.io/blog/2017/08/22/%E5%AE%89%E8%A3%85maven/)



## 二、下载安装
+ 1、去官网：[https://jenkins.io/download/](https://jenkins.io/download/) 下载 `.war` 包文件。  
+ 2、`wget `http://mirrors.jenkins.io/war-stable/latest/jenkins.war
+ 3、把jenkins.war包放在tomcat下面的webapps目录下面
+ 4、启动tomcat会自动解压war包，生成一个jenkins文件夹，而且会在root目录下生成一个.jenkins的文件夹
+ 5、浏览器访问 `http://ip:端口/jenkins` 
+ 6、输入初始化密码，位置在上面提示的路径(`$user.home/.jenkins/secrets/initialAdminPassword`),比如你是root用户:`/root/.jenkins/secrets/initialAdminPassword`
+ 7、选择插件安装界面，选择第一个，安装社区推荐的即可
+ 8、之后创建一个用户
+ 9、创建用户之后，就可以使用jenkins了

![](jenkins1.png)
![](jenkins3.png)
![](jenkins4.png)

> 除了放在servlet 容器，也可以通过`java -jar jenkins.war &` 的方式启动。
> 如果插件安装失败的话，可以去镜像地址：[https://mirrors.tuna.tsinghua.edu.cn/jenkins/](https://mirrors.tuna.tsinghua.edu.cn/jenkins/)   
> 手动下载然后通过插件管理中的高级选择进行上传

![](jenkins5.png)

## 三、全局工具配置
在Jenkins 中的全局工具配置中，配置  
+ JDK
+ Git
+ Maven  
配置上面几个工具的路径
![](jenkins8.png)

## 四、Github 配置
在Jenkins 访问Github 项目的时候，有时需要授权，为了保险 所以我们在Github上给Jenkins 生成一个令牌（`Personal access tokens`）。
#### 1、生成 Personal access tokens  
+ 在Github个人设置里面（`Settings`）
+ 点击`Developer settings`
+ 进去之后，点击`Personal access tokens`
+ 之后点击`Generate new token`按钮
+ 选择`repo` 和 `admin:repo_hook`选项
+ 最后点击下方`Generate token` 绿色按钮生成token
+ 生成一个token字符串，记录下来，后面不显示的

![](jenkins9.png)
![](jenkins9-1.png)
![](jenkins9-2.png)


#### 2、生成凭据
+ 在Jenkins管理界面中，点击`凭据`
+ 点击全局凭据
+ 添加凭据
+ 然后类型选择`Secret text`,Secret 选项就是在Github生成的token,描述那里随便写，然后添加

![](jenkins-credentials.png)

#### 3、配置Jenkins 的Github Server
进入Jenkins 的系统设置
+ 在Github 服务器那，添加Github服务器
+ 凭据选择刚才上一步的凭据
+ 点击右边`连接测试`
+ 没问题，保存

![](jenkins10-1.png)


## 五、构建任务
准备工作都准备好了，开始构建吧。 
 
![](jenkins-build.png)

### 1、手动构建
这个的意思就是，当你推送代码了，但是Jenkins不会帮你立即部署，需要你主动去点一下构建  
> 当多人开发的时候，没人都推送了才去手动构建也是一个好的方式。缺点：不够自动呗，别急后面有自动

+ 1、新建任务，名称为`test2`
+ 2、选择、`构建一个自由风格的软件项目`  
这个比较灵活，自由配置
+ 3、选择Github项目  
项目URL,填你自己的，比如我：`https://github.com/rstyro/SpringBoot-test.git/`
+ 4、源码管理选择`Git`  
仓库选择源代码 仓库地址，比如我：`https://github.com/rstyro/SpringBoot-test.git`,如果你是私人仓库即可添加凭证
+ 5、`构建触发器`和`构建环境`全部为空  
因为是手动构建这两个不需要配置
+ 6、构建那里选择,`添加构建步骤` 然后`选择Maven` 与 `执行Shell`  
maven 目标选择
+ 7、最后就可以保存了

![](jenkins-build2.png)
![](jenkins-build3.png)
![](jenkins-build-p0.png)
> `Started by rstyro` 这个是通过用户触发的

![](jenkins-build-p1.png)

#### `test_run.sh` 内容如下
```shell
#!/bin/bash
BUILD_ID=DONTKILLME
# jenkins 构建之后的jar 根路径
JAR_PATH="/root/.jenkins/workspace/test2"

# 项目 打包之后的路径
PROJ_PATH="/data/jar"

# 打包后的名称
JAR_NAME="springboot-test"

# 文件的后缀
FILE_TYPE="jar"

# 备份的文件夹名称
BACKUP="backup"

### base函数
kill()
{
    pid=`ps -ef | grep $JAR_NAME.$FILE_TYPE |grep -v color |grep -v grep | awk '{print $2}'`
    echo "$JAR_NAME pid is ${pid}"
    if [ "$pid" = "" ]
    then
        echo "no $JAR_NAME pid alive"
    else
                echo "killing start"
        sudo kill -9 $pid
        echo "killing end"
    fi
}

#停止之前的进程
echo "killing before"
kill
echo "killing after"

#创建备份目录
cd $PROJ_PATH

if [ ! -d "$BACKUP" ];then
      sudo mkdir -p $BACKUP
      cd $BACKUP
      sudo mkdir log
fi
echo $PROJ_PATH
cd $PROJ_PATH
#创建运行目录
if [ ! -d run ];then
      sudo mkdir -p run
fi

#备份之前的版本
cd $PROJ_PATH/run
if [ -f "$JAR_NAME.$FILE_TYPE" ];then
    sudo mv $JAR_NAME.$FILE_TYPE $PROJ_PATH/$BACKUP/$JAR_NAME$(date "+%Y%m%d%H%M%S").$FILE_TYPE
fi
if [ -f "print.out" ];then
    sudo mv print.out $PROJ_PATH/$BACKUP/log/print$(date "+%Y%m%d%H%M%S").out
fi

#将打包好的文件移动到run上
cd $JAR_PATH

if [ -d target ];then
      cd target
      sudo mv $JAR_NAME.$FILE_TYPE $PROJ_PATH/run/$JAR_NAME.$FILE_TYPE
      cd ../
fi

#启动服务
cd $PROJ_PATH/run

nohup java -jar $JAR_NAME.$FILE_TYPE >print.out 2>&1 &
```

### 2、自动构建
+ 利用到 Github的`Webhooks` 
+ 在Github项目的`Settings` 配置`Webhooks`
+ 点击`Add webhook` 在`Playload URL` 填写Jenkins 的webhook 地址
+ 下面如何触发webhook ，直接选择第一个选项推送（`Just the push event`）即可
+ 点击下面`Add webhook`按钮进行添加
+ 然后在Jenkins构建任务的时候与上面的步骤差不多
+ 就是第5步，那里选择 `构建触发器`选择`GitHub hook trigger for GITScm polling` 这个选择即可  
+ 然后当我们推送项目的时候，Github就会通知 Jenkins 进行构建


![](jenkins-webhooks.png)
![](jenkins-build-auto.png)

![](jenkins-build-p2.png)

> `Started by GitHub push by rstyro` 这个打印说明通过Github 推送触发的，说明Webhooks 配置成功。搞定    


## 六、用户权限管理

### 1、配置步骤
+ 1、安装插件`Role-based Authorization Strategy`
+ 2、进入全局安全配置
+ 3、当插件安装好的时候，授权策略会多出一个`Role-Based Strategy`选项
+ 4、选择该项并保存

![](jenkins-auth.png)

### 2、管理分配角色
+ 1、系统管理中有一个 `Manage and Assign Roles` 的选项
+ 2、选择`Manage Roles` 管理角色
+ 3、可以创建3种角色：`Global role` 、`Project roles` 、`Slave roles`   
全局角色可以对jenkins系统进行设置与项目的操作  
项目角色只能对项目进行操作  
节点角色只能对节点进行操作
+ 4、可以按照你的需求配置角色
+ 5、然后再次进入`Manage and Assign Roles` 的选项
+ 6、选择`Assign Roles` 分配角色
+ 7、在 `User/group to add` 后面指定一个用户，点击`Add`
+ 8、之后给这个用户选择一个角色即可

![](jenkins-auth-role.png)
![](jenkins-auth-role-manage.png)
![](jenkins-auth-role2.png)
![](jenkins-auth-role3.png)

### 3、角色选项说明
+ Overall(全部)	
	+ Administer  
		管理员
	+ Read  
		只读权限
+ Credentials(凭证)  
	+ Create  创建	
	+ Delete 删除
	+ ManageDomains  管理娱
	+ Update  更新
	+ View  查看		
+ Slave(代理）  
	+ Build	构建
	+ Configure	配置
	+ Connect	连接
	+ Create	创建
	+ Delete	删除
	+ Disconnect	断开连接
	+ Provision
+ Job(任务)  
	+ Build  构建
	+ Cancel 取消构建
	+ Configure	配置
	+ Create	创建
	+ Delete	删除
	+ Discover	重定向
	+ Move	移动
	+ Read	只读
	+ Workspace	查看工作区
+ Run(运行)  
	+ Delete  删除
	+ Replay	重启
	+ Update  更新
+ View(视图)  
	+ Configure	配置
	+ Create	创建
	+ Delete	删除
	+ Read		查看
+ SCM Lockable  Resources
	SCM配置
	+ Tag	tag构建
	+ Reserve	
	+ Unlock  
	

## 七、常用插件
+ jenkins基础上是离不开插件的

### 1、权限插件
+ 插件名：`Role-based Authorization Strategy`
+ 上面有介绍

### 2、构建发布到其他服务器运行
+ 插件名：`Publish over SSH`
+ 如果需要把构建好的包，打包到其他的服务器
+ 需要安装 `Publish over SSH` 插件，节点也可以，但是节点服务器都需要配置jenkins环境，如jdk、maven等

![](pos.png)

+ 配置 `Publish over SSH` ,`Manage Jenkins` --> `Configure System` --> `Publish over SSH` 进行远程服务器配置即可
+ 具体如下图：

![](ssh.png)

![](ssh-build.png)

![](ssh-config.png)


### 3、MultiJob多任务构建
+ 插件名：`MultiJob plugin`
+ 有时需要重启所有服务，如果一个一个服务的去点，这样效率比较低
+ 所以我们可以构建一个任务，让Jenkins 自动去构建所有任务。

**步骤**
+ 需要安装：`MultiJob plugin` 插件

![](multijob.png)

+ 然后 新建Item 创建一个 `MultiJob Project` 即可。

![](multijob-project.png)

+ 在构建那里，添加一个 `MultiJob Phase` ，在其下面添加 Job 即可。

![](multijob-phase.png)

### 4、NodeJS构建vue项目
+ 插件名：`Nodejs plugin`
+ 安装插件Nodejs-plugin 
+ 配置NodeJs: 系统管理 -> 全局工具配置 -> NodeJS 
+ 之后就可以构建vue项目了

![](plugin.png)

**配置NodeJS**
安装nodejs的步骤省略...

![](nodejs-path.png)

**构建任务**
+ 前面拉代码等略过...

![](nodejs-config.png)

+ shell配置

```
# node -v
# npm -v

# 第一次构建可以加这行，后面可以注释上
npm install

npm run build:test

# 换成你的项目名
HOME=/var/lib/jenkins/jobs/youprojectName/workspace
RUN_PATH=/usr/share/nginx/html

if [ -d dist ]
then
	rm -rf $RUN_PATH/*
    mv -f $HOME/dist/* $RUN_PATH/
fi

echo "dist包 构建结束"
```

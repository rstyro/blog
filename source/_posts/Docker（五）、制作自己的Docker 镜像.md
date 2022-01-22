---
title: Docker（五）、制作自己的Docker 镜像
date: 2018-01-18 16:10:37
updated: 2018-01-18 16:10:37
tags: [Docker]
categories: 开发工具
---
# 制作自己的Docker 镜像
#### Docker 可以通过 Dockerfile 的内容来自动构建镜像。Dockerfile 是一个包含创建镜像所有命令的文本文件，通过docker build命令可以根据 Dockerfile 的内容构建镜像

## 目标：在 tomcat中 运行一个.war 文件

## 一、创建一个Dockerfile 文件
```
# 先创建一个文件夹为docker-admin
mkdir docker-admin

# 进入文件夹docker-admin 并创建一个Dockerfile
cd docker-admin && vim Dockerfile

```

## 二、编辑Dockerfile 文件
编辑如下内容,下面中的`COPY admin.war` 的admin.war 就是我们的war文件
Dockerfile 的一些基本语法结构 后面再介绍
```
FROM docker.io/tomcat
MAINTAINER rstyro
COPY admin.war /usr/local/tomcat/webapps
```

## 三、获取到.war 文件
你可以用你自己的，或者用我的
````
# github 下载地址为：
wget https://github.com/rstyro/admin/raw/pack/pack/admin-0.0.1-SNAPSHOT.war

# 修改名字
mv admin-0.0.1-SNAPSHOT.war admin.war

```

## 四、构建镜像

```
# -t 参数 后面跟镜像名字和tag  注意别忘了后面的 . 点表示当前路径
docker build -t admin:1.0.0 .
```

## 五、运行我们刚构建的镜像
```
# 给它取名 admin 本机端口映射 8080
docker run --name=admin -p 8080:8080 -d admin:1.0.0
```
#### 下面是我敲命令的过程
![](71806.png)
![](65971.png)

## 六、Dockerfile 指令详解
+ FROM
+ MAINTAINER
+ RUN
+ CMD
+ EXPOSE
+ ENV
+ ADD
+ COPY
+ ENTRYPOINT
+ VOLUME
+ USER
+ WORKDIR
+ ONBUILD

### 1、FROM
用法:
```
FROM <image>
```
+ FROM指定构建镜像的基础源镜像，如果本地没有指定的镜像，则会自动从 Docker 的公共库 pull 镜像下来。
+ FROM必须是 Dockerfile 中非注释行的第一个指令，即一个 Dockerfile 从FROM语句开始。
+ FROM可以在一个 Dockerfile 中出现多次，如果有需求在一个 Dockerfile 中创建多个镜像。
+ 如果FROM语句没有指定镜像标签，则默认使用latest标签。

### 2、MAINTAINER
用法:
```
MAINTAINER <name>
```
指定创建镜像的用户

### 3、RUN 
RUN 有两种使用方式
```
RUN "executable", "param1", "param2"
```
+ 每条RUN指令将在当前镜像基础上执行指定命令，并提交为新的镜像，后续的RUN都在之前RUN提交后的镜像为基础，镜像是分层的，可以通过一个镜像的任何一个历史提交点来创建，类似源码的版本控制。
+ exec 方式会被解析为一个 JSON 数组，所以必须使用双引号而不是单引号。exec 方式不会调用一个命令 shell，所以也就不会继承相应的变量，如：
```
RUN [ "echo", "$HOME" ]
```
这种方式是不会达到输出 HOME 变量的，正确的方式应该是这样的
```
RUN [ "sh", "-c", "echo", "$HOME" ]
```
RUN产生的缓存在下一次构建的时候是不会失效的，会被重用，可以使用--no-cache选项，即docker build --no-cache，如此便不会缓存。
 
### 4、CMD
CMD有三种使用方式:
```
CMD "executable","param1","param2"
CMD "param1","param2"
CMD command param1 param2 (shell form)
```
+ CMD指定在 Dockerfile 中只能使用一次，如果有多个，则只有最后一个会生效。
+ CMD的目的是为了在启动容器时提供一个默认的命令执行选项。如果用户启动容器时指定了运行的命令，则会覆盖掉CMD指定的命令。

> CMD会在启动容器的时候执行，build 时不执行，而RUN只是在构建镜像的时候执行，后续镜像构建完成之后，启动容器就与RUN无关了

### 5、EXPOSE
格式：
```
EXPOSE <port> [<port>...]
```
告诉 Docker 服务端容器对外映射的本地端口，需要在 docker run 的时候使用-p或者-P选项生效。

### 6、ENV
```
ENV <key> <value>       # 只能设置一个变量
ENV <key>=<value> ...   # 允许一次设置多个变量
```
指定一个环境变量，会被后续RUN指令使用，并在容器运行时保留。

例子:
```
ENV myName="John Doe" myDog=Rex\ The\ Dog \
    myCat=fluffy
```
等同于
```
ENV myName John Doe
ENV myDog Rex The Dog
ENV myCat fluffy
```
### 7、ADD
```
ADD <src>... <dest>
```
ADD复制本地主机文件、目录或者远程文件 URLS 从 并且添加到容器指定路径中 。

支持通过 GO 的正则模糊匹配，具体规则可参见 Go filepath.Match

```
ADD hom* /mydir/        # adds all files starting with "hom"
ADD hom?.txt /mydir/    # ? is replaced with any single character
```
+ 路径必须是绝对路径，如果 不存在，会自动创建对应目录
+ 路径必须是 Dockerfile 所在路径的相对路径
+ 如果是一个目录，只会复制目录下的内容，而目录本身则不会被复制

### 8、COPY
```
COPY <src>... <dest>
```
+ COPY复制新文件或者目录从 并且添加到容器指定路径中 。用法同ADD，唯一的不同是不能指定远程文件 URLS。

### 9、ENTRYPOINT
```
ENTRYPOINT "executable", "param1", "param2"
ENTRYPOINT command param1 param2 (shell form)
```
配置容器启动后执行的命令，并且不可被 docker run 提供的参数覆盖，而CMD是可以被覆盖的。如果需要覆盖，则可以使用`docker run --entrypoint`选项。
每个 Dockerfile 中只能有一个ENTRYPOINT，当指定多个时，只有最后一个生效。

##### Exec form ENTRYPOINT 例子
+ 通过ENTRYPOINT使用 exec form 方式设置稳定的默认命令和选项，而使用CMD添加默认之外经常被改动的选项。
```
FROM ubuntu
ENTRYPOINT ["top", "-b"]
CMD ["-c"]
```
+ 通过 Dockerfile 使用ENTRYPOINT展示前台运行 Apache 服务
```
FROM debian:stable
RUN apt-get update && apt-get install -y --force-yes apache2
EXPOSE 80 443
VOLUME ["/var/www", "/var/log/apache2", "/etc/apache2"]
ENTRYPOINT ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
```
##### Shell form ENTRYPOINT 例子
+ 这种方式会在/bin/sh -c中执行，会忽略任何CMD或者docker run命令行选项，为了确保docker stop能够停止长时间运行ENTRYPOINT的容器，确保执行的时候使用exec选项。
```
FROM ubuntu
ENTRYPOINT exec top -b
```
如果在ENTRYPOINT忘记使用exec选项，则可以使用CMD补上:
```
FROM ubuntu
ENTRYPOINT top -b
CMD --ignored-param1 # --ignored-param2 ... --ignored-param3 ... 依此类推
```

### 10、VOLUME
```
VOLUME ["/data"]
```
将本地主机目录挂载到目标容器中
或者将其他容器挂载的挂载点 挂载到目标容器中
### 11、USER
```
USER daemon
```
指定运行容器时的用户名或 UID，后续的RUN、CMD、ENTRYPOINT也会使用指定用户。

### 11、WORKDIR
```
WORKDIR /path/to/workdir
```
为后续的RUN、CMD、ENTRYPOINT指令配置工作目录。可以使用多个WORKDIR指令，后续命令如果参数是相对路径，则会基于之前命令指定的路径。
```
WORKDIR /a
WORKDIR b
WORKDIR c
RUN pwd
```
最终路径是/a/b/c。

WORKDIR指令可以在ENV设置变量之后调用环境变量:
```
ENV DIRPATH /path
WORKDIR $DIRPATH/$DIRNAME
```
最终路径则为 /path/$DIRNAME。

### 12、ONBUILD
```
ONBUILD [INSTRUCTION]
```
使用该dockerfile生成的镜像A，并不执行ONBUILD中命令
如再来个dockerfile 基础镜像为镜像A时，生成的镜像B时就会执行ONBUILD中的命令

### 参考链接：[http://www.open-open.com/lib/view/open1423703640748.html](http://www.open-open.com/lib/view/open1423703640748.html)


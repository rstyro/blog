---
title: Docker（四）、运行Nginx
date: 2018-01-13 15:53:00
updated: 2018-01-13 15:53:00
tags: [Docker]
categories: 开发工具
---
# Docker 运行nginx
运行了hello world 还不是我们的目标，这章我们要来学习运行一个静态的页面
## 一、获取Nginx
##### 获取镜像
```
docker pull nginx

```
## 二、启动镜像
#### 方法一：指定端口映射
##### 本机80端口 映射 容器的80端口,-d 是后台运行的意思，
```
# --name 是给它指定一个名字，我们这里给它指定的名字叫mynginx(不指定时docker会随机给它起一个名字)
docker run -d --name mynginx -p 80:80 nginx
```

#### 方法二：随机端口映射
##### 本机随机指定一个端口映射容器的nginx 启动端口,-d 是后台运行的意思
```
docker run -d --name mynginx -P 80:80 nginx
```

## 三、浏览器访问
#### nginx 默认启动的端口为 80 
#### 通过命令`docker ps` 或者 `docker ps | grep nginx`，查看端口的映射情况
#### 浏览器访问：http://localhost/ 或者 curl http://localhost/
![](13248.png)

## 四、修改index.html 页面

### 方法一：进入容器内部修改index.html 页面
##### 这就需要我们学新的一个命令`docker exec `了。格式如下：
```
# 参数-i是与用户交互式 -t 可以理解为一个伪终端，具体的可以通过 docker exec --help 命令来查看exec 的参数详解
docker exec -it mynginx bash
```
运行上面的命令之后我们就进到了运行nginx 容器里了，我们要修改的index页面的路径为`/usr/share/nginx/html/index.html`
当我们想使用vim 对它进行修改的时候，发现没有vim 这个命令。所以我们需要安装vim,运行如下命令（测试可以这么干）
```
# 更新源，然后安装vim,然后就可以编辑了。
apt-get update && apt-get install -y vim
```
接下来就可以修改了，想退出容器只需要运行`exit` 命令即可

### 方法二：映射页面目录（推荐）
##### 1、首先我们新建一个目录，并进入该目录，建立一个html的子目录
```
# -p 是递归创建
mkdir -p docker-nginx/html
cd docker-nginx
```

##### 2、在html目录下创建一个index.html页面
```html
vim html/index.html

# 编辑内容如下：
<!DOCTYPE html>
<html>
<head>
	<meta charset="utf-8">
	<meta http-equiv="X-UA-Compatible" content="IE=edge">
	<title>Hello Docker</title>
</head>
<body>
	<h1>Hello Docker!!!</h1>
</body>
</html>
```

##### 3、运行容器
在运行容器之前我们要把刚刚运行的容器停止掉，以为我们需要用80来启动它（如果你不要80端口，可以不用停止它）
```
# 停止刚才运行的容器，mynginx 就是我们刚才命名的
docker stop mynginx

# 这里是把这个容器删除掉，也可以不删掉，但是下面我下面又使用了mynginx,
docker rm mynginx

# 启动本地映射html 页面的容器
docker run -d -p 80:80 --name mynginx -v "$PWD/html":/usr/share/nginx/html docker.io/nginx
```
打开浏览器，访问 [http://localhost/](http://localhost/)，应该就能看到 Hello Docker!!! 了
我们可以在我们的主机上修改 index.html 的内容，然后刷新浏览器，看是否浏览器也更新了。
![](47063.png)

## 五、挂载配置文件
#### 1、拷贝nginx容器的配置文件
```
# 别忘了后面有一个 `.`  这个点表示当前目录
docker cp mynginx:/etc/nginx .
```
#### 2、改名
执行完成后，当前目录应该多出一个nginx子目录。然后，把这个子目录改名为conf
```
mv nginx conf
```

#### 3、停止我们刚才运行的容器
```
docker stop mynginx
```

#### 4、重新启动
我们的容器名字这里得改一下 mynginx 刚才我们已经用了
```
docker run -d --name mynginx2 -v "$PWD/html":/usr/share/nginx/html -v "$PWD/conf":/etc/nginx -p 80:80 docker.io/nginx
```
#### 5、修改配置
只需要修改 `conf/conf.d/default.conf`文件即可



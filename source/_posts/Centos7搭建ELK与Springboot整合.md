---
title: Centos7搭建ELK与Springboot整合
date: 2021-04-28 11:42:59
updated: 2021-04-28 11:42:59
tags:
categories:
---
### 前言
+ ElasticSearch和Logstash都是需要Java 环境的
+ 所以需要预先安装好Jdk(或者使用他们的包自带的jdk)
+ 安装JDK:[Lilnux安装JDK](https://rstyro.gitee.io/blog/2017/05/13/Linux%20%E5%AE%89%E8%A3%85jdk/)

### 一、安装Elasticsearch
+ 可以看我几百年前的文章：[ElasticSearch 的安装](https://rstyro.gitee.io/blog/2017/11/30/ElasticSearch%20%E7%9A%84%E5%AE%89%E8%A3%85/)
+ 可能报错的解决：[ES安装问题集锦](https://rstyro.gitee.io/blog/2017/11/30/Elasticsearch5.0+%20%E5%AE%89%E8%A3%85%E9%97%AE%E9%A2%98%E9%9B%86%E9%94%A6/)
+ 或者现在最新的安装方法：
```
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.12.0-linux-x86_64.tar.gz
tar -zxvf elasticsearch-7.12.0-linux-x86_64.tar.gz -C /usr/local/
mv elasticsearch-7.12.0 elasticsearch
cd elasticsearch
```


#### 1、修改Elasticsearch配置
+ 修改：`/usr/local/elasticsearch/config/elasticsearch.yml`
```
cluster.name: "mySearch"
node.name: "myNode1"
cluster.initial_master_nodes: ["myNode1"]
# 跨域问题
http.cors.enabled: true
http.cors.allow-origin: "*"
#http.cors.allow-headers: Authorization

network.host: 0.0.0.0
http.port: 9200
transport.tcp.port: 9300
```

#### 2、给Elasticsearch创建一个启动用户
+ 因为ES不能使用root用户启动
+ 所以新建一个elastic用户来启动
```
# 创建用户 elastic,属于root组,elasticsearch不用使用root启动
useradd -d /home/elastic -m -g root elastic

# 为elastic用户设置密码
passwd elastic

# 重新赋予文件夹权限
chown -R elastic:root elasticsearch
```

#### 3、修改系统的一些限制配置
+ vi `/etc/sysctl.conf`
```
# 限制一个进程可以拥有的VMA(虚拟内存区域)的数量
vm.max_map_count=655360
```
+ 然后执行：`sysctl -p`看看效果
+ vi `/etc/security/limits.conf`
```
* soft nofile 65536
* hard nofile 65536
* soft nproc 2048
* hard nproc 4096
```
+ 修改完，重启系统



### 二、安装kibana

#### 1、下载kibana
+ 下载地址：[https://www.elastic.co/cn/downloads/kibana](https://www.elastic.co/cn/downloads/kibana)
+ 下载成功后，解压即可
```
wget https://artifacts.elastic.co/downloads/kibana/kibana-7.12.0-linux-x86_64.tar.gz
tar -zxvf kibana-7.12.0-linux-x86_64.tar.gz -C /usr/local/
cd /usr/local/
mv kibana-7.12.0-linux-x86_64 kibana
cd kibana
```

#### 2、配置kibana
+ 进入kibana目录修改config下的`kibana.yml`配置文件
```
server.port: 5601
server.host: "0.0.0.0"
i18n.locale: "zh-CN"
#elasticsearch.hosts: ["http://localhost:9200"]
#elasticsearch.username: "kibana_system"
#elasticsearch.password: "pass"
```

#### 3、启动kibana
+ kibana 默认前台启动
```bash
# 启动 kibana
/usr/local/kibana/bin/kibana

# 后台启动
mkdir /usr/local/kibana/logs
nohup /usr/local/kibana/bin/kibana  --allow-root >/usr/local/kibana/logs/kibana.log 2>&1 &
nohup /usr/local/kibana/bin/kibana >/usr/local/kibana/logs/kibana.log 2>&1 &
```

### 三、安装Logstash

#### 1、下载 Logstash
+ 下载地址： [https://www.elastic.co/cn/downloads/logstash](https://www.elastic.co/cn/downloads/logstash)
+ 下载成功后，解压即可
```
wget https://artifacts.elastic.co/downloads/logstash/logstash-7.12.0-linux-x86_64.tar.gz
tar -zxvf logstash-7.12.0-linux-x86_64.tar.gz -C /usr/local/
cd /usr/local/
mv logstash-7.12.0 logstash
```
#### 2、安装插件
+ 安装一下常用插件
```
# 过滤插件
/bin/logstash-plugin install logstash-filter-multiline
# 安装json解析插件
/bin/logstash-plugin install logstash-codec-json_lines
```

#### 3、和springboot整合

##### 配置logstash
+ 新建logstash 配置文件：logstash-spring.conf

```
input {
    tcp {
        port => 4567
        codec => json_lines
    }
}
output{
  elasticsearch { 
     hosts => ["localhost:9200"] # 改成你elasticsearch的地址
     index => "%{[spring-app-name]}-%{+YYYY.MM.dd}" #用一个项目名称来做索引，注意一点：springappname 这个我用大写，会报错，所以记得小写
  }
  stdout { codec => rubydebug }
}
```

+ `4567` 是`logstash`接收数据的端口
+ `codec => json_lines`是一个json解析器，接收json的数据。这个要装 `logstash-codec-json_lines` 插件
+ ouput elasticsearch指向我们安装的地址
+ stdout会打印收到的消息，调试用
+ 然后启动
```
# 启动logstash
/usr/local/logstash/bin/logstash -f config/logstash-spring.conf
/usr/local/logstash/bin/logstash -f /usr/local/logstash/conf.d/logstash-spring.conf
```

##### 配置springboot
+ 新建一个Springboot项目
+ 导入 logstash pom依赖
```
<dependency>
	<groupId>net.logstash.logback</groupId>
	<artifactId>logstash-logback-encoder</artifactId>
	<version>6.6</version>
</dependency>
```
+ springboot新建一个`logback-spring.xml`的日志配置文件
```
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE configuration>
<configuration>
  <appender name="LOGSTASH" class="net.logstash.logback.appender.LogstashTcpSocketAppender">
    <destination>localhost:4567</destination>
    <encoder charset="UTF-8" class="net.logstash.logback.encoder.LogstashEncoder" />
  </appender>

  <include resource="org/springframework/boot/logging/logback/base.xml"/>

  <root level="INFO">
    <appender-ref ref="LOGSTASH" />
    <appender-ref ref="CONSOLE" />
  </root>

</configuration>
```
+ 随便在Springboot启动类加点日志
```
@SpringBootApplication
public class SpringbootElkApplication implements CommandLineRunner {

    public static void main(String[] args) {
        SpringApplication.run(SpringbootElkApplication.class, args);
    }

    @Override
    public void run(String... args) throws Exception {
        Logger logger = LoggerFactory.getLogger(SpringbootElkApplication.class);
        logger.info("Hallo Logstash");

        for (int i = 0; i < 10; i++) {
            logger.error("这是报错信息，参数={}，结果={};", i, i);
        }
    }

}
```
+ 在`kibana` -> `Stack Managemen` -> `索引模式` -> `创建索引模式`，我们就用 `spring-app*` 吧。创建好了，点击discover。就可以看到我们的日志了


![](add.png)

![](kibana.png)

**代码地址：**
+ Github: [https://github.com/rstyro/Springboot/tree/master/springboot-elk](https://github.com/rstyro/Springboot/tree/master/springboot-elk)
+ Gitee: [https://gitee.com/rstyro/spring-boot/tree/master/springboot-elk](https://gitee.com/rstyro/spring-boot/tree/master/springboot-elk)

### 四、Nginx配置账号密码访问


**因为kibana 没有账号密码，所以可以用nginx做转发，然后nginx配置账号密码**
```bash
# 有些系统本身就安装了的，就不需要再安装，反正敲这个命令也不报错
yum -y install httpd-tools

# 创建rstyro用户，输入两次密码
htpasswd -c /etc/nginx/password rstyro

# -D 删除指定的用户
htpasswd -D /etc/nginx/password rstyro

# -b htpassswd命令行中一并输入用户名和密码而不是根据提示输入密码
htpasswd -b /etc/nginx/password rstyro password

# -p htpassswd命令不对密码进行进行加密，即明文密码
htpasswd -cp /etc/nginx/password rstyro


# 帮助文档：
# [root@root2 local]# htpasswd -h
# htpasswd: illegal option -- h
# Usage:
# 	htpasswd [-cimB25dpsDv] [-C cost] [-r rounds] passwordfile username
# 	htpasswd -b[cmB25dpsDv] [-C cost] [-r rounds] passwordfile username password
# 
# 	htpasswd -n[imB25dps] [-C cost] [-r rounds] username
# 	htpasswd -nb[mB25dps] [-C cost] [-r rounds] username password
#  -c  Create a new file.
#  -n  Don't update file; display results on stdout.
#  -b  Use the password from the command line rather than prompting for it.
#  -i  Read password from stdin without verification (for script usage).
#  -m  Force MD5 encryption of the password (default).
#  -2  Force SHA-256 crypt() hash of the password (secure).
#  -5  Force SHA-512 crypt() hash of the password (secure).
#  -B  Force bcrypt aencryption of the password (very secure).
#  -C  Set the computing time used for the bcrypt algorithm
#      (higher is more secure but slower, default: 5, valid: 4 to 31).
#  -r  Set the number of rounds used for the SHA-256, SHA-512 algorithms
#      (higher is more secure but slower, default: 5000).
#  -d  Force CRYPT encryption of the password (8 chars max, insecure).
#  -s  Force SHA-1 encryption of the password (insecure).
#  -p  Do not encrypt the password (plaintext, insecure).
#  -D  Delete the specified user.
#  -v  Verify password for the specified user.
# On other systems than Windows and NetWare the '-p' flag will probably not work.
# The SHA-1 algorithm does not use a salt and is less secure than the MD5 algorithm.

```

**配置nginx认证**
```
server {
  listen 80;
  server_name  localhost;
  # ...
  
  auth_basic "请输入用户和密码"; # 验证时的提示信息
  auth_basic_user_file /usr/local/nginx/password; # 认证文件

  location / {
      root   /var/www;
      index  index.html index.htm;
  }
  # ...
}
```


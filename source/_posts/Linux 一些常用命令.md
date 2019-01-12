---
title: Linux 一些常用命令
date: 2017-06-11 15:18:59
tags: [Linux]
categories: 网络运维
---
## cat 命令
```
cat -n textfile1 > textfile2        #把 textfile1 的文档内容加上行号后输入 textfile2 这个文档里
cat /dev/null > /etc/test.txt       #清空 /etc/test.txt 文档内容
cat error.log | grep -C 5 'goods'   #显示file文件里匹配goods字串那行以及上下5行
cat error.log | grep -B 5 'goods'   #显示goods及前5行
cat error.log | grep -A 5 'goods'   #显示goods及后5行
```

## tail 命令
```
tail -n 100 error.log             #显示error.log的最后100行
tail -n +100 error.log            #显示error.log从100行开始
```

## head 命令
```
head -n 10 error.log          #显示前10条
head -n +10 error.log         #显示前10条
head -10 error.log            #显示前10条
```

## ps 命令
```
ps -l                          #将目前属于您自己这次登入的 PID 与相关信息列示出来
ps aux                         #列出目前所有的正在内存当中的程序
ps aux | grep tomcat           #列出与tomcat有关的pid
```

## df,du 命令
```
df                       # 显示磁盘使用的文件系统信息
df -h                    # -h选项，通过它可以产生可读的格式df命令的输出
du                       # 显示目录或者文件所占空间
du -h test               # 方便阅读的格式显示test目录所占空间情况
du -h --max-depth=1      # 显示当前文件夹下，格式化各个文件的大小
du -h --max-depth=1 /usr	#显示/usr 文件夹下的各个文件的大小
```

## free 命令
```
# 显示系统内存的使用情况，-m是 以MB 为单位显示，其他参数可通过 --help 来查看
free -m
```


## chmod 命令

```
chmod ugo+r file1.txt              #将文件 file1.txt 设为所有人皆可读取 :
chmod a+r file1.txt                #将文件 file1.txt 设为所有人皆可读取 :
chmod 777 file                     #将文件 file1.txt 设为所有人皆可读取  数字，r=4，w=2，x=1
chmod ug+w,o-w file1.txt file2.txt #将文件 file1.txt 与 file2.txt 设为该文件拥有者，与其所属同一个群体者可写入，但其他以外的人则不可写入 :
chmod u+x ex1.py                   #将 ex1.py 设定为只有该文件拥有者可以执行
chmod -R a+r *                     #将目前目录下的所有文件与子目录皆设为任何人可读取
```

## scp命令
```
scp /mnt/backup/gdweb.war  root@192.168.1.1:/root/gdweb.war        #192.168.1.1 就是目标主机ip，
```

## kill 命令
```
# 杀掉所有mongod 的所有进程，-2 比较好，-9 有点暴力
kill -2 $(pidof mongod)
```

## rpm 命令
```
# 查看 pcre 是否安装，要查看其他的，把pcre 改成你要检查的程序即可，比如 查看java是否安装 :rpm -qa java
rpm -qa pcre
```
## groupadd  命令
#### 格式：groupadd 选项 用户组
##### 其中各选项含义如下：
##### 代码:
##### -g GID 指定新用户组的组标识号（GID）。
##### -o 一般与-g选项同时使用，表示新用户组的GID可以与系统已有用户组的GID相同。
```
# 创建一个用户组：superman
groupadd superman
```

## useradd 命令
#### 格式：useradd 选项 用户名
##### 其中各选项含义如下：
##### 代码:
##### -c comment 指定一段注释性描述。
##### -d 目录 指定用户主目录，如果此目录不存在，则同时使用-m选项，可以创建主目录。
##### -g 用户组 指定用户所属的用户组。
##### -G 用户组，用户组 指定用户所属的附加组。
##### -s Shell文件 指定用户的登录Shell。
##### -u 用户号 指定用户的用户号，如果同时有-o选项，则可以重复使用其他用户的标识号。
```
# 创建一个用户：rstyro
useradd -d /usr/rstyro -m -g es rstyro
```

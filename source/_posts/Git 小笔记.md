---
title: Git 小笔记
date: 2017-05-20 10:00:13
tags: [Git]
categories: 笔记
---
### 一、git 删除远程idea 文件
```bash
1、查看远程分支
$ git branch -a 

2、查看本地分支
git branch

3、切换分支
git checkout master

4、删除缓存区.idea（保留工作区.idea）
$ git rm --cached -r .idea
$ git rm --cached -r *.iml

# 将.idea从源代码仓库中删除（-m 表示备注）
$ git commit -m "commit and remove .idea"

# 推送到远程端
$ git push origin master
```


### 二、git 设置代理
```
# 设置代理
git config --global http.proxy http://127.0.0.1:19180
git config --global https.proxy https://127.0.0.1:19180


# 只代理 github.com,其他不走代理
git config --global http.https://github.com.proxy  http://127.0.0.1:19180

# 取消代理
git config --global --unset http.proxy
git config --global --unset https.proxy
```

### 三、git commit 撤销

+ 我们有时候写完代码：`git commit -m "本功能全部完成"`
+ 然后发现搞错了，想撤回commit，怎么办？
+ 如下：
```shell
# 仅仅是撤回commit操作，您写的代码仍然保留
git reset --soft HEAD^
```
**命令解析：**
+ HEAD^的意思是上一个版本，也可以写成HEAD~1
+ 如果你进行了2次commit，想都撤回，可以使用HEAD~2
+ --soft 
不删除工作空间改动代码，撤销commit，不撤销git add . 
+ --hard
删除工作空间改动代码，撤销commit，撤销`git add .` 注意完成这个操作后，就恢复到了上一次的commit状态。
+ --mixed 
不删除工作空间改动代码，撤销commit，并且撤销`git add .` 操作 ,这个为默认参数,`git reset --mixed HEAD^` 和 `git reset HEAD^` 效果是一样的


### 四、Git 记住密码

```
# 第一次需要输入账号密码，之后就都不必再输入了
git config --global credential.helper store

# 第一次需要输入账号密码，15分钟内不必再输入
git config --global credential.helper cache

# 第一次需要输入账号密码，300秒内不必再输入
git config --global credential.helper 'cache --timeout=300'
```
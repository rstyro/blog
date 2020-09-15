---
title: Git 小笔记
date: 2017-05-20 10:00:13
tags: [Git]
categories: 笔记
---
### git 删除远程idea 文件
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
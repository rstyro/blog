---
title: Mysql 零散笔记
date: 2018-01-04 18:03:27
updated: 2018-01-04 18:03:27
tags: [MYSQL]
categories: 数据库
---
# Mysql 零散笔记

## 一、小数点不够自动补零
#### 1、FORMAT
```
# 第二个参数是 保留几位小数 ，---> '12,332.1235'
SELECT FORMAT(12332.123456, 4);

```

#### 2、truncate
```
# 输出 ---->4545.13
select truncate(4545.1366,2);
```

#### 3、convert
```
# 第二个参数可以填有很多类型，DECIMAL(15,2) 中的2 是两位小数点
select convert(15645.1246,DECIMAL(15,2));
```

## 二、字符串拼接

#### 1、concat
```
select concat('￥',8898898.15) as RMB

# 查询
a.name LIKE CONCAT(CONCAT('%', #{keyword}),'%')
```
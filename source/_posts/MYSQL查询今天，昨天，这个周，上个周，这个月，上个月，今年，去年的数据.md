---
title: MYSQL查询今天，昨天，这个周，上个周，这个月，上个月，今年，去年的数据
date: 2017-04-10 21:02:42
tags: [MYSQL]
categories: 数据库
---
## 一般后台做报表什么的，可能会用到
##### createTime ---- 创建时间， 就是你要对比的时间，表的字段类型为 datetime
### 直接上代码
```
-- 查询上周的数据 
-- SELECT count(id) as count FROM user WHERE YEARWEEK(date_format(createTime,'%Y-%m-%d')) = YEARWEEK(now())-1; 
-- 查询这个周的数据
-- SELECT count(id) as count FROM user WHERE YEARWEEK(date_format(createTime,'%Y-%m-%d')) = YEARWEEK(now())
-- 查询上个月的数据 
-- select count(id) as count from user where date_format(createtime,'%Y-%m')=date_format(DATE_SUB(curdate(), INTERVAL 1 MONTH),'%Y-%m') 
-- 查询这个月的数据 
-- SELECT count(id) as count FROM user WHERE date_format(createtime,'%Y-%m')=date_format(now(),'%Y-%m');
-- select count(id) as count from `user` where DATE_FORMAT(createtime,'%Y%m') = DATE_FORMAT(CURDATE(),'%Y%m') ; 
-- 查询距离当前现在6个月的数据 
-- select count(id) as count from user where createtime between date_sub(now(),interval 6 month) and now(); 
-- 查询今天的数据
-- SELECT count(id) as count FROM user WHERE date_format(createtime,'%Y-%m-%d')=date_format(now(),'%Y-%m-%d');
-- 查询昨天的数据
-- SELECT * FROM user WHERE TO_DAYS(NOW())-TO_DAYS(createTime) = 1
-- 今年的
-- select * from `user` where YEAR(createTime)=YEAR(NOW());
-- 去年的
-- select * from `user` where YEAR(createTime)=YEAR(NOW())-1;
-- 来一发集合的select 
    t1.count as toDay,
    tt1.count as lastDay,
    t2.count as lastWeek,
    tt2.count as toWeek,
    t3.count as lastMonth,
    tt3.count as toMonth,
    t4.count as toYear,
    tt4.count as lastYear,
    t.count as total    from (SELECT count(id) as count FROM user WHERE date_format(createtime,'%Y-%m-%d')=date_format(now(),'%Y-%m-%d')) t1,
(SELECT count(id) as count FROM user WHERE TO_DAYS(NOW())-TO_DAYS(createTime) = 1) tt1,
(SELECT count(id) as count FROM user WHERE YEARWEEK(date_format(createTime,'%Y-%m-%d')) = YEARWEEK(now())-1) t2,
(SELECT count(id) as count FROM user WHERE YEARWEEK(date_format(createTime,'%Y-%m-%d')) = YEARWEEK(now())) tt2,
(select count(id) as count from user where date_format(createtime,'%Y-%m')=date_format(DATE_SUB(curdate(), INTERVAL 1 MONTH),'%Y-%m')) t3,
(SELECT count(id) as count FROM user WHERE date_format(createtime,'%Y-%m')=date_format(now(),'%Y-%m')) tt3,
(select count(id) as count from `user` where YEAR(createTime)=YEAR(NOW())) t4,
(select count(id) as count from `user` where YEAR(createTime)=YEAR(NOW())-1) tt4,
(select count(id) as count from user) t
```
### 统计当前月，后12个月，各个月的数据
####下面是创建对照视图 sql
```
CREATE
    ALGORITHM = UNDEFINED 
    DEFINER = `tyro`@`%` 
    SQL SECURITY DEFINERVIEW `past_12_month_view` AS
    SELECT DATE_FORMAT(CURDATE(), '%Y-%m') AS `month` 
    UNION SELECT DATE_FORMAT((CURDATE() - INTERVAL 1 MONTH), '%Y-%m') AS `month` 
    UNION SELECT DATE_FORMAT((CURDATE() - INTERVAL 2 MONTH), '%Y-%m') AS `month` 
    UNION SELECT DATE_FORMAT((CURDATE() - INTERVAL 3 MONTH), '%Y-%m') AS `month` 
    UNION SELECT DATE_FORMAT((CURDATE() - INTERVAL 4 MONTH), '%Y-%m') AS `month` 
    UNION SELECT DATE_FORMAT((CURDATE() - INTERVAL 5 MONTH), '%Y-%m') AS `month` 
    UNION SELECT DATE_FORMAT((CURDATE() - INTERVAL 6 MONTH), '%Y-%m') AS `month` 
    UNION SELECT DATE_FORMAT((CURDATE() - INTERVAL 7 MONTH), '%Y-%m') AS `month` 
    UNION SELECT DATE_FORMAT((CURDATE() - INTERVAL 8 MONTH), '%Y-%m') AS `month` 
    UNION SELECT DATE_FORMAT((CURDATE() - INTERVAL 9 MONTH), '%Y-%m') AS `month` 
    UNION SELECT DATE_FORMAT((CURDATE() - INTERVAL 10 MONTH), '%Y-%m') AS `month` 
    UNION SELECT DATE_FORMAT((CURDATE() - INTERVAL 11 MONTH), '%Y-%m') AS `month`
```
####然后和你想要统计的表进行关联查询,如下的demo
```
select 
    v.month,    ifnull(b.minute,0) count from 
    past_12_month_view v 
left join (select DATE_FORMAT(t.createTime,'%Y-%m') month,count(t.id) minute  from user t  group by month) b 
on 
    v.month = b.month 
group by 
    v.month
```
### 顺便把我上次遇到的一个排序小问题也写出来

##### 数据表有一个sort_num 字段来代表排序，但这个字段有些值是null，现在的需求是,返回结果集按升序返回，如果sort_num 为null 则放在最后面mysql null 默认是最小的值，如果按升序就会在前面.
#### 解决方法：
```
SELECT * from table_name 
ORDER BY 
  case WHEN 
  sort_num is null 
  then 
    1 
  else 0 end, sort_num asc
```

#### 再写一个吧
#### case when 统计个数
```
SELECT 
    count(*) as total,
    sum(case when a.notice_type='praise' THEN 1 else 0 end) as praiseNum,
    sum(case when a.notice_type='concern' THEN 1 else 0 end) as concernNum,
    sum(case when a.notice_type='letter' THEN 1 else 0 end) as letterNum,
    sum(case when a.notice_type='comment' THEN 1 else 0 end) as commentNum
FROM
    blog_notice a
```

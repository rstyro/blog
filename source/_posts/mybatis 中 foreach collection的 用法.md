---
title: mybatis 中 foreach collection的 用法
date: 2017-05-03 14:58:22
updated: 2017-05-03 14:58:22
tags: [MYSQL, Java]
categories: Java
---
# Mybits foreach 的用法
### foreach元素的属性主要有 item，index，collection，open，separator，close。

|属性|说明|
|--|--|
|item|表示集合中每一个元素进行迭代时的别名，|
|index|指 定一个名字，用于表示在迭代过程中，每次迭代到的位置，|
|open|表示该语句以什么开始，|
|separator|表示在每次进行迭代之间以什么符号作为分隔符，|
|close|表示以什么结束。|

<!--more-->

#### 在使用foreach的时候最关键的也是最容易出错的就是collection属性，该属性是必须指定的，但是在不同情况 下，该属性的值是不一样的，主要有一下3种情况：

#### 1. 如果传入的是单参数且参数类型是一个List的时候，collection属性值为list
#### 2. 如果传入的是单参数且参数类型是一个array数组的时候，collection的属性值为array
#### 3. 如果传入的参数是多个的时候，我们就需要把它们封装成一个Map了，当然单参数也可

## 上例子

### 一、通过id获取多条数据
+ List 类型的我都配置了别名list,参数是 `List<Article>` ，Article 是我自己定义的实体类

```sql
<!-- 获取标签文章列表 -->
<select id="getArticleList" parameterType="list"  resultType="pm">
SELECT
	*
from 
	blog_article a
where
	a.article_id in
	<foreach item="item" collection="list" index="index" open="(" separator="," close=")">
		#{item.article_id}
	</foreach>
	and isdel=0
order by
	a.create_time desc,a.update_time desc
</select>
```

### 二、批量插入数据

```sql
<!-- 批量新增-->
<insert id="batchSaveArticleLabel" parameterType="list">
	insert into blog_article_label(
		article_id,
		label_id
	) values
	<foreach collection="list" item="item" index="index" separator="," >
	(
		#{item.article_id},
		#{item.label_id}
	)
	</foreach>
</insert>
```

### 三、对一个字段进行多次模糊匹配

```sql
select * from table
<where>
   <foreach collection="list" item="item" index="index" separator="or">
      name like '%${item}%'
   </foreach>
</where>
```

### 上面的参数都是 `List`,如果是 `String[]` 这种的就是把collection 的值改为array,如下demo

### 四、批量删除

```sql
<delete id="getArticleList" parameterType="String">
DEKETE
from 
	blog_article a
where
a.article_id in
<foreach collection="array" index="index" item="item" open="(" separator="," close=")">
	#{item}
</foreach>
</delete>
```

### 五、批量修改
+ 参数是 `Map<String,Object>` ,我下面写map 是因为配置了别名
+ Java 代码是这样的:

```java
Map<String,Object> map = new HashMap<>();
String[] ids = {"1","2","3"};
map.put("content","修改的内容");
map.put("ids",ids);
```
mapper 文件
```sql
<update id="update" parameterType="map">
UPDATE table
	set 
		content="#{content}"
WHERE
id in
<foreach collection="ids" index="index" item="item" open="(" separator="," close=")">
	#{item}
</foreach>
</update>
```

#### 还有一种

```sql
<update id="updateUserChildNum" parameterType="list">
		UPDATE usr_relation_umbrella
			SET child_number = CASE user_id
			<foreach collection="list" item="item">
				WHEN #{item.userId} THEN #{item.childNumber}
			</foreach>
			END
		WHERE user_id IN
		<foreach item="item" collection="list" index="index" open="(" separator="," close=")">
			#{item.userId}
		</foreach>
	</update>
```
#### 多个

```sql
UPDATE categories 
    SET display_order = CASE id 
        WHEN 1 THEN 3 
        WHEN 2 THEN 4 
        WHEN 3 THEN 5 
    END, 
    title = CASE id 
        WHEN 1 THEN 'New Title 1'
        WHEN 2 THEN 'New Title 2'
        WHEN 3 THEN 'New Title 3'
    END
WHERE id IN (1,2,3)
```

#### Mybatis 主键自增的时候，保存时返回主键。
+  如下demo,在mapper.xml 中定义

```sql
<!-- 保存文章 -->
	<insert id="saveArticle" parameterType="pm" useGeneratedKeys="true" keyProperty="article_id">
		insert into blog_article(
			<if test="user_id != null and user_id != ''">
				user_id,
			</if>
			title,
			content,
			<if test="text != null and text != ''">
				text,
			</if>
			create_time
		)values(
			<if test="user_id != null and user_id != ''">
				#{user_id},
			</if>
			#{title},
			#{content},
			<if test="text != null and text != ''">
				#{text},
			</if>
			#{create_time}
		)
	</insert>
```

+ `useGeneratedKeys` 表示给主键设置自增长
+ `keyProperty` 表示将自增长后的Id赋值给 你的实体类pm添加 article_id 这个字段。pm 是我封装的一个实体类

#### 一般后台做报表什么的，可能会用到
+ createTime ---- 创建时间， 就是你要对比的时间，表的字段类型为 datetime
+ 直接上代码


```sql
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

#### 统计当前月，后12个月，各个月的数据
+ 下面是创建对照视图 sql

```sql
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
#### 然后和你想要统计的表进行关联查询,如下的demo

```sql
select 
    v.month,    ifnull(b.minute,0) count from 
    past_12_month_view v 
left join (select DATE_FORMAT(t.createTime,'%Y-%m') month,count(t.id) minute  from user t  group by month) b 
on 
    v.month = b.month 
group by 
    v.month
```
#### 顺便把我上次遇到的一个排序小问题也写出来
+ 数据表有一个sort_num 字段来代表排序，但这个字段有些值是null，现在的需求是,返回结果集按升序返回，如果sort_num 为null 则放在最后面mysql null 默认是最小的值，如果按升序就会在前面.
+ 解决方法：

```
SELECT * from table_name 
ORDER BY 
  case WHEN 
  sort_num is null 
  then 
    1 
  else 0 end, sort_num asc
```


+ case when 统计个数

```sql
SELECT 
    count(*) as total,
    sum(case when a.notice_type='praise' THEN 1 else 0 end) as praiseNum,
    sum(case when a.notice_type='concern' THEN 1 else 0 end) as concernNum,
    sum(case when a.notice_type='letter' THEN 1 else 0 end) as letterNum,
    sum(case when a.notice_type='comment' THEN 1 else 0 end) as commentNum
FROM
    blog_notice a
```

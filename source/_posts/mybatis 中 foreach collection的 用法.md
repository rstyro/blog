---
title: mybatis 中 foreach collection的 用法
date: 2017-05-03 14:58:22
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

#### 在使用foreach的时候最关键的也是最容易出错的就是collection属性，该属性是必须指定的，但是在不同情况 下，该属性的值是不一样的，主要有一下3种情况：

#### 1. 如果传入的是单参数且参数类型是一个List的时候，collection属性值为list
#### 2. 如果传入的是单参数且参数类型是一个array数组的时候，collection的属性值为array
#### 3. 如果传入的参数是多个的时候，我们就需要把它们封装成一个Map了，当然单参数也可

## 上例子

### 一、通过id获取多条数据
List 类型的我都配置了别名list,参数是 `List<Article>` ，Article 是我自己定义的实体类
```
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
```
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
```
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
参数是 `Map<String,Object>` ,我下面写map 是因为配置了别名
Java 代码是这样的:
```
Map<String,Object> map = new HashMap<>();
String[] ids = {"1","2","3"};
map.put("content","修改的内容");
map.put("ids",ids);
```
mapper 文件
```
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
```
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
```
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
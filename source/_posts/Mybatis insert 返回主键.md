---
title: Mybatis insert 返回主键
date: 2017-11-20 12:13:42
tags: [MYSQL]
categories: 数据库
---
# Mybatis 主键自增的时候，保存时返回主键。
## 如下demo,在mapper.xml 中定义
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
#### `useGeneratedKeys` 表示给主键设置自增长
#### `keyProperty` 表示将自增长后的Id赋值给 你的实体类pm添加 article_id 这个字段。pm 是我封装的一个实体类


# 还有其他的方法，但这个是我经常用的，其他不经常用就不粘了。
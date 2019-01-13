---
title: ElasticSearch 查询报错QueryPhaseExecutionException Result window is too large....
date: 2018-01-13 14:34:22
tags: [ElasticSearch]
categories: 搜索引擎
---
# ES 报错
## 一、QueryPhaseExecutionException
```
nested: QueryPhaseExecutionException[Result window is too large, from + size must be less than or equal to: [10000] but was [10010].
 See the scroll api for a more efficient way to request large data sets. This limit can be set by changing the [index.max_result_window] index level setting.]; }
 ```
#### 解决方法：
```
# indexName 改为你的索引名称
curl -XPUT http://127.0.0.1:9200/indexName/_settings -d '{ "index" : { "max_result_window" : 100000000}}'
```
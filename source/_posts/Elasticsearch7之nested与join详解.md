---
title: Elasticsearch7之nested与join详解
date: 2020-10-12 18:15:30
tags: [ElasticSearch]
categories: 搜索引擎
---
### 一、 前言
简单来讲，nested与join的都是特殊的对象类型，功能基本都是做数据关联的。


### 二、nested类型

 `nested` 是数据嵌套，也就是说数据保存的时候就已经嵌套关联好了，查询的时候立马就可以直接返回。
因为已经保存的时候关联好了，所以它的应用场景很适合查询比较频繁的。
而`nested` 与`object` 类型挺类似的，最大的区别就是`nested`字段里面的属性可以进行检索,也就是查询，而`object`里面的内容没法单独检索。

#### 1、创建索引

首先需要创建`nested`类型的索引，以帖子的内容嵌套帖子的评论来举例。
```yml
# 创建帖子的索引为topic。而comments为nested类型，做为帖子评论列表
PUT http://172.16.1.236:9201/topic

{
    "settings": {
        "number_of_shards": 3,
        "number_of_replicas": 0
    },
    "mappings": {
        "properties": {
            "update_time": {
                "type": "date",
                "format": "yyyy-MM-dd HH:mm:ss || yyyy-MM-dd'T'HH:mm:ss.SSS || yyyy-MM-dd || epoch_millis"
            },
            "create_time": {
                "type": "date",
                "format": "yyyy-MM-dd HH:mm:ss || yyyy-MM-dd'T'HH:mm:ss.SSS || yyyy-MM-dd || epoch_millis"
            },
            "user_id": {
                "type": "long"
            },
            "is_del": {
                "type": "boolean"
            },
            "location": {
                "type": "geo_point",
                "ignore_malformed": "true"
            },
            "id": {
                "type": "keyword"
            },
            "title": {
                "type": "keyword"
            },
            "content": {
                "term_vector": "with_positions_offsets",
                "search_analyzer": "ik_smart",
                "type": "text",
                "analyzer": "ik_max_word"
            },
            "status": {
                "type": "short"
            },
            "comments":{
                "type":"nested",
                "properties":{
                    "id":{
                        "type":"keyword"
                    },
                    "user_id":{
                        "type":"long"
                    },
                    "content":{
                        "type":"text",
                        "search_analyzer": "ik_smart",
                        "analyzer": "ik_max_word",
                        "term_vector": "with_positions_offsets"
                    },
                    "praise_num":{
                        "type":"long"
                    },
                    "create_time":{
                        "type": "date",
                        "format": "yyyy-MM-dd HH:mm:ss || yyyy-MM-dd'T'HH:mm:ss.SSS || yyyy-MM-dd || epoch_millis"
                    }
                }
            }
        }
    }
}
```

把`comments` 字段做为`nested` 类型，且在其下定义几个属性（`id、user_id、content、praise_num、create_time`）

#### 2、添加数据

索引建好了，那当然是新增数据了，随便新增几条数据
```yml
PUT http://172.16.1.236:9201/topic/_doc/1

{
    "comments": [
        {
            "content": "1楼占个沙发，镇楼！！！",
            "create_time": "2020-10-09 17:48:37",
            "id": "f1a551ea8e0244ccb27072109ac94197",
            "praise_num": 1,
            "user_id": 1
        },
        {
            "content": "打破互联网的是人类呗，还能是什么",
            "create_time": "2020-10-09 17:48:37",
            "id": "f4f29dc3e3ce400898a2e648369f1108",
            "praise_num": 2,
            "user_id": 1
        }
    ],
    "content": "最终将打破互联网的是什么？",
    "create_time": "2020-10-09 17:48:37",
    "id": "3d0954d31a4e47f7ba703c259d43ee67",
    "is_del": false,
    "location": "22.013134,113.12341335",
    "status": 1,
    "title": "互联网",
    "update_time": "2020-10-09 17:48:37",
    "user_id": 1
}
```

第二条
```

PUT http://172.16.1.236:9201/topic/_doc/2

{
  "update_time": "2020-10-09 18:01:13",
  "comments": [
    {
      "create_time": "2020-10-03 18:01:13",
      "user_id": 1,
      "praise_num": 168,
      "id": "112227332c5e479085f688708ffcf89b",
      "content": "1楼占个沙发，镇楼！！！"
    },
    {
      "create_time": "2020-10-04 18:01:14",
      "user_id": 2,
      "praise_num": 666,
      "id": "61f131dd53dc49a2970187b8951ca869",
      "content": "PHP是全世界最好的语言"
    },
    {
      "create_time": "2020-10-05 18:01:15",
      "user_id": 3,
      "praise_num": 2,
      "id": "350bca8e118644f9864e58eeded9e068",
      "content": "Java是全世界最好的语言"
    },
    {
      "create_time": "2020-10-05 18:01:16",
      "user_id": 4,
      "praise_num": 2,
      "id": "2eef86ccddce4b02a7c9b81cc321cfc9",
      "content": "不应该是C语言吗"
    },
    {
      "create_time": "2020-10-08 18:01:17",
      "user_id": 5,
      "praise_num": 2,
      "id": "8d5e0cf841db4ae1b47fd3eeb799f2e2",
      "content": "我的C++应该是上榜的"
    }
  ],
  "create_time": "2020-10-09 18:01:13",
  "user_id": 1,
  "is_del": false,
  "location": "22.013134,113.12341335",
  "id": "1809bd926a504a028e00fe427bbb58a9",
  "title": "语言",
  "content": "什么是世界上最好的语言？",
  "status": 1
}
```

#### 3、nested查询

nested 查询需要指定一个path,path就是需要查询的nested字段是哪个

```yml
POST  http://172.16.1.236:9201/topic/_search

# 简单的查询
{
    "query": {
        "nested": {
            "query": {
                "match": {
                    "comments.content": {
                        "query": "世界"
                    }
                }
            },
            "path": "comments"
        }
    }
}



# 复杂一点点的
{
  "query": {
    "bool": {
      "must": [
        {
          "match": {
            "title": "语言"
          }
        },
        {
          "nested": {
            "path": "comments",
            "query": {
              "bool": {
                "must": [
                  {
                    "match": {
                      "comments.content": "世界"
                    }
                  }
                ]
              }
            }
          }
        }
      ]
    }
  }
}


# 在复杂一点点，聚合，求总的评论点赞数
{
    "query": {
        "bool": {
            "must": [
                {
                    "match": {
                        "title": "语言"
                    }
                },
                {
                    "nested": {
                        "path": "comments",
                        "query": {
                            "bool": {
                                "must": [
                                    {
                                        "match": {
                                            "comments.content": "世界"
                                        }
                                    }
                                ]
                            }
                        }
                    }
                }
            ]
        }
    },
    "aggs": {
        "comments": {
            "nested": {
                "path": "comments"
            },
            "aggs": {
                "sumPraiseNum": {
                    "sum": {
                        "field": "comments.praise_num"
                    }
                }
            }
        }
    }
}


# 也可以再筛选一下
{
    "query": {
        "bool": {
            "must": [
                {
                    "match": {
                        "title": "语言"
                    }
                },
                {
                    "nested": {
                        "path": "comments",
                        "query": {
                            "bool": {
                                "must": [
                                    {
                                        "match": {
                                            "comments.content": "世界"
                                        }
                                    }
                                ]
                            }
                        }
                    }
                }
            ]
        }
    },
    "aggs": {
        "comments": {
            "nested": {
                "path": "comments"
            },
            "aggs": {
                "by_day": {
                    "date_histogram": {
                        "field": "comments.create_time",
                        "interval": "day",
                        "format": "yyyy-MM-dd"
                    },
                    "aggs": {
                        "sum_num": {
                            "sum": {
                                "field": "comments.praise_num"
                            }
                        }
                    }
                }
            }
        }
    }
}

```


#### 4、nested删除

只删除nested字段里面的某个内容

```yml
# 删除ES ID为1 comments里面user_id 等于1 的数据
POST  http://172.16.1.236:9201/topic1/_doc/1/_update
{
 "script": {
    "lang": "painless",
    "source": "ctx._source.comments.removeIf(it -> it.user_id == 1);"
 }
}
```

#### 5、nested修改
nested 的修改，常规写法需要全部替换，否则就需要写脚本更改

```yml
# 更新comments里面，user_id=1 的数据
POST  http://172.16.1.236:9201/topic1/_doc/2/_update
{
  "script": {
    "source": "for(item in ctx._source.comments){if (item.user_id == 1) {item.praise_num = 168; item.content= '1楼评论更新！！！！';}}" 
  }
}
```

#### 6、其他
**Lucene 沒有內部 object 的概念, 所以 Elasticsearch 內部會把 object 解析成簡單的字段名與值的信息,就是所有字段平鋪。（扁平式键值对的结构）**

**每一个嵌套对象都会被索引为一个 隐藏的独立文档，大概如下这样：**

```
# 第一个嵌套文档
{
    "comments.content": "1楼占个沙发，镇楼！！！",
    "comments.create_time": "2020-10-09 17:48:37",
    "comments.id": "f1a551ea8e0244ccb27072109ac94197",
    "comments.praise_num": 1,
    "comments.user_id": 1
}
# 第二个嵌套文档
{
    "comments.content": "打破互联网的是人类呗，还能是什么",
    "comments.create_time": "2020-10-09 17:48:37",
    "comments.id": "f1a551ea8e0244ccb27072109ac94197",
    "comments.praise_num": 1,
    "comments.user_id": 1
}

# 根文档 或者也可称为父文档
{

    "content": "最终将打破互联网的是什么？",
    "create_time": "2020-10-09 17:48:37",
    "id": "3d0954d31a4e47f7ba703c259d43ee67",
    "is_del": false,
    "location": "22.013134,113.12341335",
    "status": 1,
    "title": "互联网",
    "update_time": "2020-10-09 17:48:37",
    "user_id": 1
}
```

每个嵌套对象都被索引为一个单独的Lucene文档。因为映射的相关开销，可能回影响性能问题，所以Elasticsearch设置了限制，比如：
+ `index.mapping.nested_objects.limit` 
此参数设置单个文档可跨所有nested类型包含的最大嵌套JSON对象数 。
当文档包含太多嵌套对象时，此限制有助于防止出现内存不足错误。默认值为10000。
+ `index.mapping.nested_fields.limit`
此参数就是nested索引中 最大不同映射的数量，为了防止设计不良的映射，默认值为50。



### 三、join类型
在Elasticsearch中，Join可以让我们创建parent/child关系。Elasticsearch不是一个RDMS。通常join数据类型尽量不要使用，除非不得已。



#### 1、创建索引

还是和上面嵌套文档一样，以帖子内容与其评论为例。
```yml
# 索引名称join_topic
PUT  http://172.16.1.236:9201/join_topic

{
    "settings": {
        "number_of_shards": 3,
        "number_of_replicas": 0
    },
    "mappings": {
        "properties": {
            "update_time": {
                "type": "date",
                "format": "yyyy-MM-dd HH:mm:ss || yyyy-MM-dd'T'HH:mm:ss.SSS || yyyy-MM-dd || epoch_millis"
            },
            "create_time": {
                "type": "date",
                "format": "yyyy-MM-dd HH:mm:ss || yyyy-MM-dd'T'HH:mm:ss.SSS || yyyy-MM-dd || epoch_millis"
            },
            "user_id": {
                "type": "long"
            },
            "is_del": {
                "type": "boolean"
            },
            "location": {
                "type": "geo_point",
                "ignore_malformed": "true"
            },
            "id": {
                "type": "keyword"
            },
            "title": {
                "type": "keyword"
            },
            "content": {
                "term_vector": "with_positions_offsets",
                "search_analyzer": "ik_smart",
                "type": "text",
                "analyzer": "ik_max_word"
            },
            "status": {
                "type": "short"
            },
             "praise_num":{
                "type":"long"
            },
            "relation_type":{
                "type": "join",
                "relations": {
                    "topic": "comments"
                }
            }
        }
    }
}
```

+ **relation_type：就是join类型的名称，可以随意定义。**
+ **relations：定义一组关系，每个关系都是parent名称和child名称。**
也就是关系可以有多个，但是不建议,像下面这样也是可以的。
```
"relation_type":{
	"type": "join",
	"relations": {
		"topic": "comments",
		"parent1": ["other1","other2"],
		"other1": "other"
	}
}
```
+ **以上我们以 `topic`做为父级，`comments`做为子级。一个topic可以有多个comments.**

#### 2、添加父级数据

+ 和平常保存数据基本一样，这里需要注意的一点就是，父子文档必须要保存在同一个分片中，否则查询可能就会查不到。
+ 可以使用`routing`参数，配置相同的routing值，把父子文档路由到相同的分片。routing公式=`shard_num = hash(_routing) % num_primary_shards`
+ routing 默认是文档的`_id`.
        
```
PUT http://172.16.1.236:9201/join_topic/_doc/1?routing=1
{
    "content": "最终将打破互联网的是什么？",
    "create_time": "2020-10-09 17:48:37",
    "id": "3d0954d31a4e47f7ba703c259d43ee67",
    "is_del": false,
    "location": "22.013134,113.12341335",
    "status": 1,
    "title": "互联网",
    "update_time": "2020-10-09 17:48:37",
    "user_id": 1,
    "relation_type":{
        "name":"topic"
    }
}
```

**如上，relation_type 的name指定为父级的name即可，然后routing的值就以父级的id**


#### 3、添加子级数据

添加子类数据，需要指定父级的ID是哪个，并且它的routing 要与父级的一样，如下例子：
```
PUT http://172.16.1.236:9201/join_topic/_doc/2?routing=1

{
    "content": "1楼占个沙发，镇楼！！！",
    "create_time": "2020-10-10 17:48:37",
    "id": "f1a551ea8e0244ccb27072109ac94197",
    "praise_num": 1,
    "user_id": 1,
    "relation_type":{
        "name":"comments",
        "parent":"1"
    }
}

```

join 类型的name 指定为子类，并设置parent的id，在加一条
```
PUT http://172.16.1.236:9201/join_topic/_doc/3?routing=1

{
    "content": "打破互联网的是人类呗，还能是什么！！！",
    "create_time": "2020-10-10 17:48:37",
    "id": "f1a551ea8e0244ccb27072109ac94197",
    "praise_num": 1,
    "user_id": 2,
    "relation_type":{
        "name":"comments",
        "parent":"1"
    }
}
```

#### 4、查询数据

查询一般分为两种：
+ 根据父文档查询子文档
+ 根据子文档查询父文档

##### A、根据父文档查询子文档

查询子文档一般有`PARENT_ID QUERY`、和 `HAS_PARENT QUERY`。

**A1、通过父级ID搜索子文档-`parent_id query`**

```
POST  http://172.16.1.236:9201/join_topic/_search

{
  "query": {
    "parent_id": {
      "type": "comments",
      "id": "1"
    }
  }
}
```
返回父级id=1 的所有评论

**A2、通过父级ID搜索子文档并过滤子文档-`parent_id query`**

```
POST  http://172.16.1.236:9201/join_topic/_search

{
  "query": {
    "bool": {
      "filter": {
        "term": {
          "user_id": 1
        }
      },
      "must": {
        "parent_id": {
          "type": "comments",
          "id": "1"
        }
      }
    }
  }
}
```
查询帖子ID=1的子文档，并只筛选出user_id=1 的评论文档


**A3、通过父级文档查询子类数据-`has_parent`**
```
POST  http://172.16.1.236:9201/join_topic/_search

{
  "query": {
    "has_parent": {
      "parent_type":"topic",
      "query": {
        "match": {
          "content": "互联网"
        }
      }
    }
  }
}
```
查询帖子内容包含有”互联网“的其下所有评论内容


##### B、根据子文档查询父文档

查询父文档用 has_child 语法

**B1、获取所有有子数据的父文档-has_child**
```
POST  http://172.16.1.236:9201/join_topic/_search
{
  "query": {
    "has_child": {
      "type": "comments",
      "query": {
        "match_all":{}
      }
    }
  }
}
```

查询有评论的所有帖子

**B2、获取匹配子文档数据的父文档-has_child**
```
POST  http://172.16.1.236:9201/join_topic/_search

{
  "query": {
    "has_child": {
      "type": "comments",
      "query": {
        "bool": {
          "must": [
            {
              "match": {
                "content": "互联网"
              }
            }
          ]
        }
      }
    }
  }
}
```
查询评论内容包含”互联网“的帖子


**B3、查询父文档并排序**
```
POST  http://172.16.1.236:9201/join_topic/_search

{
  "query": {
    "has_child": {
      "type": "comments",
      "query": {
        "function_score": {
          "script_score": {
            "script": "_score * doc['praise_num'].value"
          }
        }
      },
      "score_mode": "max"
    }
  }
}
```
查询帖子，以点赞数最高降序返回


### 四、总结

#### 1、nested与join区别
+ **nested 相比join查询更好一点，缺点是更新内容需要全部替换或者脚本更新。如果频繁更新或者更新大对象数据非常影响性能。每次更新都会重新索引整个文档。**
+ **nested文档时嵌套在一起的防止查询时数据过大，内存溢出，限制了子文档的总个数与字段个数**
+ **join 连接字段has_child或has_parent查询都会对查询性能产生重大影响，但是父子文档独立开来，可以分别更新互不影响。**
+ **join的parent及child文档必须在同一个分片**


**能尽量不用这两种类型就尽量不用！！！**


#### 2、参考链接
+ [https://www.elastic.co/guide/en/elasticsearch/reference/7.9/nested.html](https://www.elastic.co/guide/en/elasticsearch/reference/7.9/nested.html)
+ [https://www.elastic.co/guide/en/elasticsearch/reference/7.9/joining-queries.html](https://www.elastic.co/guide/en/elasticsearch/reference/7.9/joining-queries.html)
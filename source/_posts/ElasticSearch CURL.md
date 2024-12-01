---
title: ElasticSearch CURL
date: 2017-12-01 17:54:07
updated: 2017-12-01 17:54:07
tags: [ElasticSearch]
categories: 搜索引擎
---
# Elasticsearch 的语法

## 一、添加

### 1、创建索引
索引名称为：test
```
PUT http://192.168.12.137:9200/test/
{
	"setting":{
		"number_of_shards":5,
		"number_of_replicas":1
	},
	"mappings":{
		"person":{
			"properties":{
				"name":{
					"type":"text"
				},
				"age":{
					"type":"integer"
				},
				"sex":{
					"type":"string"
				},
				"birthday":{
					"type":"date",
					"format":"yyyy-MM-dd HH:mm:ss || yyyy-MM-dd || epoch_millis"
				},
				"introduce":{
					"type":"text"
				}
			}
		}
	}
}
```

<!--more-->

### 2、创建文档(自动生成ID)
给文档person 新增数据
```
POST http://192.168.12.137:9200/test/person/
{
    "name":"jieke",
    "age":20
}
```

### 3、创建文档 (设置id的)
```
POST http://192.168.12.137:9200/test/person/1
{
    "name":"pede",
    "age":20
}
```

## 二、查询

### a、查询索引（test）
```
GET http://192.168.12.137:9201/test/_settings
```

### b、同时获取两个索引（test 和robot）
```
GET http://192.168.12.137:9201/test,robot/_settings
```

### c、查询所有索引的信息
```
http://192.168.12.137:9201/_all/_settings
```

### 1、查询文档信息通过ID
```
GET http://192.168.12.137:9200/test/person/1
```

### 2、查询文档信息通过name属性
```
GET http://192.168.12.137:9200/test/person/_search?q=name:jieke
```

### 3、通过_source 获取指定的字段
只查询 name 字段的数据
```
GET http://192.168.12.137:9200/test/person/1?_source=name
```


### 4、查询所有数据
```
POST http://localhost:9200/test/_search
{
	"query":{
		"match_all":{}
	}
}
```

### 5、form size分页查询
```
POST http://localhost:9200/test/_search
{
	"query":{
		"match_all":{}
	}
	"from":1,
	"size":2
}
```



### 6、查询并排序
```
# 排序
POST http://localhost:9200/test/_search
{
	"query":{
		"match":{
			"name":"lrshuai"
		}
	}
	"sort":[
		{"age":{"order":"desc"}}
	]
}
```

### 7、分组查询 group_by
```
# 统计个数
POST http://localhost:9200/test/_search
{
	"aggs":{
		"group_by_age":{
			"terms":{
				"field":"age"
			}
		},
		"group_by_name":{
			"terms":{
				"field":"name"
			}
		}
	}
}

# stats 
POST http://localhost:9200/test/_search
{
	"aggs":{
		"group_by_age":{
			"stats":{
				"field":"age"
			}
		},
	}
}

# 最小值
POST http://localhost:9200/test/_search
{
	"aggs":{
		"group_by_age":{
			"min":{
				"field":"age"
			}
		},
	}
}
```

### 8、match 查询
```
# 匹配name 
POST http://localhost:9200/test/_search
{
	"query":{
		"match":{
			"name":"lrshuai"
		}
	}
}


# match_phrase 全部匹配，不进行分词
http://localhost:9200/test/_search
{
	"query":{
		"match_phrase":{
			"introduce":"人见"
		}
	}	
}

# slop 是quick dog 相隔的距离有多少。
# 通过设置一个像 50 或者 100 这样的高 slop 值, 你能够排除单词距离太远的文档， 但是也给予了那些单词临近的的文档更高的分数
http://localhost:9200/test/_search
{
   "query": {
      "match_phrase": {
         "title": {
            "query": "quick dog",
            "slop":  50 
         }
      }
   }
}

# multi_match 多个字段匹配
POST http://localhost:9200/test/_search
{
	"query":{
		"multi_match":{
			"query":"见",
			"fields":["name","introduce"]
		}
	}	
}

```

### 9、语法查询
```
# 语法查询
http://localhost:9200/test/_search
{
	"query":{
		"query_string":{
			"query":"见 or 我"
		}
	}	
}

# 语法查询指定字段
POST http://localhost:9200/test/_search
{
	"query":{
		"query_string":{
			"query":"见 or 我",
			"fields":["name","introduce"]
		}
	}	
}

# 字段完全相等的查询
POST http://localhost:9200/test/_search
{
	"query":{
		"term":{
			"name":"lrshuai"
		}
	}	
}
```

### 10、rang 范围查询
```

{
	"query":{
		"range":{
			"age":{
				"gte":20,
				"lte":25
			}
		}
	}	
}

POST http://localhost:9200/test/_search
{
    "query":{
     "range" : {
        "create_time" : {
            "gt" : "2017-01-01 00:00:00",
            "lt" : "2017-12-07 00:00:00"
        }
    }
    }
}

# 多一个月
POST http://localhost:9200/test/_search
{
    "query":{
     "range" : {
        "create_time" : {
            "gt" : "2017-01-01 00:00:00",
            "lt" : "2017-12-07 00:00:00||+1M"
        }
    }
    }
}
```


### 11、should 查询
should 满足其中一个就可以
```
POST http://localhost:9200/test/_search
{
	"query":{
		"bool":{
			"should":[
				{
					"match":{
						"name":"tyro"
					}	
				},{
					"range":{
						"age":{
							"gt":20,
							"lte":25
						}
					}
				}
			]
		}
	}	
}
```


### 12、filter查询
```
POST http://localhost:9200/test/_search
{
	"query":{
		"bool":{
			"filter":{
				"term":{
					"name":"rstyro"
				}
			}
		}
	}	
}
```


### 13、must 与must_not
```
# must 必须满足所有条件
POST http://localhost:9200/test/_search
{
	"query":{
		"bool":{
			"must":[
				{
					"match":{
						"sex":"女"
					}	
				},
				{
					"range":{
						"age":{
							"lte":30
						}	
					}
				}
			]
		}
	}	
}
# 加上filter 过滤
POST http://localhost:9200/test/_search
{
	"query":{
		"bool":{
			"must":[
				{
					"match":{
						"sex":"女"
					}	
				}
			],
			"filter":[
				{
					"term":{
						"introduce":"人"
					}
				}
			]
		}
	}	
}

# must_not 必须不满足所有条件
POST http://localhost:9200/test/_search
{
	"query":{
		"bool":{
			"must_not":[
				{
					"match":{
						"sex":"女"
					}	
				},
				{
					"range":{
						"age":{
							"lte":20
						}	
					}
				}
			]
		}
	}	
}
```

### 14、查询语句提高权重
##### content 字段必须包含 `full 、 text 和 search `所有三个词。
##### 如果` content` 字段也包含` Elasticsearch` 或 `Lucene `，文档会获得更高的评分 `_score` 。
```
{
    "query": {
        "bool": {
            "must": {
                "match": {
                    "content": { 
                        "query":    "full text search",
                        "operator": "and"
                    }
                }
            },
            "should": [ 
                { "match": { "content": "Elasticsearch" }},
                { "match": { "content": "Lucene"        }}
            ]
        }
    }
}
```

#### 再修改一下：
```
GET /_search
{
    "query": {
        "bool": {
            "must": {
                "match": {  
                    "content": {
                        "query":    "full text search",
                        "operator": "and"
                    }
                }
            },
            "should": [
                { "match": {
                    "content": {
                        "query": "Elasticsearch",
                        "boost": 3 
                    }
                }},
                { "match": {
                    "content": {
                        "query": "Lucene",
                        "boost": 2 
                    }
                }}
            ]
        }
    }
}
```
##### 上面的语句使用默认的 boost 值 1 。
##### 而`"query": "Elasticsearch", "boost": 3` 这条语句更为重要，因为它有最高的 boost 值。
##### ` "query": "Lucene","boost": 2 ` 这条语句比使用默认值的更重要，但它的重要性不及`Elasticsearch` 语句。

#### 还有一种方法：boosting 查询
```
{
  "query": {
    "boosting": {
      "positive": {
        "match": {
          "content": "Elasticsearch"
        }
      },
      "negative": {
        "match": {
          "content": "Lucene"
        }
      },
      "negative_boost": 0.5
    }
  }
}
```

它接受 positive 和 negative 查询。只有那些匹配 positive 查询的文档罗列出来，对于那些同时还匹配 negative 查询的文档将通过文档的原始 _score 与 negative_boost 相乘的方式降级后的结果。
为了达到效果， negative_boost 的值必须小于 1.0 。在这个示例中，所有包含负向词的文档评分 _score 都会减半。

### 15、dis_max 查询
#### 分离 最大化查询
##### 比如有如下两条数据：
```
PUT /my_index/my_type/1
{
    "title": "Quick brown rabbits",
    "body":  "Brown rabbits are commonly seen."
}

PUT /my_index/my_type/2
{
    "title": "Keeping pets healthy",
    "body":  "My quick brown fox eats rabbits on a regular basis."
}
```
我们进行查询
```
{
    "query": {
        "bool": {
            "should": [
                { "match": { "title": "Brown fox" }},
                { "match": { "body":  "Brown fox" }}
            ]
        }
    }
}
```
但返回的结果：发现查询的结果是文档 1 的评分更高：
```
{
  "hits": [
     {
        "_id":      "1",
        "_score":   0.14809652,
        "_source": {
           "title": "Quick brown rabbits",
           "body":  "Brown rabbits are commonly seen."
        }
     },
     {
        "_id":      "2",
        "_score":   0.09256032,
        "_source": {
           "title": "Keeping pets healthy",
           "body":  "My quick brown fox eats rabbits on a regular basis."
        }
     }
  ]
}
```

#### 为了理解导致这样的原因， 需要回想一下 bool 是如何计算评分的：
##### 1、它会执行 should 语句中的两个查询。
##### 2、加和两个查询的评分。
##### 3、乘以匹配语句的总数。
##### 4、除以所有语句总数（这里为：2）。
##### 文档 1 的两个字段都包含 brown 这个词，所以两个 match 语句都能成功匹配并且有一个评分。文档 2 的 body 字段同时包含 brown 和 fox 这两个词，但 title 字段没有包含任何词。这样， body 查询结果中的高分，加上 title 查询中的 0 分，然后乘以二分之一，就得到比文档 1 更低的整体评分。

##### 在本例中， title 和 body 字段是相互竞争的关系，所以就需要找到单个 最佳匹配 的字段。
##### 如果不是简单将每个字段的评分结果加在一起，而是将 最佳匹配 字段的评分作为查询的整体评分，结果会怎样？这样返回的结果可能是： 同时 包含 brown 和 fox 的单个字段比反复出现相同词语的多个不同字段有更高的相关度

```
{
    "query": {
        "dis_max": {
            "queries": [
                { "match": { "title": "Brown fox" }},
                { "match": { "body":  "Brown fox" }}
            ]
        }
    }
}
```
#### 分离最大化查询（Disjunction Max Query）指的是： 将任何与任一查询匹配的文档作为结果返回，但只将最佳匹配的评分作为查询的评分结果返回 ：
```
{
  "hits": [
     {
        "_id":      "2",
        "_score":   0.21509302,
        "_source": {
           "title": "Keeping pets healthy",
           "body":  "My quick brown fox eats rabbits on a regular basis."
        }
     },
     {
        "_id":      "1",
        "_score":   0.12713557,
        "_source": {
           "title": "Quick brown rabbits",
           "body":  "Brown rabbits are commonly seen."
        }
     }
  ]
}
```

### 16、multi_match 查询
#### multi_match 查询为能在多个字段上反复执行相同查询提供了一种便捷方式
> multi_match 多匹配查询的类型有多种，其中的三种恰巧与 了解我们的数据 中介绍的三个场景对应，即： best_fields 、 most_fields 和 cross_fields （最佳字段、多数字段、跨字段）

##### 如下简单demo:
bool查询
```
{
  "query": {
    "bool": {
      "should": [
        { "match": { "street":    "Poland Street W1V" }},
        { "match": { "city":      "Poland Street W1V" }},
        { "match": { "country":   "Poland Street W1V" }},
        { "match": { "postcode":  "Poland Street W1V" }}
      ]
    }
  }
}
```
换成multi_match 查询
```
{
  "query": {
    "multi_match": {
      "query":       "Poland Street W1V",
      "type":        "most_fields",
      "fields":      [ "street", "city", "country", "postcode" ]
    }
  }
}
```

## 三、修改

### 1、直接修改
修改文档person id为1 的name属性为 '杰克'
```
POST http://192.168.12.137:9201/test/person/1/_update
{
    "doc":{
        "name":"杰克"
    }
}
```

### 2、脚本修改
```
POST http://192.168.12.137:9201/test/person/1/_update
{
	"script":{
		"lang":"painless",
		"inline":"ctx._source.age += 10"
	}
}

//或者这样的
POST http://192.168.12.137:9201/test/person/1/_update
{
	"script":{
		"lang":"painless",
		"inline":"ctx._source.age =params.age"
		"params":{
			"age":30
		}
	}
}
```


## 四、删除

### 1、删除索引
删除test 索引
```
DELETE http://192.168.12.137:9201/test
```

### 2、删除文档
id 为1 的数据
```
DELETE http://192.168.12.137:9201/test/person/1
```
### 3、通过条件删除数据
```
POST twitter/_delete_by_query
{
  "query": { 
    "match": {
      "message": "some message"
    }
  }
}
```
##### 我这个是5.6.4 版本的，具体的看文档：
##### https://www.elastic.co/guide/en/elasticsearch/reference/5.6/docs-delete-by-query.html#docs-delete-by-query

### 4、删除字段（field）
删除 person 文档里的field 字段
```
POST http://192.168.12.137:9201/test/person/_update
{
    "script":{
        "lang":"painless",
        "inline":"ctx._source.remove(\"field\")"
    }
}
```

## 五、mapping 映射
在创建索引的时候，可以预先定义字段的类型与相关属性，分为静态映射和动态映射
每个字段可添加的属性有：

|属性|说明|适用类型|
|--|--|--|
|store|可选值有：yes、no ,设为yes就是存储，no 不存储|all|
|index|可选值有：analyzed、not_analyzed、no ,analyzed--- 索引并分析，not_analyzed -- 索引但不分析，no ---不索引这个字段，这样就搜不到了。默认值是：analyzed |string ,其他类型只能设置 not_analyzed、no|
|null_value|当字段为空时，可以为它设置一个默认值：比如 "null_value":"NAN"|all|
|boost|字段的权重。默认值：1.0|all|
|index_analyzer|设置一个索引时用的分析器|all|
|search_analyzer|设置一个搜索时用的分析器|all|
|analyzer|可以设置索引和搜索时用到的分析器，默认使用 standard 分析器，除外，你还可以使用 whitespace、simple、english 这3个内置的分析器|all|
|include_in_all|它的作用是每个字段默认都搜索到，如果你不想让某个字段被搜索到，那么将这个字段设置为false 即可。默认值:true|all|
|index_name|定义字段的名称，默认值是字段本身的名字|all|
|norms|作用是根据各种规范化因素去计算权值，这样方便查询，在analyzed 定义字段里，值为true、not-analyzed 是 false。|all|

### 1、创建索引并配置映射
```
PUT http://192.168.12.137:9201/person
{
    "setting":{
        "number_of_shards":5,
        "number_of_replicas":1
    },
    "mappings":{
        "man":{
            "properties":{
                "name":{
                    "type":"string",
                    "index":"not_analyzed"
                },
                "age":{
                    "type":"integer"
                },
                "sex":{
                    "type":"string"
                },
                "money":{
                    "type":"double"
                }
            }
        }
    }
}
```

### 2、查看映射
```
GET http://192.168.12.137:9201/person/_mapping
```

### 3、删除映射
```
DELETE http://192.168.12.137:9201/person/man/_mapping
```



> 参考文献：[https://www.elastic.co/guide/cn/elasticsearch/guide/current/index.html](https://www.elastic.co/guide/cn/elasticsearch/guide/current/index.html)

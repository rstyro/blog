---
title: Elasticsearch7索引模板
date: 2020-09-23 09:37:38
tags: [ElasticSearch]
categories: 搜索引擎
---
### 前言
+ Elasticsearch环境:`7.9.0`版本

> 在`Elasticsearch 7.8`中引入的可组合索引模板。


### 一、索引模板的定义
索引模板是一种告诉Elasticsearch在创建索引时如何配置索引的方法。对于数据流，索引模板在创建流的后备索引时对其进行配置。在创建索引之前先配置模板，然后在手动创建索引或通过对文档建立索引创建索引时，模板设置将用作创建索引的基础。

模板有两种类型，索引模板和组件模板。组件模板是可重用的构建块，用于配置映射，设置和别名。您使用组件模板构造索引模板，但它们不会直接应用于一组索引。索引模板可以包含组件模板的集合，也可以直接指定设置，映射和别名。

### 二、索引模板的作用
 一般创建索引的时候都会进行字段配置分片配置分词配置等等，有些操作是重复的。比如建立多个索引但是分词分析器的配置是一样的，时间字段的格式化是一样的等等。
而模板就是把这些重复的操作抽出来，每次发现有重复的直接使用模板就行。就相当于我们写代码，遇到很多重复片段的代码就抽出一个方法。复用性比较好。

索引模板就是方便我们创建索引而产生的，Elasticsearch内置了`metrics-*-*`和`logs-*-*`索引模板，每个模板的优先级为100，主要是为了让`Elastic Agent`使用的。为防止模板被内置模板覆盖，建议自己的模板设置的优先级（`priority`）大于100。

比如要使用 `Rollover API` 的时候，还是配合模板使用的。

### 三、索引模板的使用
模板可分为索引模板和组件模板。先讲索引模板

#### 1、动态模板
创建索引的时候，可以指定`properties`、`settings`等其他之外还可以添加**动态模板(`dynamic_templates`)**。看看demo
```yml
# 创建topic索引的时候，添加动态模板
PUT http://172.16.1.236:9201/topic
{
    "settings": {
        "number_of_shards": 3,
        "number_of_replicas": 1
    },
    "mappings": {
        "dynamic_templates": [
            {
                "my_template_name": {
                    "match": "*num",
					"unmatch": "*_text",
                    "mapping": {
                        "type": "long"
                    }
                }
            },
            {
                "time_template": {
                    "match_mapping_type": "string",
                    "match": "*time",
                    "mapping": {
                        "type": "date",
                        "format": "yyyy-MM-dd HH:mm:ss || yyyy-MM-dd || epoch_millis"
                    }
                }
            },
            {
                "reg_template": {
                    "match_mapping_type": "string",
                    "match_pattern":"regex",
                    "match": ".*(status|id|type).*",
                    "mapping": {
                        "type": "keyword"
                    }
                }
            },
            {
                "text_template": {
                    "match_mapping_type": "string",
                    "match": "*",
                    "mapping": {
						"type": "text",
                        "analyzer": "ik_max_word",
                        "search_analyzer": "ik_smart",
                        "term_vector": "with_positions_offsets"
                    }
                }
            }
        ],
        "properties": {
            "is_del": {
                "type": "boolean"
            },
            "location": {
                "type": "geo_point",
                "ignore_malformed": "true"
            },
            "status": {
                "type": "short"
            }
        }
    }
}
```

字段解析：
```js
dynamic_templates  		// 一个数组，随便自定义匹配规则模板，数组里面对象是个json,key就是名称
match_mapping_type 		//检测数据类型，可以检测出boolean、long、string、double 等等
match    				//匹配通配符
unmatch  				//不匹配
match_pattern    		//正则匹配
path_match   			//和math 一样，只不过是对于对象类型的属性匹配
path_unmatch 			//和unmath 一样，只不过是对于对象类型的属性匹配，



// 解释动态模板意思

// my_template_name 字段名称匹配 “num”结尾，不匹配“_text”结尾的使用 long类型
// time_template    字段名称以“time”结尾的使用 date 类型并格式化
// reg_template     字段名称正则匹配 包含 “status、id、type”其中一个的使用 keyword类型
// text_template    上面都不匹配直接使用text 类型，并建立分词

// 文档地址：https://www.elastic.co/guide/en/elasticsearch/reference/7.9/dynamic-templates.html
```


#### 2、索引模板
这里分为两个，一个是新版的API,一个是旧版的API。先讲新版的。

##### 新版
简单的栗子：
```
PUT /_index_template/template_name
{
  "index_patterns" : ["te*"],
  "priority" : 1,
  "template": {
    "settings" : {
      "number_of_shards" : 2
    }
  }
}
```
请求体参数不止上面的几个，如下：

|参数|参数类型|是否必传|描述|
|--|:-:|:-:|--|
|index_patterns <div style="width:100px"></div>|字符串数组<div style="width:70px"></div>|是|通配符表达式数组，用于在创建过程中匹配数据流和索引的名称。|
|data_stream|对象|否|指示模板是否用于创建数据流及其支持索引|
|template|对象|否|应用的模板。它可任选地包括一个`aliases`，`mappings`或 `settings`配置，这些参数和创建索引的时候配置的一样|
|composed_of|字符串数组|否|组件模板名称的有序数组。组件模板按照指定的顺序合并，这意味着指定的最后一个组件模板具有最高优先级|
|priority|整数|否|确定索引模板优先级的优先级，如果未指定优先级，则将模板视为优先级为0（最低优先级）|
|version|整数|否|用于从外部管理索引模板的版本号，用户自定义|
|_meta|对象|否|有关索引模板的可选用户元数据，用户自定义|

**Index Template API**
+ **创建或更新一个名为 topic_template 索引模板**
```
PUT http://172.16.1.236:9201/_index_template/topic_template
{
    "index_patterns" : ["test*","topic*"],
    "template":{
        "settings": {
            "number_of_shards": 3,
            "number_of_replicas": 1
        },
        "mappings": {
            "dynamic_templates": [
                {
                    "time_template": {
                        "match_mapping_type": "string",
                        "match": "*num",
                        "mapping": {
                            "type": "long"
                        }
                    }
                },
                {
                    "time_template": {
                        "match_mapping_type": "string",
                        "match": "*time",
                        "mapping": {
                            "type": "date",
                            "format": "yyyy-MM-dd HH:mm:ss || yyyy-MM-dd || epoch_millis"
                        }
                    }
                },
                {
                    "id_template": {
                        "match_mapping_type": "string",
                        "match": "*id",
                        "mapping": {
                            "type": "keyword"
                        }
                    }
                },
                {
                    "text_template": {
                        "match_mapping_type": "string",
                        "match": "*",
                        "mapping": {
                            "analyzer": "ik_max_word",
                            "search_analyzer": "ik_smart",
                            "term_vector": "with_positions_offsets"
                        }
                    }
                }
            ],
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
                }
            }
        }
    },
    "priority": 200
}
```
这个模板创建成功之后，如果我们新建一个符合`index_patterns` 匹配规则的时候就会使用这个模板，
比如创建一个叫 “topic2” 的索引，如果我们没有定义字段，那它的字段如果符合模板字段就会应用模板的字段。（因为“topic2”匹配`index_patterns` 的`topic*`字符串）

+ **获取所有索引模板**
```
GET http://172.16.1.236:9201/_index_template
```

+ **索引模板`topic_template`是否存在**
```
# 返回200 代表存在，404 代表不存在
HEAD http://172.16.1.236:9201/_index_template/topic_template
```

+ **删除`topic_template`索引模板**
```
DELETE http://172.16.1.236:9201/_index_template/topic_template
```

+ [文档地址:https://www.elastic.co/guide/en/elasticsearch/reference/7.9/indices-put-template.html](https://www.elastic.co/guide/en/elasticsearch/reference/7.9/indices-put-template.html)

##### 旧版
和新版差不多
```
PUT _template/template_1
{
  "index_patterns": ["te*", "bar*"],
  "settings": {
    "number_of_shards": 1
  },
  "mappings": {
    "_source": {
      "enabled": false
    },
    "properties": {
      "host_name": {
        "type": "keyword"
      },
      "created_at": {
        "type": "date",
        "format": "EEE MMM dd HH:mm:ss Z yyyy"
      }
    }
  }
}
```
可以看到**请求路径不一样**，还要就是它没有优先级这个参数，但是**有`order`这个字段和优先级一样的作用。**
API 就是改前缀地址就行，如下：
```yml
# 添加模板
PUT _template/topic_template
{
  "index_patterns": ["te*", "bar*"],
  "settings": {
    "number_of_shards": 1
  },
  "mappings": {
    "_source": {
      "enabled": false
    },
    "properties": {
      "host_name": {
        "type": "keyword"
      },
      "created_at": {
        "type": "date",
        "format": "EEE MMM dd HH:mm:ss Z yyyy"
      }
    }
  }
}


# 获取所有索引模板
GET http://172.16.1.236:9201/_template


# 索引模板`topic_template`是否存在
# 返回200 代表存在，404 代表不存在
HEAD http://172.16.1.236:9201/_template/topic_template


# 删除`topic_template`索引模板
DELETE http://172.16.1.236:9201/_template/topic_template

```

**有兴趣可以看官方文档：[https://www.elastic.co/guide/en/elasticsearch/reference/7.9/indices-templates-v1.html](https://www.elastic.co/guide/en/elasticsearch/reference/7.9/indices-templates-v1.html)**


#### 3、组合模板
通俗点讲，组合模板就是把索引模板又拆成小部分，相当于方法里的方法一样。
她的参数和索引模板一样，只是请求的api变了。比如上面创建的索引模板，可以做成一个组件模板：
```yml
# 创建一个名为my_dynamic_template 的组合模板
PUT http://172.16.1.236:9201/_component_template/my_dynamic_template
{
    "template": {
        "mappings": {
            "dynamic_templates": [
                {
                    "time_template": {
                        "match_mapping_type": "string",
                        "match": "*num",
                        "mapping": {
                            "type": "long"
                        }
                    }
                },
                {
                    "time_template": {
                        "match_mapping_type": "string",
                        "match": "*time",
                        "mapping": {
                            "type": "date",
                            "format": "yyyy-MM-dd HH:mm:ss || yyyy-MM-dd || epoch_millis"
                        }
                    }
                },
                {
                    "id_template": {
                        "match_mapping_type": "string",
                        "match": "*id",
                        "mapping": {
                            "type": "keyword"
                        }
                    }
                },
                {
                    "text_template": {
                        "match_mapping_type": "string",
                        "match": "*",
                        "mapping": {
                            "analyzer": "ik_max_word",
                            "search_analyzer": "ik_smart",
                            "term_vector": "with_positions_offsets"
                        }
                    }
                }
            ]
        }
    }
}
```
或者把`settings` 配置做成一个组件
```yml
# 创建一个名为my_setting_template，只有 settings 属性的组合模板
PUT http://172.16.1.236:9201/_component_template/my_setting_template
{
  "template": {
    "settings": {
      "number_of_shards": 3,
      "number_of_replicas":1
    }
  }
}
```

使用她的时候只需要在创建模板的时候，使用：`composed_of` 参数即可：
```yml
# 创建索引，引用组合模板
PUT http://172.16.1.236:9201/_index_template/my_component_template
{
    "index_patterns" : ["index*","topic*"],
    "template":{
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
                "is_del": {
                    "type": "boolean"
                },
                "location": {
                    "type": "geo_point",
                    "ignore_malformed": "true"
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
                }
            }
        }
    },
    "priority": 201,
    "composed_of":["my_setting_template","my_dynamic_template"]
}
```

#### 4、查看所有模板API
```
# 返回所有模板信息，参数v 返回头部名称
GET http://172.16.1.236:9201/_cat/templates?v
```

**ok，最后放上官方文档：[https://www.elastic.co/guide/en/elasticsearch/reference/7.9/simulate-multi-component-templates.html](https://www.elastic.co/guide/en/elasticsearch/reference/7.9/simulate-multi-component-templates.html)**
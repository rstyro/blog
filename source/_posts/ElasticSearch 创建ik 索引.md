---
title: ElasticSearch 创建ik 索引
date: 2017-12-12 16:53:30
tags: [ElasticSearch]
categories: 其他
---
## 简单粗暴，代码如下
```

{
    "setting":{
        "number_of_shards":5,
        "number_of_replicas":1
    },
    "mappings":{
        "brain":{
            "properties":{
                "answer":{
                    "type":"text",
                    "analyzer":"ik_max_word",
					"search_analyzer":"ik_smart"
                },
                "question":{
                    "type":"text",
					"analyzer":"ik_max_word",
					"search_analyzer":"ik_smart"
                },
                "user_id":{
                    "type":"text"
                },
                "create_time":{
                    "type":"date",
                    "format":"yyyy-MM-dd HH:mm:ss || yyyy-MM-dd || epoch_millis"
                }
            }
        },
		"history":{
			"properties":{
				"question":{
					"type":"text",
					"analyzer":"ik_max_word",
					"search_analyzer":"ik_smart"
				},
				"user_id":{
					"type":"text"
				},
				"address":{
					"type":"text",
					"analyzer":"ik_max_word",
					"search_analyzer":"ik_smart"
				},
				"is_read":{
					"type":"text"
				},
				"create_time":{
					"type":"date",
					"format":"yyyy-MM-dd HH:mm:ss || yyyy-MM-dd || epoch_millis"
				}
			}
			
		}
    }
}
```
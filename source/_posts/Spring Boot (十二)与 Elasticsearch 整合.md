---
title: Spring Boot (十二)与 Elasticsearch 整合
date: 2017-12-02 22:54:20
tags: [ElasticSearch, Spring Boot]
categories: Java
---
# Springboot 与 elasticsearch 整合demo
springboot 整合elasticsearch5.6.4 版本的
## 一、pom.xml
pom.xml 主要片段
```
<properties>
	<project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
	<project.reporting.outputEncoding>UTF-8</project.reporting.outputEncoding>
	<java.version>1.8</java.version>
	<elasticsearch.version>5.6.4</elasticsearch.version>
</properties>

<!-- 接口注解需要用到 -->
 <dependency>
	<groupId>org.springframework.boot</groupId>
	<artifactId>spring-boot-starter-web</artifactId>
</dependency>
<!-- 重要 -->
<dependency>
	<groupId>org.elasticsearch.client</groupId>
	<artifactId>transport</artifactId>
	<version>${elasticsearch.version}</version>
</dependency>
<!-- 需要 -->
<dependency>
	<groupId>org.apache.logging.log4j</groupId>
	<artifactId>log4j-core</artifactId>
</dependency>

```
## 二、application.properties 内容
```
# 你集群的名字
elasticsearch.cluster.name=people
# 地址，多个用逗号隔开，注意端口，9300 是transportService 的端口。
elasticsearch.host=127.0.0.1:9300,127.0.0.1:9301

```


## 三、自定义Elasticsearch 配置类
这个配置类是为了获取TransportClient 
```
package top.lrshuai.es.config;

import org.elasticsearch.client.transport.TransportClient;
import org.elasticsearch.common.settings.Settings;
import org.elasticsearch.common.transport.InetSocketTransportAddress;
import org.elasticsearch.transport.client.PreBuiltTransportClient;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.net.InetAddress;
import java.net.UnknownHostException;

@Configuration
public class ElasticsearchConfig {

	@Value("${elasticsearch.cluster.name}")
	private String clusterName;

	@Value("${elasticsearch.host}")
	private String host;

	@Bean
	public TransportClient transportClient() throws UnknownHostException {
		// 设置集群名称
		Settings settings = Settings.builder().put("cluster.name", clusterName)
				.build();
		TransportClient transportClient = new PreBuiltTransportClient(settings);
		String[] nodes = host.split(",");
		for (String node : nodes) {
			if (node.length() > 0) {
				String[] hostPort = node.split(":");
				transportClient.addTransportAddress(
						new InetSocketTransportAddress(
						InetAddress.getByName(hostPort[0]),
						Integer.parseInt(hostPort[1])));
			}
		}
		return transportClient;
	}

}

```

## 四、自定义查询的接口与实现
下面是我的一个例子，可以参考下，然后按照自己的需求定制查询接口
#### 1、PersonDao 接口
```
package top.lrshuai.es.dao;


import top.lrshuai.es.entity.Person;

public interface PersonDao {
	public String save(Person person);
	public String update(Person person);
	public String deltele(String id);
	public Object find(String id);
	public Object query(Person person);
}

```
#### 2、PersonDaoImpl 接口的实现类
```
package top.lrshuai.es.dao.impl;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutionException;

import org.apache.log4j.Logger;
import org.elasticsearch.action.delete.DeleteResponse;
import org.elasticsearch.action.get.GetResponse;
import org.elasticsearch.action.index.IndexResponse;
import org.elasticsearch.action.search.SearchRequestBuilder;
import org.elasticsearch.action.search.SearchResponse;
import org.elasticsearch.action.search.SearchType;
import org.elasticsearch.action.update.UpdateRequest;
import org.elasticsearch.action.update.UpdateResponse;
import org.elasticsearch.client.transport.TransportClient;
import org.elasticsearch.common.xcontent.XContentBuilder;
import org.elasticsearch.common.xcontent.XContentFactory;
import org.elasticsearch.index.query.BoolQueryBuilder;
import org.elasticsearch.index.query.QueryBuilders;
import org.elasticsearch.index.query.RangeQueryBuilder;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import top.lrshuai.es.dao.PersonDao;
import top.lrshuai.es.entity.Person;

@Component
public class PersonDaoImpl implements PersonDao{

	@Autowired
    private TransportClient transportClient;
	
	private Logger log = Logger.getLogger(getClass());
	//索引名称（数据库名）
	private String index = "test";
	
	//类型名称（表名）
	private String type = "person";
	
	/**
	 * 保存
	 */
	@Override
	public String save(Person person) {
		 try {
			 XContentBuilder builder = XContentFactory.jsonBuilder().startObject();
			builder.field("name", person.getName());
			builder.field("age", person.getAge());
			builder.field("sex", person.getSex());
			builder.field("birthday", person.getBirthday());
			builder.field("introduce", person.getIntroduce());
			builder.endObject();
			IndexResponse response = this.transportClient.prepareIndex(index, type)
					.setSource(builder).get();
			return response.getId();
		} catch (IOException e) {
			e.printStackTrace();
			log.error(e.getMessage(), e);
		}
		return null;
	}
	
	/**
	 * 更新
	 */
	@Override
	public String update(Person person) {
		UpdateRequest request = new UpdateRequest(index, type, person.getId());
        try {
            XContentBuilder builder = XContentFactory.jsonBuilder().startObject();
            if (person.getName() != null) {
                builder.field("name", person.getName());
            }
            if (person.getSex() != null) {
            	builder.field("sex", person.getSex());
            }
            if (person.getIntroduce() != null) {
            	builder.field("introduce", person.getIntroduce());
            }
            if (person.getBirthday() != null) {
            	builder.field("birthday", person.getBirthday());
            }
            if (person.getAge() > 0) {
            	builder.field("age", person.getAge());
            }
            builder.endObject();
            request.doc(builder);
            UpdateResponse response = transportClient.update(request).get();
            return response.getId();
        } catch (IOException | InterruptedException | ExecutionException e) {
            log.error(e.getMessage(), e);
        }
        return null;
	}
	
	@Override
	public String deltele(String id) {
		DeleteResponse response = transportClient.prepareDelete(index, type, id).get();
		return response.getId();
	}
	
	@Override
	public Object find(String id) {
		GetResponse response =transportClient.prepareGet(index, type, id).get();
		System.out.println("response="+response);
		Map<String, Object> result = response.getSource();
		if(result != null) {
			result.put("_id", response.getId());
		}
		return result;
	}
	
	@Override
	public Object query(Person person) {
		List<Map<String,Object>> result =  new ArrayList<>();;
		try {
			 BoolQueryBuilder boolBuilder = QueryBuilders.boolQuery();
	        if (person.getName() != null) {
//	            boolBuilder.must(QueryBuilders.matchQuery("name", person.getName()));
	            boolBuilder.should(QueryBuilders.matchQuery("name", person.getName()));
	        }
	        if (person.getIntroduce() != null) {
//	            boolBuilder.must(QueryBuilders.matchQuery("introduce", person.getIntroduce()));
	            boolBuilder.should(QueryBuilders.matchQuery("introduce", person.getIntroduce()));
	        }
	        
	        //range 查询范围，大于age,小于age+10
	        if(person.getAge() > 0) {
	        	RangeQueryBuilder rangeQuery = QueryBuilders.rangeQuery("age");
	        	rangeQuery.from(person.getAge());
	        	rangeQuery.to(person.getAge()+10);
	        	boolBuilder.filter(rangeQuery);
	        }
	        SearchRequestBuilder builder = transportClient.prepareSearch(index)
	                    .setTypes(type)
	                    .setSearchType(SearchType.QUERY_THEN_FETCH)
	                    .setQuery(boolBuilder)
	                    .setFrom(0)
	                    .setSize(10);
			// 高亮
			//HighlightBuilder hBuilder = new HighlightBuilder();
			//hBuilder.preTags("<h2>");
			//hBuilder.postTags("</h2>");	
			//hBuilder.field("question"); 
			//高亮的字段
			//builder.highlighter(hBuilder);
	        log.info(String.valueOf(builder));
	        SearchResponse response = builder.get();
	        response.getHits().forEach((s)->result.add(s.getSource()));
		} catch (Exception e) {
			e.printStackTrace();
			log.error(e.getMessage(), e);
		}
		return result;
	}
	
}

```

## 五测试类
```
package top.lrshuai.es;

import java.util.Date;

import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.junit4.SpringRunner;

import top.lrshuai.es.entity.Person;
import top.lrshuai.es.service.PersonService;

@RunWith(SpringRunner.class)
@SpringBootTest
public class ApplicationTests {

	@Autowired
	private PersonService personService;
	
	@Test
	public void testSavePerson() {
		String name = "帅大叔";
		String introduce = "宇宙超级无敌帅";
		Person person = new Person(name, 23, "男", new Date(), introduce);
		System.out.println(personService.savePerson(person));
	}
	
	@Test
	public void testUpdatePerson() {
		String name = "靓女";
		int age = 24;
		String sex = "女";
		String introduce = "这是一个非常非常非常非常漂亮的女孩。";
		Date birthday = new Date();
		Person person = new Person(name, age, sex, birthday, introduce);
		person.setId("mjupFmABhhkOZSWoch9i");
		personService.updatePerson(person);
	}
	
	@Test
	public void testFindPerson() {
		String id = "mjupFmABhhkOZSWoch9i";
		System.out.println(personService.findPerson(id));
	}
	
	@Test
	public void testDelPerson() {
		String id = "mjupFmABhhkOZSWoch9i";
		System.out.println(personService.delPerson(id));
	}
	
	@Test
	public void testQueryPerson() {
		Person person = new Person();
		person.setName("帅");
		person.setIntroduce("人");
//		person.setAge(27);
		Object obj  = personService.queryPerson(person);
		System.out.println(obj);
	}

}

```

## 示例代码：[Github](https://github.com/rstyro/spring-boot/tree/master/springboot-elasticsearch)

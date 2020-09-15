---
title: Elasticsearch7使用详解
date: 2020-09-10 18:57:27
tags: [ElasticSearch]
categories: 搜索引擎
---
### 一、前言
Elasticsearch是一个基于Lucene的搜索服务器。它提供了一个分布式多用户能力的全文搜索引擎，基于RESTful web接口。Elasticsearch是用Java语言开发的，并作为Apache许可条款下的开放源码发布，是一种流行的企业级搜索引擎。
在全文检索领域， Lucene可谓是独领风骚数十年。倒排索引构成全文检索的根基。

> 本篇不研究底层，只介绍用法

### 二、Elasticsearch7与Mysql的对比

|Elasticsearch5|MYSQL|说明|
|--|--|--|
|Index|databases|ES的索引对应MYSQL的是一个数据库|
|type|table|ES的类型对应MYSQL的表|
|Documents |Rows |ES的文档对应MYSQL的一条数据|

Elasticsearch有点长，下文直接简称ES。

ES7这个版本在创建mapping的时候不能指定type了，对应映射改成如下：

|Elasticsearch7.9|MYSQL|说明|
|--|--|--|
|Index|table|ES的索引对应MYSQL的表|
|Documents |Rows |ES的文档对应MYSQL的一条数据|

去掉type,每个索引相当与MYSQL这种关系型数据库的表，索引之下就是属性了，对应着表的字段。
虽然创建的时候没有指定type,但是查看索引信息的时候，发现她变成了`_doc`(可能是为了和之前的版本兼容？),ES8版本就应该是删除了，看官方文档：
[https://www.elastic.co/guide/en/elasticsearch/reference/current/removal-of-types.html#_schedule_for_removal_of_mapping_types](https://www.elastic.co/guide/en/elasticsearch/reference/current/removal-of-types.html#_schedule_for_removal_of_mapping_types)

**怎么安装配置ES就不说了之前文章有：[ES系列文章](https://rstyro.github.io/blog/tags/ElasticSearch/)**

### 三、索引
就我的理解，ES7的索引就类似于传统关系数据库中的表了。索引 (index) 的复数词为 indices 或 indexes 。
索引**常用**的配置如下：
```
// 分片个数
number_of_shards:5

// 分片副本，副本分片数的最大值是 n -1（其中 n 为节点数，因为分片的副本不能分配到相同的节点）
number_of_replicas:0

//多久执行一次刷新操作，使搜索到的索引最近更改可见。默认为1s。可以设置-1为禁用刷新
refresh_interval:10s

//控制单次查询返回的最大结果数
max_result_window:20000   
```

### 四、Mappings
mappings 就我的理解就是相当于传统关系数据库的表字段设计。就是字段的映射关系。
常用类型有：
```
text			非结构化文本，默认会进行分词，支持模糊查询
keyword			这个字段好像是从text拆分出来的，不进行分词
constant_keyword	常量关键字是的关键字字段的专用化,索引中所有文档的值都相同的情况
boolean			布尔值，true 或false
date			日期类型
date_nanos		日期类型，精确到纳秒
long			数字类型，一个有符号的64位整数，最小值为-2的63次方，最大值为2的63次方-1
double			双精度
integer			int  最小值为-2的3次方，最大值为2的31次方-1
short			取值范围-32768到 32768
byte			取值范围-128 127
object			对象类型 JSON object.
nested			对象类型，和object 的区别，它允许以可以查询的方式对对象数组进行索引 
join			在相同索引下定义父子关系
geo_point		经纬度坐标

...等等，文档地址：https://www.elastic.co/guide/en/elasticsearch/reference/current/mapping-types.html
```
Mappings常用的设置参数：
```
properties	定义属性
analyzer	只有text才有的参数属性：文本分析器
search_analyzer	搜索分词器
boost		权重，在5.0.0 已弃用
coerce		强制转型，如果你是integer类型，当设置了coerce=false,那你传一个字符串类型的数字（"10"）就会失败
dynamic		是否可以动态添加类型，默认true
format		格式化，日期之类的：epoch_millis、date_optional_time 、strict_date_optional_time
index		是否对字段简历索引，默认true
term_vector	向量，如果使用高亮搜索类型为fvh ，则需要配置这个。配置这个
```

### 五、API
直接用`5.6.*版本`写过一篇笔记，虽然和现在`7.9.*`有点不同,我就不重复写了,笔记链接：
+ [Github挂载 ElasticSearch CURL](https://rstyro.github.io/blog/2017/12/01/ElasticSearch%20CURL/)
+ [Gitee挂载 ElasticSearch CURL](https://rstyro.gitee.io/blog/2017/12/01/ElasticSearch%20CURL/)

#### 1、创建索引
索引有点区别，因为type没有了
```
PUT http://172.16.1.236:9200/topic

{
	"settings":{
		"number_of_shards":5,
		"number_of_replicas":0
	},
    "mappings":{
        "properties":{
            "id":{
                "type":"keyword"
            },
			"user_id":{
                "type":"long"
            },
			"title":{
                "type":"keyword"
            },
			"content":{
                "type":"text",
                "analyzer":"ik_max_word",
                "search_analyzer":"ik_smart",
                "term_vector":"with_positions_offsets"
            },
			"is_del":{
                "type":"boolean"
            },
			"update_time":{
                "type":"date",
                "format":"yyyy-MM-dd HH:mm:ss || yyyy-MM-dd || epoch_millis"
            },
            "create_time":{
                "type":"date",
                "format":"yyyy-MM-dd HH:mm:ss || yyyy-MM-dd || epoch_millis"
            }
        }
    }
}
```

"term_vector":"with_positions_offsets" 这个属性是为了高亮能用fvh(`fast-vector-highlighter`)显示类型

#### 2、操作mapping
```
# 给索引添加 location 定位属性
PUT http://172.16.1.236:9200/topic/_mapping
{
    "properties":{
        "location":{
            "type":"geo_point"
        }
    }
}

# topic查看mapping
GET http://172.16.1.236:9200/topic/_mapping

# es 获取mapping单个content属性的信息
GET http://172.16.1.236:9200/topic/_mapping/field/content
```

mapping 字段无法修改类型

#### 3、添加数据
```
# 指定ID：0ab92409ea7843c89983ada5f7bc2524 添加数据
PUT http://172.16.1.236:9200/topic/_create/0ab92409ea7843c89983ada5f7bc2524
{
    "content": "测试内容之-虽然我走得很慢,但我从不后退!",
    "create_time": "2020-09-10 14:20:31",
    "id": "0ab92409ea7843c89983ada5f7bc2524",
    "is_del": false,
    "location": "22.541144,113.952953",
    "status": 1,
    "title": "测试标题",
    "update_time": "2020-09-10 14:20:31",
    "user_id": 1
}

# 指定ID：0ab92409ea7843c89983ada5f7bc2524 添加数据
POST http://172.16.1.236:9200/topic/_doc/0ab92409ea7843c89983ada5f7bc2524
{
    "content": "测试内容之-虽然我走得很慢,但我从不后退!",
    "create_time": "2020-09-10 14:20:31",
    "id": "0ab92409ea7843c89983ada5f7bc2524",
    "is_del": false,
    "location": "22.541144,113.952953",
    "status": 1,
    "title": "测试标题",
    "update_time": "2020-09-10 14:20:31",
    "user_id": 1
}

# 随机ID生成数据
POST http://172.16.1.236:9200/topic/_doc
{
    "content": "测试内容之-虽然我走得很慢,但我从不后退!",
    "create_time": "2020-09-10 14:20:31",
    "id": "0ab92409ea7843c89983ada5f7bc2524",
    "is_del": false,
    "location": "22.541144,113.952953",
    "status": 1,
    "title": "测试标题",
    "update_time": "2020-09-10 14:20:31",
    "user_id": 1
}
```
#### 4、更新数据
```
# 修改title为：“测试更新”，status为2
POST http://172.16.1.236:9200/topic/_doc/450b4fd5e65f4004a4a96149e50d9e8b/_update
{
    "doc":{
        "title":"测试更新",
        "status":2
    }
}
```

#### 5、删除数据
```
# 删除指定ID：450b4fd5e65f4004a4a96149e50d9e8b
DELETE http://172.16.1.236:9200/topic/_doc/450b4fd5e65f4004a4a96149e50d9e8b

# 模糊删除
POST http://172.16.1.236:9200/topic/_delete_by_query
{
    "query":{
        "match":{
            "content":"测试"
        }
    }
}
```

#### 6、查询数据
```
# 查询所有数据
GET http://172.16.1.236:9200/topic/_search
{
	"query":{
		"match_all":{}
	}
}


# 分页查询所有数据
GET http://172.16.1.236:9200/topic/_search
{
	"query":{
		"match_all":{}
	},
    "from":1,
	"size":2
}


# 高亮搜索
GET http://172.16.1.236:9200/topic/_search
{
    "query" : { "match" : { "content" : "测试" }},
    "highlight" : {
        "pre_tags" : ["<tag1>", "<tag2>"],
        "post_tags" : ["</tag1>", "</tag2>"],
        "fields" : {
            "content" : {}
        }
    }
}


# 高亮搜索加排序与分页
GET http://172.16.1.236:9200/topic/_search
{
    "from": 0,
    "size": 3,
    "timeout": "60s",
    "query": {
        "match": {
            "content": {
                "query": "测试"
            }
        }
    },
    "sort": [
        {
            "_score": {
                "order": "desc"
            }
        },
        {
            "create_time": {
                "order": "desc"
            }
        }
    ],
    "highlight": {
        "fields": {
            "content": {
                "pre_tags": [
                    "<em1>",
                    "<em2>"
                ],
                "post_tags": [
                    "</em1>",
                    "</em2>"
                ],
                "type": "plain"
            }
        }
    }
}


# 经纬度圆点范围2km查询
GET http://172.16.1.236:9200/topic/_search
{
  "query": {
    "geo_distance": { 
      "distance": "2km",
       "location": { 
            "lat": 22.54, 
            "lon": 113.95
        }
    }
  }
}
```

#### 7、节点信息查询
```
# 查询集群设置
GET http://172.16.1.236:9200/_cluster/settings

# 查询节点状态
GET http://172.16.1.236:9200/_cat/health?v

# 查询节点信息
GET http://172.16.1.236:9200/_cluster/health?wait_for_status=yellow&timeout=50s

# 查询节点路由
POST http://172.16.1.236:9200/_cluster/reroute

# 查询节点 PROCESS
http://172.16.1.236:9200/_nodes/process

```
### 六、Java API
关键一环代码调用，Java 代码有3个客户端可以使用：
+ TransportClient 
这个使用的是ES的`transport.tcp.port` 端口进行传输数据。**在ES`7.0.0`弃用，到`8.0.0`将删除**
+ Java Low Level REST Client 
Rest低级别客户端，使用的是ES的`http.port`端口进行传输数据。
+ Java High  Level REST Client 
Rest高级别客户端，使用的是ES的`http.port`端口进行传输数据。
和上面`Java Low Level REST Client`的区别就是，在其基础上封装了一层.
可以理解为；
	`Java Low Level REST Client`相当与面向过程
	`Java High  Level REST Client`相当与面向对象

**既然TransportClient即将删除，那就用 RestHighLevelClient 了**

#### 1、导入依赖
```
 <dependency>
	<groupId>org.elasticsearch.client</groupId>
	<artifactId>elasticsearch-rest-high-level-client</artifactId>
	<version>7.9.0</version>
</dependency>

<dependency>
	<groupId>org.apache.logging.log4j</groupId>
	<artifactId>log4j-core</artifactId>
	<version>2.11.1</version>
</dependency>

<dependency>
	<groupId>org.apache.logging.log4j</groupId>
	<artifactId>log4j-to-slf4j</artifactId>
	<version>2.11.1</version>
</dependency>

<dependency>
	<groupId>com.alibaba</groupId>
	<artifactId>fastjson</artifactId>
	<version>1.2.73</version>
</dependency>
```

#### 2、配置RestHighLevelClient
RestHighLevelClient 就是高级别客户端。

```
import com.jfinal.kit.Prop;
import com.jfinal.kit.PropKit;
import org.apache.http.HttpHost;
import org.apache.http.auth.AuthScope;
import org.apache.http.auth.UsernamePasswordCredentials;
import org.apache.http.client.CredentialsProvider;
import org.apache.http.client.config.RequestConfig;
import org.apache.http.impl.client.BasicCredentialsProvider;
import org.elasticsearch.client.RestClient;
import org.elasticsearch.client.RestClientBuilder;
import org.elasticsearch.client.RestHighLevelClient;

import java.io.IOException;
import java.util.Arrays;
import java.util.Objects;

public class EsClientConfig {
    /**
     * elasticsearch 连接地址多个地址使用,分隔
     */
    private static String hosts;
    private static String username;
    private static String password;

    /**
     * 连接目标url最大超时
     */
    private static Integer connectTimeOut;

    /**
     * 等待响应（读数据）最大超时
     */
    private static Integer socketTimeOut;

    /**
     * 从连接池中获取可用连接最大超时时间
     */
    private static Integer connectionRequestTime;

    static {
        Prop prop = PropKit.use("jboot.properties");
        hosts=prop.get("elasticsearch.hosts");
        username=prop.get("elasticsearch.username");
        password=prop.get("elasticsearch.password");
        connectTimeOut=prop.getInt("elasticsearch.client.connectTimeOut");
        socketTimeOut=prop.getInt("elasticsearch.client.socketTimeOut");
        connectionRequestTime=prop.getInt("elasticsearch.client.connectionRequestTime");
    }

    private static RestHighLevelClient restHighLevelClient;

    private EsConfig(){}

    public static RestHighLevelClient getInstance(){
        if(restHighLevelClient==null){
            synchronized (EsConfig.class){
                if(restHighLevelClient == null){
                    restHighLevelClient=buildRestHighLevelClient();
                }
            }
        }
        return restHighLevelClient;
    }

    /**
     * 构建RestHighLevelClient
     * @return
     */
    private static RestHighLevelClient buildRestHighLevelClient() {
        final CredentialsProvider credentialsProvider = new BasicCredentialsProvider();
        credentialsProvider.setCredentials(AuthScope.ANY, new UsernamePasswordCredentials(username, password));
        HttpHost[] httpHosts = Arrays.stream(hosts.split(",")).map(host -> new HttpHost(host.split(":")[0], Integer.parseInt(host.split(":")[1]))).filter(Objects::nonNull).toArray(HttpHost[]::new);
        RestClientBuilder builder = RestClient.builder(httpHosts)
                .setHttpClientConfigCallback(httpClientBuilder -> {
                    RequestConfig.Builder requestConfigBuilder = RequestConfig.custom()
                            .setConnectTimeout(connectTimeOut)
                            .setSocketTimeout(socketTimeOut)
                            .setConnectionRequestTimeout(connectionRequestTime);
                    httpClientBuilder.setDefaultRequestConfig(requestConfigBuilder.build());
                    httpClientBuilder.setDefaultCredentialsProvider(credentialsProvider);
                    return httpClientBuilder;
                });
        return new RestHighLevelClient(builder);
    }

    /**
     * 释放资源
     * @throws IOException
     */
    public static void release() throws IOException {
        if(restHighLevelClient!=null)restHighLevelClient.close();
    }

}
```
因为我没有使用Spring框架所有自己搞了个单例模式的Client,如果是Spring直接使用在方法上使用`@Bean`注解即可，贼方便。

#### 3、辅助工具类
贴完整点的代码吧
##### EsUtils 工具类
```
public class EsUtils {

    private static Pattern humpPattern = Pattern.compile("[A-Z]");

    /**
     * 下划线转驼峰
     * @param str
     * @return
     */
    public static String humpToLine(String str) {
        Matcher matcher = humpPattern.matcher(str);
        StringBuffer sb = new StringBuffer();
        while (matcher.find()) {
            matcher.appendReplacement(sb, "_" + matcher.group(0).toLowerCase());
        }
        matcher.appendTail(sb);
        return sb.toString();
    }

    /**
     * 原字符是否包含 指定字符(不区分大小写)
     * @param srcStr 原字符
     * @param tags 目标数组
     * @return
     */
    public static boolean isCludeCharByOr(String srcStr,String... tags){
        if(tags != null && tags.length>0){
            for(String str:tags){
                if(isEmpty(str))continue;
                if(srcStr.toLowerCase().contains(str))return true;
            }
        }
        return false;
    }

	/**
     * 对象生成properties 属性map
     * 下面的else if 判断还有很多，懒得写，根据自己的需求完善吧
     * @param t
     * @return
     */
    public static Map<String,Object> getProperties(Object t){
        Map<String,Object> propertiesMap = new HashMap<>();
        if(t != null){
            Class<? extends Object> tClass = t.getClass();
            //得到所有属性
            Field[] fields = tClass.getDeclaredFields();
            if(fields!=null&& fields.length>0){
                for(Field field:fields){
                    String fieldClassStr = field.getGenericType().toString();
                    Map<String,Object> fieldAttrMap = new HashMap<>();
                    if("class java.lang.Long".equals(fieldClassStr)){
                        fieldAttrMap.put("type","long");
                    }else if("class java.lang.Double".equals(fieldClassStr)){
                        fieldAttrMap.put("type","double");
                    }else if("class java.time.LocalDateTime".equals(fieldClassStr) || "class java.util.Date".equals(fieldClassStr) || "class java.time.LocalDate".equals(fieldClassStr)){
                        fieldAttrMap.put("type","date");
                        fieldAttrMap.put("format","yyyy-MM-dd HH:mm:ss || yyyy-MM-dd'T'HH:mm:ss.SSS || yyyy-MM-dd || epoch_millis");
                    }else if("class java.lang.Boolean".equals(fieldClassStr)){
                        fieldAttrMap.put("type","boolean");
                    }else if("class java.lang.String".equals(fieldClassStr) && EsUtils.isCludeCharByOr(field.getName(),"id,type,state,status".split(","))){
                        fieldAttrMap.put("type","keyword");//keyword：存储数据时候，不会分词建立索引，支持模糊、支持精确匹配，支持聚合、排序操作
                    }else{
                        fieldAttrMap.put("type","text");//分词建立索引
                        fieldAttrMap.put("analyzer", "ik_max_word");
                        fieldAttrMap.put("search_analyzer", "ik_smart");
                    }
                    propertiesMap.put(EsUtils.humpToLine(field.getName()),fieldAttrMap);
                }
            }

        }
        return propertiesMap;
    }

    /**
     * 判空
     * @param str
     * @return
     */
    public static boolean isEmpty(String str){
        return str == null || "".equals(str);
    }

}
```
##### 对象属性名称驼峰与下划线互转序列化类
fastjson 序列化类
```
/**
 * 驼峰序列化配置
 *  https://github.com/alibaba/fastjson/wiki/PropertyNamingStrategy_cn
 *  String text = JSON.toJSONString(model, serializeConfig);
 *  Model model2 = JSON.parseObject(text, Model.class, parserConfig);
 */
public class FastJsonHumpSerialize {

    private static SerializeConfig serializeConfig;
    private static ParserConfig parserConfig;

    public static SerializeConfig getSerializeConfig() {
        if(serializeConfig==null){
            synchronized (FastJsonHumpSerialize.class){
                if(serializeConfig==null){
                    serializeConfig=new SerializeConfig();
                    serializeConfig.propertyNamingStrategy = PropertyNamingStrategy.SnakeCase;
                }
            }
        }
        return serializeConfig;
    }

    public static ParserConfig getParserConfig() {
        if(parserConfig==null){
            synchronized (FastJsonHumpSerialize.class){
                if(parserConfig==null){
                    parserConfig=new ParserConfig();
                    parserConfig.propertyNamingStrategy = PropertyNamingStrategy.SnakeCase;
                }
            }
        }
        return parserConfig;
    }
}
```
这个序列化类主要是想把对象的属性名称驼峰与下划线互转。
**如果你没有这个需求那可以不需要这个，直接存的就是属性名的字段。**

#### 4、抽象的增删改查类
主要写了一些平常可能用到的方法，还有很多查询没写，
```
/**
 * 操作ES 基础类
 * @since 2020-08-28
 * @author lrs
 */
public abstract class BaseEsService<T> {
    public Logger log = LoggerFactory.getLogger(this.getClass());
    /**
     * 索引名称
     */
    private String indexName;
    private BaseEsService(){}

    protected BaseEsService(String indexName) {
        this.indexName = indexName;
    }

    private RestHighLevelClient restHighLevelClient = EsClientConfig.getInstance();

    /**
     * 创建索引
     */
    public boolean createIndex(T t) throws IOException {
        CreateIndexRequest request = new CreateIndexRequest(indexName);
        request.settings(Settings.builder()
                .put("index.number_of_shards", 5) // 分片
                //副本,单机相同shard不允许同时分配到一个节点上，单机的话0,以副本分片数的最大值是 n -1（其中 n 为节点数）。
                .put("index.number_of_replicas", 0)
                .put("refresh_interval", "10s")
        );
        Map<String, Object> properties = EsUtils.getProperties(t);
        Map<String, Object> mapping = new HashMap<>();
        mapping.put("properties", properties);
        request.mapping(mapping);
        CreateIndexResponse createIndexResponse = restHighLevelClient.indices().create(request, RequestOptions.DEFAULT);
        return createIndexResponse.isAcknowledged();
    }

    /**
     * 删除索引
     *
     * @return
     */
    public boolean delIndex() throws IOException {
        if (existsIndex()) {
            DeleteIndexRequest request = new DeleteIndexRequest(indexName);
            AcknowledgedResponse deleteIndexResponse = restHighLevelClient.indices().delete(request, RequestOptions.DEFAULT);
            return deleteIndexResponse.isAcknowledged();
        }
        return true;
    }

    /**
     * 判断索引是否存在
     *
     * @return
     */
    public boolean existsIndex() throws IOException {
        GetIndexRequest request = new GetIndexRequest(indexName);
        return restHighLevelClient.indices().exists(request, RequestOptions.DEFAULT);
    }

    /**
     * 添加文档
     *
     * @param id
     * @param data
     * @return
     */
    public boolean saveDoc(String id, T data) throws IOException {
        IndexRequest indexRequest = new IndexRequest(indexName).id(id).source(JSON.toJSONString(data, FastJsonHumpSerialize.getSerializeConfig()), XContentType.JSON);
        indexRequest.opType(DocWriteRequest.OpType.CREATE);
        restHighLevelClient.index(indexRequest, RequestOptions.DEFAULT);
        return true;
    }

    /**
     * 批量新增
     *
     * @param list
     * @return
     * @throws IOException
     */
    public boolean batchSaveDoc(List<T> list) throws IOException {
        if (list == null || list.size() < 1) return false;
        BulkRequest request = new BulkRequest();
        for (T t : list) {
            IndexRequest indexRequest = new IndexRequest(indexName).id(getTId(t)).source(JSON.toJSONString(t, FastJsonHumpSerialize.getSerializeConfig()), XContentType.JSON);
            request.add(indexRequest);
        }
        BulkResponse bulk = restHighLevelClient.bulk(request, RequestOptions.DEFAULT);
        return !bulk.hasFailures();
    }

    public boolean saveDocByMap(String id, Map<String, Object> docMap) throws IOException {
        IndexRequest indexRequest = new IndexRequest(indexName).id(id).source(docMap);
        indexRequest.opType(DocWriteRequest.OpType.CREATE);
        restHighLevelClient.index(indexRequest, RequestOptions.DEFAULT);
        return true;
    }

    /**
     * 判断文档是否存在
     *
     * @param id
     * @return
     */
    public boolean existsDoc(String id) throws IOException {
        GetRequest request = new GetRequest(indexName, id);
        request.fetchSourceContext(new FetchSourceContext(false));
        request.storedFields("_none_");
        return restHighLevelClient.exists(request, RequestOptions.DEFAULT);
    }

    /**
     * 删除文档
     *
     * @param id
     * @return
     */
    public boolean delDocById(String id) throws IOException {
        DeleteResponse delete = restHighLevelClient.delete(new DeleteRequest(indexName, id), RequestOptions.DEFAULT);
        return DocWriteResponse.Result.DELETED.equals(delete.getResult());
    }

    /**
     * 批量删除文档
     *
     * @param ids id数组
     * @return
     * @throws IOException
     */
    public boolean batchDelDocById(String... ids) throws IOException {
        BulkRequest bulkRequest = new BulkRequest();
        if (ids != null && ids.length > 0) {
            for (String id : ids) {
                if (id == null || "".equals(id.trim())) continue;
                bulkRequest.add(new DeleteRequest(indexName, id));
            }
            BulkResponse bulk = restHighLevelClient.bulk(bulkRequest, RequestOptions.DEFAULT);
            return !bulk.hasFailures();
        }
        return false;
    }

    /**
     * 更新文档
     *
     * @param id
     * @param data
     * @return
     */
    public boolean updateDocById(String id, T data) throws IOException {
        UpdateRequest request = new UpdateRequest(indexName, id).doc(JSON.toJSONString(data, FastJsonHumpSerialize.getSerializeConfig()), XContentType.JSON);
        UpdateResponse update = restHighLevelClient.update(request, RequestOptions.DEFAULT);
        return true;
    }

    /**
     * Script更新数字字段
     * @param id
     * @param fieldName
     * @param oprateNum
     * @return
     * @throws IOException
     */
    public boolean updateFieldNum(String id,String fieldName,int oprateNum) throws IOException {
        UpdateRequest request = new UpdateRequest(this.indexName,id).script(new Script("ctx._source."+fieldName+" += "+oprateNum));
        UpdateResponse update = restHighLevelClient.update(request, RequestOptions.DEFAULT);
        return update.getShardInfo().getFailed()==0;
    }

    /**
     * 批量更新
     *
     * @param list
     * @return
     */
    public boolean batchUpdateDoc(List<T> list) throws IOException {
        if (list == null || list.size() < 1) return false;
        BulkRequest request = new BulkRequest();
        for (T t : list) {
            UpdateRequest updateRequest = new UpdateRequest(indexName, getTId(t)).doc(JSON.toJSONString(t, FastJsonHumpSerialize.getSerializeConfig()), XContentType.JSON);
            request.add(updateRequest);
        }
        BulkResponse bulk = restHighLevelClient.bulk(request, RequestOptions.DEFAULT);
        return !bulk.hasFailures();
    }


    /**
     * 获取文档
     *
     * @param id
     * @return
     */
    public Map<String, Object> getDocMapById(String id) throws IOException {
        GetRequest request = new GetRequest(indexName, id);
        GetResponse response = restHighLevelClient.get(request, RequestOptions.DEFAULT);
        Map<String, Object> docMap = response.getSourceAsMap();
        return docMap;
    }

    /**
     * 获取文档
     *
     * @param id
     * @return
     */
    public T getDocById(String id) throws IOException {
        GetRequest request = new GetRequest(indexName, id);
        GetResponse response = restHighLevelClient.get(request, RequestOptions.DEFAULT);
        T result = JSON.parseObject(response.getSourceAsString(), getTClass(), FastJsonHumpSerialize.getParserConfig());
        return result;
    }

    /**
     * 所有数据
     *
     * @param size 指定大小,默认10个
     * @return
     * @throws IOException
     */
    public List<T> searchAll(int size) throws IOException {
        List<T> results = new ArrayList<>();
        SearchSourceBuilder searchSourceBuilder = new SearchSourceBuilder();
        searchSourceBuilder.query(QueryBuilders.matchAllQuery()).size(size);
        SearchRequest searchRequest = new SearchRequest(indexName);
        SearchResponse response = excuteSearch(searchRequest, searchSourceBuilder);
        addItem(results, response.getHits().getHits());
        return results;
    }

    /**
     * 获取Id 列表
     *
     * @param ids
     * @return
     * @throws IOException
     */
    public List<T> searchIds(String... ids) throws IOException {
        List<T> results = new ArrayList<>();
        SearchSourceBuilder searchSourceBuilder = new SearchSourceBuilder();
        searchSourceBuilder.query(QueryBuilders.idsQuery().addIds(ids));
        SearchRequest searchRequest = new SearchRequest().indices(indexName).source(searchSourceBuilder);
        SearchResponse response = excuteSearch(searchRequest, searchSourceBuilder);
        addItem(results, response.getHits().getHits());
        return results;
    }

    /**
     * 精确匹配相当于MySQL的 =,只有key 为keyword类型才可
     *
     * @param key
     * @param value
     * @throws IOException
     */
    public List<T> searchByTerm(String key, Object... value) throws IOException {
        List<T> results = new ArrayList<>();
        SearchSourceBuilder searchSourceBuilder = new SearchSourceBuilder();
        searchSourceBuilder.query(QueryBuilders.termsQuery(key, value));//这里注意下term 和 terms
        SearchRequest searchRequest = new SearchRequest(indexName);
        SearchResponse response = excuteSearch(searchRequest, searchSourceBuilder);
        addItem(results, response.getHits().getHits());
        return results;
    }

    /**
     * 以点为圆心，disance范围查询
     * @param field 字段，类型是geo_point
     * @param distance 距离
     * @param lat 纬度
     * @param lon 经度
     * @return
     * @throws IOException
     */
    public List<T> searchGeo(String field, String distance,double lat,double lon) throws IOException {
        List<T> results = new ArrayList<>();
        SearchSourceBuilder searchSourceBuilder = new SearchSourceBuilder();
        //以某点为中心，搜索指定范围
        searchSourceBuilder.query(QueryBuilders.geoDistanceQuery(field)
                .point(lat,lon).distance(distance,DistanceUnit.KILOMETERS));//distance km
        SearchRequest searchRequest = new SearchRequest(indexName);
        SearchResponse response = excuteSearch(searchRequest, searchSourceBuilder);
        addItem(results, response.getHits().getHits());
        return results;
    }

    private void addItem(List<T> results, SearchHit[] hits) {
        if (hits != null && hits.length > 0) {
            for (SearchHit hit : hits) {
                T item = JSON.parseObject(hit.getSourceAsString(), getTClass(), FastJsonHumpSerialize.getParserConfig());
                results.add(item);
            }
        }
    }

    /**
     * 这个主要是为了让子类自实现其他复杂的查询
     * 还有就是查询器公共配置
     *
     * @param request
     * @param sourceBuilder
     * @return
     * @throws IOException
     */
    public SearchResponse excuteSearch(SearchRequest request, SearchSourceBuilder sourceBuilder) throws IOException {
        // 设置超时
        sourceBuilder.timeout(new TimeValue(60, TimeUnit.SECONDS));
        // 按查询评分降序 排序支持四种：Field-, Score-, GeoDistance-, ScriptSortBuilder
        // 默认的评分排序
        sourceBuilder.sort(new ScoreSortBuilder().order(SortOrder.DESC));
        // 自定义脚本排序
        Script script = new Script("doc['comment_num'].value + doc['praise_num'].value");
        sourceBuilder.sort(SortBuilders.scriptSort(script, ScriptSortBuilder.ScriptSortType.NUMBER).order(SortOrder.DESC));
        // 字段排序
        sourceBuilder.sort(new FieldSortBuilder("create_date").order(SortOrder.DESC));
        // 设置查询器
        request.source(sourceBuilder);
        return restHighLevelClient.search(request, RequestOptions.DEFAULT);
    }

    /**
     * 获取text分词结果
     * @param text
     * @return
     * @throws IOException
     */
    public List<AnalyzeResponse.AnalyzeToken> getAnalyzeToken(String...text) throws IOException {
//        AnalyzeRequest request = AnalyzeRequest.withField(this.indexName,"content",text);
        AnalyzeRequest request = AnalyzeRequest.withIndexAnalyzer(this.indexName,"ik_max_word",text);
        AnalyzeResponse analyze = this.restHighLevelClient.indices().analyze(request, RequestOptions.DEFAULT);
        return analyze.getTokens();
    }
    public String getAnalyzeText(String...text) throws IOException {
        AnalyzeRequest request = AnalyzeRequest.withIndexAnalyzer(this.indexName,"ik_max_word",text);
        AnalyzeResponse analyze = this.restHighLevelClient.indices().analyze(request, RequestOptions.DEFAULT);
        StringBuilder reslt = new StringBuilder();
        analyze.getTokens().forEach(i->reslt.append(i.getTerm()).append(","));
        return reslt.toString().substring(0,reslt.toString().length()-1);
    }
	
	/**
     * 设置高亮
     * @param sourceBuilder
     * @param field 字段名称
     */
    public void setHighLigt(SearchSourceBuilder sourceBuilder,String field){
        HighlightBuilder highlightBuilder = new HighlightBuilder();
        HighlightBuilder.Field contentField = new HighlightBuilder.Field(field);
        contentField.preTags("<em1>","<em2>");
        contentField.postTags("</em1>","</em2>");
        //unified、plain、fvh。默认unified
        contentField.highlighterType("plain");
        highlightBuilder.field(contentField);
        sourceBuilder.highlighter(highlightBuilder);
    }

    /**
     * 获取T 的class
     *
     * @return
     */
    private Class<T> getTClass() {
        Class<T> tClass = (Class<T>) ((ParameterizedType) getClass().getGenericSuperclass()).getActualTypeArguments()[0];
        return tClass;
    }
    /**
     * 反射获取泛型对象ID
     *
     * @param t
     * @return
     */
    public String getTId(T t) {
        try {
            Class<? extends Object> tClass = t.getClass();
            //整合出 getId() 属性这个方法
            Method m = tClass.getMethod("getId");
            //调用这个整合出来的get方法，强转成自己需要的类型
            Object id = m.invoke(t);
            return id.toString();
        } catch (Exception e) {
            log.info("没有这个属性");
            return null;
        }
    }
}
```
**这里写的不是那么全的查询，但是是常用的查询，还有很多查询，像前缀查询，聚合查询，多字段查询....等等**
按需添加！！！

#### 5、测试Demo
```
public class TopicService extends EsBaseService<Topic> {
    public TopicService(String indexName) {
        super(indexName);
    }

    public static void main(String[] args) throws Exception {
        TopicService topicService = new TopicService("topic");
        Topic topic = new Topic();
        topic.setId(EsUtils.getUUID()).setUserId(1l).setTitle("测试标题").setContent("测试内容之-虽然我走得很慢,但我从不后退!")
                .setStatus((short) 1).setIsDel(false).setLocation("22.541144,113.952953")
                .setCreateTime(LocalDateTime.now()).setUpdateTime(LocalDateTime.now());
        topicService.saveDoc(topic.getId(),topic);
		// 关闭客户端
        EsClientConfig.release();
    }
    
}
```
简单的测试一下保存功能！


**官方文档：[https://www.elastic.co/guide/en/elasticsearch/client/java-rest/7.9/java-rest-high-search.html](https://www.elastic.co/guide/en/elasticsearch/client/java-rest/7.9/java-rest-high-search.html)**


**熬夜多-记忆不好，又一篇笔记出炉！！！**

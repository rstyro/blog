---
title: Elasticsearch 数据导入导出 Java 实现工具类
date: 2017-12-11 10:35:54
updated: 2017-12-11 10:35:54
tags: [ElasticSearch]
categories: 搜索引擎
---
# Elasticsearch 数据导入导出 Java 实现
## 最近学了elasticsearch 对它也不是非常的熟悉，它好像没有像 mongodb 有mongodump 这样的工具方便。
## 虽然也有一些别人做的插件工具。但嫌麻烦，所以整理了网上一些大神写代码。工具类如下。
## 如果发现有不对的地方，欢迎指正。或者可以优化的地方，欢迎指点。

<!--more-->

```java
package top.lrshuai.blog.util;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.net.InetSocketAddress;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import org.elasticsearch.action.bulk.BulkRequestBuilder;
import org.elasticsearch.action.index.IndexRequest;
import org.elasticsearch.action.search.SearchRequestBuilder;
import org.elasticsearch.action.search.SearchResponse;
import org.elasticsearch.client.transport.TransportClient;
import org.elasticsearch.common.settings.Settings;
import org.elasticsearch.common.transport.InetSocketTransportAddress;
import org.elasticsearch.common.unit.TimeValue;
import org.elasticsearch.index.query.QueryBuilders;
import org.elasticsearch.search.SearchHit;
import org.elasticsearch.transport.client.PreBuiltTransportClient;
/**
 * 
 * @author rstyro
 *
 */
public class CopyUtil {
	public static void main(String[] args) throws Exception {
		String srcClustName="robot";
		String srcIndexName="robot4";
		String srcIp="127.0.0.1";
		int srcPort = 9300;
		
		String tagClustName="robot";
		String tagIndexName="robot6";
		String tagTypeName="brain";
		String tagIp="127.0.0.1";
		int tagPort = 9300;
		
        esToEs(srcClustName, srcIndexName, srcIp, srcPort, tagClustName, tagIndexName, tagTypeName, tagIp, tagPort);
		
		//outToFile(srcClustName, srcIndexName, null, srcIp, srcPort, "f:\\json.txt");
		//fileToEs(tagClustName, tagIndexName, tagTypeName, tagIp, tagPort, "f:\\json.txt");
	}
	
	/**
	 * 数据拷贝
	 * elasticsearch 到 elasticsearch
	 * @param srcClustName 	原集群名称
	 * @param srcIndexName 	原索引
	 * @param srcIp		   	原ip
	 * @param srcPort		原 transport 服务端口(默认9300的端口)
	 * @param tagClustName	目标集群名称
	 * @param tagIndexName	目标索引
	 * @param tagTypeName	目标type
	 * @param tagIp			目标ip
	 * @param tagPort		目标transport服务端口
	 * @throws InterruptedException
	 */
	public static void esToEs(String srcClustName,String srcIndexName,String srcIp,int srcPort,String tagClustName,String tagIndexName,String tagTypeName,String tagIp,int tagPort) throws InterruptedException{
		Settings srcSettings = Settings.builder()  
              .put("cluster.name", srcClustName)
             // .put("client.transport.sniff", true)  
              //.put("client.transport.ping_timeout", "30s")  
              //.put("client.transport.nodes_sampler_interval", "30s")
			  .build();  
      TransportClient srcClient = new PreBuiltTransportClient(srcSettings);  
      srcClient.addTransportAddress(new InetSocketTransportAddress(new InetSocketAddress(srcIp, srcPort)));  
        
      Settings tagSettings = Settings.builder()  
              .put("cluster.name", tagClustName)
			  //.put("client.transport.sniff", true)  
             // .put("client.transport.ping_timeout", "30s")  
             // .put("client.transport.nodes_sampler_interval", "30s")
			 .build();  
      TransportClient tagClient = new PreBuiltTransportClient(tagSettings);  
      tagClient.addTransportAddress(new InetSocketTransportAddress(new InetSocketAddress(tagIp, tagPort)));  
        
      SearchResponse scrollResp = srcClient.prepareSearch(srcIndexName)  
              .setScroll(new TimeValue(1000))
              .setSize(1000)
              .execute().actionGet();  
        
      BulkRequestBuilder bulk = tagClient.prepareBulk();  
      ExecutorService executor = Executors.newFixedThreadPool(5);  
      while(true){  
          bulk = tagClient.prepareBulk();  
          final BulkRequestBuilder bulk_new = bulk;  
          System.out.println("查询条数="+scrollResp.getHits().getHits().length);
          for(SearchHit hit : scrollResp.getHits().getHits()){  
              IndexRequest req = tagClient.prepareIndex().setIndex(tagIndexName)  
          .setType(tagTypeName).setSource(hit.getSourceAsMap()).request();  
              bulk_new.add(req);  
          }  
          executor.execute(new Runnable() { 
              @Override  
              public void run() {  
                  bulk_new.execute();  
              }  
          });  
          Thread.sleep(100);
          scrollResp = srcClient.prepareSearchScroll(scrollResp.getScrollId())  
                  .setScroll(new TimeValue(1000)).execute().actionGet();  
          if(scrollResp.getHits().getHits().length == 0){  
              break;  
          }  
      }
      //该方法在加入线程队列的线程执行完之前不会执行
      executor.shutdown();
      System.out.println("执行结束");
      tagClient.close();
      srcClient.close();
	}
	
	/**
	 * elasticsearch 数据到文件
	 * @param clustName 	集群名称
	 * @param indexName 	索引名称
	 * @param typeName  	type名称
	 * @param sourceIp  	ip
	 * @param sourcePort 	transport 服务端口
	 * @param filePath		生成的文件路径
	 */
	public static void outToFile(String clustName,String indexName,String typeName,String sourceIp,int sourcePort,String filePath){
		Settings settings = Settings.builder()  
                .put("cluster.name", clustName)
                //.put("client.transport.sniff", true)  
               // .put("client.transport.ping_timeout", "30s")  
               // .put("client.transport.nodes_sampler_interval", "30s")
			   .build();  
        TransportClient client = new PreBuiltTransportClient(settings);  
        client.addTransportAddress(new InetSocketTransportAddress(new InetSocketAddress(sourceIp, sourcePort)));  
        SearchRequestBuilder builder = client.prepareSearch(indexName);
        if(typeName != null){
        	builder.setTypes(typeName);
        }
        builder.setQuery(QueryBuilders.matchAllQuery());
        builder.setSize(10000);
        builder.setScroll(new TimeValue(6000));
        SearchResponse scrollResp = builder.execute().actionGet();
	        try {
	        	//把导出的结果以JSON的格式写到文件里
	            BufferedWriter out = new BufferedWriter(new FileWriter(filePath, true));
	            long count = 0;
	            while (true) {
	            	for(SearchHit hit : scrollResp.getHits().getHits()){
	            		String json = hit.getSourceAsString();
	            		if(!json.isEmpty() && !"".equals(json)){
	            			out.write(json);
	            			out.write("\r\n");
	            			count++;
	            		}
	            	} 
	            	scrollResp = client.prepareSearchScroll(scrollResp.getScrollId())  
	                      .setScroll(new TimeValue(6000)).execute().actionGet();  
	              if(scrollResp.getHits().getHits().length == 0){  
	                  break;  
	              } 
	            }
	            System.out.println("总共写入数据:"+count);
	            out.close();
	            client.close();
	        } catch (FileNotFoundException e) {
	            e.printStackTrace();
	        } catch (IOException e) {
	            e.printStackTrace();
	        }
		
	}
	
	/**
	 * 把json 格式的文件导入到elasticsearch 服务器
	 * @param clustName		集群名称
	 * @param indexName		索引名称
	 * @param typeName		type 名称
	 * @param sourceIp		ip
	 * @param sourcePort	端口
	 * @param filePath		json格式的文件路径
	 */
	@SuppressWarnings("deprecation")
	public static void fileToEs(String clustName,String indexName,String typeName,String sourceIp,int sourcePort,String filePath){
		Settings settings = Settings.builder()  
				.put("cluster.name", clustName)
				//.put("client.transport.sniff", true)  
				//.put("client.transport.ping_timeout", "30s")  
				//.put("client.transport.nodes_sampler_interval", "30s")
				.build();  
		TransportClient client = new PreBuiltTransportClient(settings);  
		client.addTransportAddress(new InetSocketTransportAddress(new InetSocketAddress(sourceIp, sourcePort)));  
		
		try {
			//把导出的结果以JSON的格式写到文件里
			BufferedReader br = new BufferedReader(new FileReader(filePath));
			String json = null;
            int count = 0;
            //开启批量插入
            BulkRequestBuilder bulkRequest = client.prepareBulk();
            while ((json = br.readLine()) != null) {
                bulkRequest.add(client.prepareIndex(indexName, typeName).setSource(json));
                //每一千条提交一次
                count++;
//                if (count% 1000==0) {
//                    System.out.println("提交了1000条");
//                    BulkResponse bulkResponse = bulkRequest.execute().actionGet();
//                    if (bulkResponse.hasFailures()) {
//                    	System.out.println("message:"+bulkResponse.buildFailureMessage());
//                    }
//                    //重新创建一个bulk
//                    bulkRequest = client.prepareBulk();
//                }
            }
            bulkRequest.execute().actionGet();
            System.out.println("总提交了：" + count);
            br.close();
            client.close();
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		}
		
	}

}

```

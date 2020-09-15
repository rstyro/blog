---
title: SpringBoot与Redisson分布式锁的使用
date: 2019-06-25 16:58:26
tags: [Spring Boot]
categories: Java
---

## 一、Redisson 是什么？
来看看百度百科怎么说的。
> Redisson是架设在[Redis](https://redis.io/)基础上的一个Java驻内存数据网格（`In-Memory Data Grid`）。`【Redis官方推荐】`

> Redisson在基于NIO的 [Netty](https://netty.io/) 框架上，充分的利用了Redis键值数据库提供的一系列优势，在Java实用工具包中常用接口的基础上，为使用者提供了一系列具有分布式特性的常用工具类。使得原本作为协调单机多线程并发程序的工具包获得了协调分布式多机多线程并发系统的能力，大大降低了设计和研发大规模分布式系统的难度。同时结合各富特色的分布式服务，更进一步简化了分布式环境中程序相互之间的协作。

然后`【Redisson官方WiKi】 `是这样说的

> Redisson 不仅提供了一系列的分布式的Java常用对象，还提供了许多分布式服务。其中包括(`BitSet, Set, Multimap, SortedSet, Map, List, Queue, BlockingQueue, Deque, BlockingDeque, Semaphore, Lock, AtomicLong, CountDownLatch, Publish / Subscribe, Bloom filter, Remote service, Spring cache, Executor service, Live Object service, Scheduler service`) Redisson提供了使用Redis的最简单和最便捷的方法。Redisson的宗旨是促进使用者对Redis的关注分离（Separation of Concern），从而让使用者能够将精力更集中地放在处理业务逻辑上。

### 功能太强大了，我都有点不会用了！！！

## 二、开始使用
### 1、导入依赖
```
 <!-- redis -->
<dependency>
	<groupId>org.springframework.boot</groupId>
	<artifactId>spring-boot-starter-data-redis</artifactId>
</dependency>
<dependency>
	<groupId>org.apache.commons</groupId>
	<artifactId>commons-pool2</artifactId>
</dependency>
<!-- redisson -->
<dependency>
	<groupId>org.redisson</groupId>
	<artifactId>redisson</artifactId>
	<version>3.11.0</version>
</dependency>
```

### 2 、配置文件配置Redis 
Springboot2 中，redis 默认用的是`lettuce`连接池
```
spring:
  # redis config
  redis:
    host: 127.0.0.1
    password:
    port: 6379
    database: 0
    lettuce:
      pool:
        max-idle: 8
        min-idle: 0
        max-active: 8
        max-wait: -1ms
    timeout: 10000ms
```

### 3、配置Redisson 
有两种方法
#### 第一种：程序化配置方法
```
Config config = new Config();
config.setTransportMode(TransportMode.EPOLL);
config.useClusterServers()
      //可以用"rediss://"来启用SSL连接
      .addNodeAddress("redis://127.0.0.1:7181");
```

#### 第二种：文件方式配置
```
// json 文件
Config config = Config.fromJSON(new File("config-file.json"));
RedissonClient redisson = Redisson.create(config);

# yaml 文件
Config config = Config.fromYAML(new File("config-file.yaml"));
RedissonClient redisson = Redisson.create(config);
```
> 配置文件的具体内容，就不多介绍了，官方的听详细的,下面给传送门
> [点我带你飞：传送门](https://github.com/redisson/redisson/wiki/2.-%E9%85%8D%E7%BD%AE%E6%96%B9%E6%B3%95)


##### 我个人比较喜欢程序化方式，全部代码如下：
```java
package top.lrshuai.redisson.config;

import org.redisson.Redisson;
import org.redisson.api.RedissonClient;
import org.redisson.config.Config;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.util.StringUtils;

/**
 * redisson 配置，下面是单节点配置：
 * 官方wiki地址：https://github.com/redisson/redisson/wiki/2.-%E9%85%8D%E7%BD%AE%E6%96%B9%E6%B3%95#26-%E5%8D%95redis%E8%8A%82%E7%82%B9%E6%A8%A1%E5%BC%8F
 *
 */
@Configuration
public class RedissonConfig {

    @Value("${spring.redis.host}")
    private String host;

    @Value("${spring.redis.port}")
    private String port;

    @Value("${spring.redis.password}")
    private String password;

    @Bean
    public RedissonClient redissonClient(){
        Config config = new Config();
        //单节点
        config.useSingleServer().setAddress("redis://" + host + ":" + port);
        if(StringUtils.isEmpty(password)){
            config.useSingleServer().setPassword(null);
        }else{
            config.useSingleServer().setPassword(password);
        }
        //添加主从配置
//        config.useMasterSlaveServers().setMasterAddress("").setPassword("").addSlaveAddress(new String[]{"",""});

        // 集群模式配置 setScanInterval()扫描间隔时间，单位是毫秒,  //可以用"rediss://"来启用SSL连接
//        config.useClusterServers().setScanInterval(2000).addNodeAddress("redis://127.0.0.1:7000", "redis://127.0.0.1:7001").addNodeAddress("redis://127.0.0.1:7002");
        return Redisson.create(config);
    }
}
```
以`Bean`的方式注入，然后在想用的地方创建一个变量即可

### 4、代码使用Redisson
```java

    @Autowired
    private RedissonClient redissonClient;
```

## 三、Redisson 分布式锁的简单使用
什么是分布式锁？分布式锁有什么作用？分布式锁怎么用？
> **个人见解**：学过多线程的应该知道，共享变量，如果不加锁的话，当多个线程去操作的时候就有可能导致数据的不一致性等问题。所以Java 本身给我们提供了`Synchronized` 关键字或者 `Lock` 锁,都可以处理这种问题。这种方式只针对单台服务器而言的，像`双十一`、`618` 这种大型活动，肯定不是只有一台服务器就能带飞的，走都不一定能走，别说飞了。当采用分布式系统多台服务器运行的时候，上面的锁方案就不靠谱了。所以分布式锁出来了。

> **百度百科**：
> 分布式锁是控制分布式系统之间同步访问共享资源的一种方式。在[分布式系统](https://baike.baidu.com/item/%E5%88%86%E5%B8%83%E5%BC%8F%E7%B3%BB%E7%BB%9F/4905336)中，常常需要协调他们的动作。如果不同的系统或是同一个系统的不同主机之间共享了一个或一组资源，那么访问这些资源的时候，往往需要互斥来防止彼此干扰来保证[一致性](https://baike.baidu.com/item/%E4%B8%80%E8%87%B4%E6%80%A7/9840083)，在这种情况下，便需要使用到分布式锁。

> 废话真多，代码撸起

```java
 /**
     * 如果只有一个线程来访问，那么在rLock.tryLock() 这个方法就会阻塞，等锁释放然后再继续下面的操作，
     * 如果是多线程访问，那么在rLock.tryLock() 这个方法会直接返回false不阻塞了,继续往下执行
     * 可以配合Jmeter 来测试
     * 更多锁的demo,可以参考wiki: https://github.com/redisson/redisson/wiki/8.-%E5%88%86%E5%B8%83%E5%BC%8F%E9%94%81%E5%92%8C%E5%90%8C%E6%AD%A5%E5%99%A8
     * @return
     */
    @GetMapping("/test")
    public Object test(){
        //获取锁实例
        RLock rLock = redissonClient.getLock(lock);
        boolean isLock =false;
        try {
            // 上锁
            isLock = rLock.tryLock();
            System.out.println(Thread.currentThread().getName()+"isLock="+isLock);
            if (isLock) {
                System.out.println(Thread.currentThread().getName()+"我抢到锁了，开心，先休息10秒先");
                Thread.sleep(10 *1000);
                // todo service 业务代码
            }else {
                System.out.println(Thread.currentThread().getName()+"被人锁了，郁闷下次再来");
                return FAILED;
            }
        } catch (InterruptedException e) {
            e.printStackTrace();
        } finally {
            if(isLock){
                System.out.println(Thread.currentThread().getName()+"不玩了，开锁了！！！");
                // 解锁
                rLock.unlock();
            }
        }
        return SUCCESS;
    }
```

![测试图片](lock.png)


Redisson 提供的锁有那么几个，按需使用
+ 可重入锁
+ 公平锁
+ 联锁
+ 红锁
+ 读写锁
+ 闭锁
各个锁的使用[Wiki]([https://github.com/redisson/redisson/wiki/8.-%E5%88%86%E5%B8%83%E5%BC%8F%E9%94%81%E5%92%8C%E5%90%8C%E6%AD%A5%E5%99%A8](https://github.com/redisson/redisson/wiki/8.-%E5%88%86%E5%B8%83%E5%BC%8F%E9%94%81%E5%92%8C%E5%90%8C%E6%AD%A5%E5%99%A8)
) 都有介绍，我只是粗略的开个头。


## 四、Redisson消息的发布订阅
这个简单，一个发布，一个接受，简单代码如下：
```java
//发布
public long publish(MyObjectDTO myObjectDTO){
	RTopic rTopic = redissonClient.getTopic(Consts.TopicName);
	return  rTopic.publish(myObjectDTO);
}

// 订阅
public void subscribe(){
        RTopic rTopic = redissonClient.getTopic(Consts.TopicName);
        rTopic.addListener(MyObjectDTO.class, new MessageListener<MyObjectDTO>() {
            // 接受订阅的消息
            @Override
            public void onMessage(CharSequence charSequence, MyObjectDTO myObjectDTO) {
                log.info("接受到消息主题={}，内容={}",charSequence,myObjectDTO);
                System.out.println("传输的数据为="+myObjectDTO);
            }
        });
    }
```
> `MyObjectDTO` 就是发布的消息体，随意一个对象就行，命名有点`LOW`
![示例图](test1.png)


#### 完整代码地址
+ Github 地址：[[https://github.com/rstyro/Springboot/tree/master/SpringBoot2-Redisson](https://github.com/rstyro/Springboot/tree/master/SpringBoot2-Redisson)
]([https://github.com/rstyro/Springboot/tree/master/SpringBoot2-Redisson](https://github.com/rstyro/Springboot/tree/master/SpringBoot2-Redisson)
)  
+ Gitee 地址：[[https://gitee.com/rstyro/spring-boot/tree/master/SpringBoot2-Redisson](https://gitee.com/rstyro/spring-boot/tree/master/SpringBoot2-Redisson)
]([https://gitee.com/rstyro/spring-boot/tree/master/SpringBoot2-Redisson](https://gitee.com/rstyro/spring-boot/tree/master/SpringBoot2-Redisson)
)

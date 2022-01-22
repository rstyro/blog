---
title: Java 面试题之后篇
date: 2018-01-03 17:14:32
updated: 2018-01-03 17:14:32
tags: [Java]
categories: Java
---
## Java 面试高级篇

## 三、开源框架和容器

### 3.1、SSM/Servlet

+ #### Servlet的生命周期
> 1、new 实例化Servlet
 2、Servlet 通过调用 init () 方法进行初始化。
3、Servlet 调用 service() 方法来处理客户端的请求。
4、Servlet 通过调用 destroy() 方法终止（结束）。
5、最后，Servlet 是由 JVM 的垃圾回收器进行垃圾回收的

+ #### 转发与重定向的区别
> 转发是服务器行为，重定向是客户端行为
> 重定向，其实是两次request,请求转发共享相同的request对象和response对象
> 我也说得不是很好，可以度娘或者按自己得理解


+ #### Spring 中BeanFactory 和 ApplicationContext 有什么区别
> BeanFacotry是spring中比较原始的Factory,原始的BeanFactory无法支持spring的许多插件，如AOP功能、Web应用等。 
> ApplicationContext接口,它由BeanFactory接口派生而来，因而提供BeanFactory所有的功能。还提供了以下的功能:
> 1.利用MessageSource进行国际化  
> 2.强大的事件机制(Event)  
> 3.底层资源的访问   
> 4.对Web应用的支持  
> 5、BeanFactroy采用的是延迟加载形式来注入Bean的，而ApplicationContext则相反，容器启动时，一次性创建了所有的Bean。这样，在容器启动时，我们就可以发现Spring中存在的配置错误。 
> 6.BeanFactory和ApplicationContext都支持BeanPostProcessor、BeanFactoryPostProcessor的使用，但两者之间的区别是：BeanFactory需要手动注册，而ApplicationContext则是自动注册


+ #### Spring Bean 的生命周期
> 1：Bean的建立：
	容器寻找Bean的定义信息并将其实例化。
2：属性注入：
	使用依赖注入，Spring按照Bean定义信息配置Bean所有属性
3：BeanNameAware的setBeanName()：
	如果Bean类有实现org.springframework.beans.BeanNameAware接口，工厂调用Bean的setBeanName()方法传递Bean的ID。
4：BeanFactoryAware的setBeanFactory()：
	如果Bean类有实现org.springframework.beans.factory.BeanFactoryAware接口，工厂调用setBeanFactory()方法传入工厂自身。
5：BeanPostProcessors的ProcessBeforeInitialization()
	如果有org.springframework.beans.factory.config.BeanPostProcessors和Bean关联，那么其postProcessBeforeInitialization()方法将被将被调用。
6：initializingBean的afterPropertiesSet()：
	如果Bean类已实现org.springframework.beans.factory.InitializingBean接口，则执行他的afterProPertiesSet()方法
7：Bean定义文件中定义init-method：
	可以在Bean定义文件中使用"init-method"属性设定方法名称例如：
	如果有以上设置的话，则执行到这个阶段，就会执行initBean()方法
8：BeanPostProcessors的ProcessaAfterInitialization()
	如果有任何的BeanPostProcessors实例与Bean实例关联，则执行BeanPostProcessors实例的ProcessaAfterInitialization()方法
9：DisposableBean的destroy()
	在容器关闭时，如果Bean类有实现org.springframework.beans.factory.DisposableBean接口，则执行他的destroy()方法
> 参考:[https://www.cnblogs.com/kenshinobiy/p/4652008.html](https://www.cnblogs.com/kenshinobiy/p/4652008.html)

+ #### Spring的bean的创建时机？依赖注入的时机？
> 1、在默认的情况下，启动spring容器创建对象。
2、在spring的配置文件bean中有一个属性  lazy-init="default/true/false"
如果 lazy-init = default/false ，在启动spring容器时创建对象。
为 true 时，在 context.getBean() 时才创建对象。
> 依赖注入在以下两种情况发生：
(1).用户第一次通过getBean方法向IoC容索要Bean时，IoC容器触发依赖注入。
(2).当用户在Bean定义资源中为<Bean>元素配置了lazy-init属性，即让容器在解析注册Bean定义时进行预实例化，触发依赖注入。


+ #### Spring IOC 如何实现
> 依赖注入的思想好像是通过反射机制实现的，这个我得水平好像没到。
> 可以参考文章：[https://www.cnblogs.com/ITtangtang/p/3978349.html](https://www.cnblogs.com/ITtangtang/p/3978349.html)


+ #### Spring IoC涉及到的设计模式；
> 工厂模式、单利模式。。

+ #### Spring中Bean的作用域，默认的是哪一个
> 1、singleton：单例模式，在整个Spring IoC容器中，使用singleton定义的Bean将只有一个实例
2、prototype：原型模式，每次通过容器的getBean方法获取prototype定义的Bean时，都将产生一个新的Bean实例
3、request：对于每次HTTP请求，使用request定义的Bean都将产生一个新实例，即每次HTTP请求将会产生不同的Bean实例。只有在Web应用中使用Spring时，该作用域才有效
4、session：对于每次HTTP Session，使用session定义的Bean豆浆产生一个新实例。同样只有在Web应用中使用Spring时，该作用域才有效
5、globalsession：每个全局的HTTP Session，使用session定义的Bean都将产生一个新实例。典型情况下，仅在使用portlet context的时候有效。同样只有在Web应用中使用Spring时，该作用域才有效
模式的是单例模式（singleton）


+ #### 说说 Spring AOP、实现原理
> 笔者的水平不够
> 可参考：[https://blog.csdn.net/fighterandknight/article/details/51209822](https://blog.csdn.net/fighterandknight/article/details/51209822)

+ #### 动态代理（CGLib 与 JDK）、优缺点、性能对比、如何选择
> 从 jdk6 到 jdk7、jdk8 ，动态代理的性能得到了显著的提升，而 cglib 的表现并未跟上，甚至可能会略微下降
> 是否正确，自行决断，笔者水平一般，参考：[https://www.cnblogs.com/haiq/p/4304615.html](https://www.cnblogs.com/haiq/p/4304615.html)

+ #### Spring 事务实现方式、事务的传播机制、默认的事务类别
> 现实方式有:声明式事务和编程式事务？
> 六种事务传播机制：
> PROPAGATION_REQUIRED -- 支持当前事务，如果当前没有事务，就新建一个事务。这是最常见的选择。
> PROPAGATION_SUPPORTS -- 支持当前事务，如果当前没有事务，就以非事务方式执行。
> PROPAGATION_MANDATORY -- 支持当前事务，如果当前没有事务，就抛出异常
> PROPAGATION_REQUIRES_NEW -- 新建事务，如果当前存在事务，把当前事务挂起。
> PROPAGATION_NOT_SUPPORTED -- 以非事务方式执行操作，如果当前存在事务，就把当前事务挂起。
> PROPAGATION_NEVER -- 以非事务方式执行，如果当前存在事务，则抛出异常。
> PROPAGATION_NESTED -- 如果当前存在事务，则在嵌套事务内执行。如果当前没有事务，则进行与PROPAGATION_REQUIRED类似的操作
> 参考自：[https://blog.csdn.net/yuanlaishini2010/article/details/45792069](https://blog.csdn.net/yuanlaishini2010/article/details/45792069)


+ #### Spring 事务底层原理
> 不行了，来个大腿


+ #### Spring事务失效（事务嵌套），JDK动态代理给Spring事务埋下的坑
> 不知道什么坑。。。

+ #### 如何自定义注解实现功能
> 以后来写


+ #### Spring MVC 运行流程
> 1.spring mvc将所有的请求都提交给DispatcherServlet,它会委托应用系统的其他模块负责对请求 进行真正的处理工作。
2.DispatcherServlet查询一个或多个HandlerMapping,找到处理请求的Controller.
3.DispatcherServlet请请求提交到目标Controller
4.Controller进行业务逻辑处理后，会返回一个ModelAndView
5.Dispathcher查询一个或多个ViewResolver视图解析器,找到ModelAndView对象指定的视图对象
6.视图对象负责渲染返回给客户端。


+ #### Spring MVC 启动流程
> 1.Web容器初始化过程 
2.SpringMVC中web.xml配置
3.认识ServletContextListener 
4.认识ContextLoaderListener
5.DispatcherServlet初始化（HttpServletBean • FrameworkServlet • DispatcherServlet）
6.ContextLoaderListener与DispatcherServlet关系 
7.DispatcherServlet的设计 
8.DispatcherServlet工作原理

+ #### Spring 的单例实现原理
> Spring对bean实例的创建是采用单例注册表的方式进行实现的，而这个注册表的缓存是HashMap对象，如果配置文件中的配置信息不要求使用单例，Spring会采用新建实例的方式返回对象实例
> 参考：[https://blog.csdn.net/cs408/article/details/48982085](https://blog.csdn.net/cs408/article/details/48982085)


+ #### Spring 框架中用到了哪些设计模式
> 代理模式—在AOP和remoting中被用的比较多。
单例模式—在spring配置文件中定义的bean默认为单例模式。
模板方法—用来解决代码重复的问题。比如. RestTemplate, JmsTemplate, JpaTemplate。
工厂模式—BeanFactory用来创建对象的实例。
适配器--spring aop
装饰器--spring data  hashmapper
观察者-- spring 时间驱动模型
回调--Spring ResourceLoaderAware回调接口


+ #### Spring 其他产品
> Srping Boot、Spring Cloud、Spring Secuirity、Spring Data、Spring AMQP 等

+ #### 有没有用到Spring Boot，Spring Boot的认识、原理
> 这个不是一两句话能说清的。
> 可参考：[https://www.cnblogs.com/zheting/p/6707035.html](https://www.cnblogs.com/zheting/p/6707035.html)

+ #### Spring中 Resource注解和Autowired注解的区别
> `@Resource`默认按照名称方式进行bean匹配，`@Autowired`默认按照类型方式进行bean匹配
> `@Resource`是J2EE的注解,`@Autowired`是Spring的注解

+ #### 如果一个接⼝有2个不同的实现, 那么怎么来Autowire一个指定的实现？
> (可以使用Qualifier注解限定要注入的Bean，也可以使用Qualifier和Autowire注解指定要获取的bean，也可以使用Resource注解的name属性指定要获取的Bean)

+ #### Spring声明一个 bean 如何对其进行个性化定制；
> init-method属性指定了在初始化bean时要调用的方法，类似的，destroy-method属性指定了bean从容器移除之前要调用的方法。


+ #### MyBatis有什么优势；

> 优点：
1. 易于上手和掌握。
2. sql写在xml里，便于统一管理和优化。
3. 解除sql与程序代码的耦合。
4. 提供映射标签，支持对象与数据库的orm字段关系映射
5. 提供对象关系映射标签，支持对象关系组建维护
6. 提供xml标签，支持编写动态sql。

> 缺点：
1. sql工作量很大，尤其是字段多、关联表多时，更是如此。
2. sql依赖于数据库，导致数据库移植性差。
3. 由于xml里标签id必须唯一，导致DAO中方法不支持方法重载。
4. 字段映射标签和对象关系映射标签仅仅是对映射关系的描述，具体实现仍然依赖于sql。（比如配置了一对多Collection标签，如果sql里没有join子表或查询子表的话，查询后返回的对象是不具备对象关系的，即Collection的对象为null）
5. DAO层过于简单，对象组装的工作量较大。
6.  不支持级联更新、级联删除。
7. 编写动态sql时,不方便调试，尤其逻辑复杂时。
8 提供的写动态sql的xml标签功能简单（连struts都比不上），编写动态sql仍然受限，且可读性低。
9. 若不查询主键字段，容易造成查询出的对象有“覆盖”现象。
10. 参数的数据类型支持不完善。（如参数为Date类型时，容易报没有get、set方法，需在参数上加@param）
11. 多参数时，使用不方便，功能不够强大。（目前支持的方法有map、对象、注解@param以及默认采用012索引位的方式）
12. 缓存使用不当，容易产生脏数据。

+ #### MyBatis如何做事务管理；
> MyBatis单独使用时，使用SqlSession来处理事务：
> 和Spring集成后，使用Spring的事务管理

+ #### MyBatis怎么防止SQL注入；
> 使用#{}语法,MyBatis会产生PreparedStatement语句中，并且安全的设置PreparedStatement参数，这个过程中MyBatis会进行必要的安全检查和转义
> 简单说，#{}是经过预编译的，是安全的；${}是未经过预编译的，仅仅是取变量的值，是非安全的，存在SQL注入


+ #### Mybatis 的工作原理
> 1、XMLConfigBuilder对象会进行XML配置文件的解析
> 2、在configuration节点下会依次解析properties/settings/.../mappers等节点配置，并存到configuration对象
> 3、使用Configuration对象去创建SqlSessionFactory。
> 4、SqlSession通过SqlSessionFactory的opensession方法返回的
> 5、MapperProxy 通过SqlSession这个具体实现类DefaultSqlSession的getMapper来获取动态代理对象
> 6、MapperProxy的invoke方法最终会被代理对象调用，
> 7、invoke 方法中调用MapperMethod.execute(sqlsession,args) 执行,得到最终的处理结果
> 可参考：[https://www.jianshu.com/p/a6b5e066c3d9](https://www.jianshu.com/p/a6b5e066c3d9)


+ #### Mybtis缓存机制
> mybatis的缓存分为两级：一级缓存、二级缓存。
> 一级缓存是SqlSession级别的缓存，缓存的数据只在SqlSession内有效(默认是开启一级缓存)
> 二级缓存是mapper级别的缓存，同一个namespace公用这一个缓存，所以对SqlSession是共享的(默认是没有开启的)


+ #### Mybtis 常用的动态标签
> 1,foreach用来循环容器的标签
> 2,concat模糊查詢
> 3,choose(when,otherwise)标签
> 4,if标签
> 5,selectKey标签

### 3.2、Netty

+  #### 为什么选择 Netty

+  #### 说说业务中，Netty 的使用场景

+  #### 原生的 NIO 在 JDK 1.7 版本存在 epoll bug

+  #### 什么是TCP 粘包/拆包

+  #### TCP粘包/拆包的解决办法

+  #### Netty 线程模型

+  #### 说说 Netty 的零拷贝

+  #### Netty 内部执行流程

+  #### Netty 重连实现

### 3.3、Tomcat

+ #### Tomcat的基础架构（Server、Service、Connector、Container）

+ #### Tomcat如何加载Servlet的

+ #### Pipeline-Valve机制

可参考：《四张图带你了解Tomcat系统架构！》

## 四、分布式

### 4.1、Nginx

+ #### 请解释什么是C10K问题或者知道什么是C10K问题吗？

+ #### Nginx简介，可参考《Nginx简介》

+ #### 正向代理和反向代理.

+ #### Nginx几种常见的负载均衡策略

+ #### Nginx服务器上的Master和Worker进程分别是什么

+ #### 使用“反向代理服务器”的优点是什么?

+ #### 常见的Nginx负载均衡策略；已有两台Nginx服务器了，倘若这时候再增加一台服务器，采用什么负载均衡算法比较好？

### 4.2、分布式其他

+ #### 谈谈业务中使用分布式的场景

+ #### Session 分布式方案

+ #### Session 分布式处理

+ #### 分布式锁的应用场景、分布式锁的产生原因、基本概念

+ #### 分布是锁的常见解决方案

+ #### 分布式事务的常见解决方案

+ #### 集群与负载均衡的算法与实现

+ #### 说说分库与分表设计，可参考《数据库分库分表策略的具体实现方案》

+ #### 分库与分表带来的分布式困境与应对之策

+ #### 如何保证分布式缓存的一致性(分布式缓存一致性hash算法?)？分布式session实现？

+ #### Solr如何实现全天24小时索引更新；

### 4.3、Dubbo

+ #### 什么是Dubbo，可参考《Dubbo入门》

+ #### 什么是RPC、如何实现RPC、RPC 的实现原理，可参考《基于HTTP的RPC实现》

+ #### Dubbo中的SPI是什么概念

+ #### Dubbo的基本原理、执行流程

## 五、微服务

### 5.1、微服务

+ #### 前后端分离是如何做的？

+ #### 微服务哪些框架

+ #### Spring Could的常见组件有哪些？可参考《Spring Cloud概述》

+ #### 领域驱动有了解吗？什么是领域驱动模型？充血模型、贫血模型

+ #### JWT有了解吗，什么是JWT，可参考《前后端分离利器之JWT》

+ #### 你怎么理解 RESTful

+ #### 说说如何设计一个良好的 API

+ #### 如何理解 RESTful API 的幂等性

+ #### 如何保证接口的幂等性

+ #### 说说 CAP 定理、BASE 理论

+ #### 怎么考虑数据一致性问题

+ #### 说说最终一致性的实现方案

+ #### 微服务的优缺点，可参考《微服务批判》

+ #### 微服务与 SOA 的区别

+ #### 如何拆分服务、水平分割、垂直分割

+ #### 如何应对微服务的链式调用异常

+ #### 如何快速追踪与定位问题

+ #### 如何保证微服务的安全、认证

### 5.2、安全问题

+ #### 如何防范常见的Web攻击、如何方式SQL注入

+ #### 服务端通信安全攻防

+ #### HTTPS原理剖析、降级攻击、HTTP与HTTPS的对比

### 5.3、性能优化

+ #### 性能指标有哪些

+ #### 如何发现性能瓶颈

+ #### 性能调优的常见手段

+ #### 说说你在项目中如何进行性能调优

## 六、其他

### 6.1、设计能力

+ #### 说说你在项目中使用过的UML图

+ #### 你如何考虑组件化、服务化、系统拆分

+ #### 秒杀场景如何设计

+ #### 如何防止表单重复提交（Token令牌环等方式）；

+ #### 有一个url白名单，需要使用正则表达式进行过滤，但是url量级很大，大概亿级，那么如何优化正则表达式？如何优化亿级的url匹配呢？

可参考：《秒杀系统的技术挑战、应对策略以及架构设计总结一二！》
### 6.2、业务工程

+ #### 说说你的开发流程、如何进行自动化部署的

+ #### 你和团队是如何沟通的

+ #### 你如何进行代码评审

+ #### 说说你对技术与业务的理解

+ #### 说说你在项目中遇到感觉最难Bug，是如何解决的

+ #### 介绍一下工作中的一个你认为最有价值的项目，以及在这个过程中的角色、解决的问题、你觉得你们项目还有哪些不足的地方

### 6.3、软实力

+ #### 说说你的优缺点、亮点

+ #### 说说你最近在看什么书、什么博客、在研究什么新技术、再看那些开源项目的源代码

+ #### 说说你觉得最有意义的技术书籍

+ #### 工作之余做什么事情、平时是如何学习的，怎样提升自己的能力

+ #### 说说个人发展方向方面的思考

+ #### 说说你认为的服务端开发工程师应该具备哪些能力

+ #### 说说你认为的架构师是什么样的，架构师主要做什么

+ #### 如何看待加班的问题

## 七、操作系统
+ #### Linux静态链接和动态链接；

+ #### 什么是IO多路复用模型（select、poll、epoll）；

+ #### Linux中的grep管道用处？Linux的常用命令？

+ #### 操作系统中虚拟地址、逻辑地址、线性地址、物理地址的概念及区别；

+ #### 内存的页面置换算法；

+ #### 进程调度算法，操作系统是如何调度进程的；

+ #### 父子进程、孤儿进程、僵死进程等概念；

+ #### fork进程时的操作；

+ #### kill用法，某个进程杀不掉的原因（僵死进程；进入内核态，忽略kill信号）；

+ #### 系统管理命令（如查看内存使用、网络情况）；

+ #### find命令、awk使用；

+ #### Linux下排查某个死循环的线程；

+ #### 为什么要内存对齐；

+ #### 为什么会有大端小端，htol这一类函数的作用；

+ #### top显示出来的系统信息都是什么含义；（重要！）

+ #### Linux地址空间，怎么样进行寻址的；

+ #### Linux如何查找目录或者文件的；

+ #### Linux下可以在/proc目录下可以查看CPU的核心数等；cat /proc/下边会有很多系统内核信息可供显示； 

+ #### 说一下栈的内存是怎么分配的；

+ #### Linux各个目录有了解过吗？/etc、/bin、/dev、/lib、/sbin这些常见的目录主要作用是什么？

+ #### 说一下栈帧的内存是怎么分配的；

+ #### Linux下排查某个死循环的线程；

## 八、系统设计开放性题目

+ #### 秒杀系统设计，超卖怎么搞;

+ #### 你们的图片时怎么存储的，对应在数据库中时如何保存图片的信息的？

+ #### 假如成都没有一座消防站，现在问你要建立几座消防站，每个消防站要配多少名消防官兵，多少辆消防车，请你拿出一个方案；

+ #### 基于数组实现一个循环阻塞队列；

+ #### 常见的ipv4地址的展现形式如“168.0.0.1”，请实现ip地址和int类型的相互转换。（使用位移的方式）

+ #### 现网某个服务部署在多台Liunx服务器上，其中一台突然出现CPU 100%的情况，而其他服务器正常，请列举可能导致这种情况发生的原因？如果您遇到这样的情况，应如何定位？内存？CPU？发布？debug？请求量？

## 九、大数据量问题（后边会有专题单独讨论）

+ #### 给定a、b两个文件，各存放50亿个url，每个url各占64字节，内存限制是4G，让你找出a、b文件共同的url？

+ #### 海量日志数据，提取出某日访问百度次数最多的那个IP；

+ #### 一个文本文件，大约有一万行，每行一个词，要求统计出其中最频繁出现的前10个词，请给出思想，给出时间复杂度分析。

+ #### 此话题后边会有专门的文章探讨，如果有等不及的小伙伴，可以移步参考：

+ **1、https://blog.csdn.net/v_july_v/article/details/6279498**

+ **2、https://blog.csdn.net/v_july_v/article/details/7382693**

## 十、逻辑思维题

+ #### 有两根粗细均匀的香（烧香拜佛的香），每一根烧完都花一个小时，怎么样能够得到15min？

+ #### 假定你有8个撞球，其中有1个球比其他的球稍重,如果只能利用天平来断定哪一个球重,要找到较重的球,要称几次?（2次）；

+ #### 实验室里有1000个一模一样的瓶子，但是其中的一瓶有毒。可以用实验室的小白鼠来测试哪一瓶是毒药。如果小白鼠喝掉毒药的话，会在一个星期的时候死去，其他瓶子里的药水没有任何副作用。请问最少用多少只小白鼠可以在一个星期以内查出哪瓶是毒药；（答案是10只）

+ #### 假设有一个池塘，里面有无穷多的水。现有2个空水壶，容积分别为5升和6升。问题是如何只用这2个水壶从池塘里取得3升的水；


#### 面试题前篇的链接：[http://lrshuai.top/atc/show/109](http://lrshuai.top/atc/show/109)
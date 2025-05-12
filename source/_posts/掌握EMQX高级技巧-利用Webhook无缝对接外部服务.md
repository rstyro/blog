---
title: 掌握EMQX高级技巧:利用Webhook无缝对接外部服务
tags: [EMQX]
categories: 物联网
date: 2025-05-12 18:43:11
updated: 2025-05-12 18:43:11
---

## 一、什么是webhook

- Webhook是一种通过自定义HTTP回调来实现实时通知机制的方法。简单来说，它允许一个应用在特定事件发生时向另一个应用发送HTTP请求（通常是POST请求），从而实现不同系统之间的即时信息交流。这种方式使得开发者可以基于特定事件触发的响应进行编程，增强了应用间的交互性和自动化程度。

<!--more-->

### 1、Webhook与传统API调用的区别
- 传统的API调用通常是由客户端发起请求到服务端获取数据或执行操作，属于拉取模式。而Webhook则是服务端在检测到指定事件发生时主动推送通知给客户端，是推模式。这种差异意味着Webhook能够更高效地处理实时性要求较高的场景，减少不必要的轮询，提升系统的整体效率和响应速度。



| **特性**     | **Webhook**          | **传统 API 调用**                  |
| ------------ | -------------------- | ---------------------------------- |
| **通信方式** | 被动（事件驱动）     | 主动（客户端发起请求）             |
| **数据流向** | 服务端主动发送数据   | 客户端主动请求数据                 |
| **适用场景** | 实时事件通知         | 定期轮询或按需获取                 |
| **资源消耗** | 更高效，无需频繁轮询 | 高资源占用，尤其是在高频轮询场景下 |



### 2、 Webhook的机制

- Webhook机制主要依赖于事件触发器、HTTP请求生成器和目标服务器三大部分。首先，事件触发器监控特定事件的发生；一旦检测到该事件，HTTP请求生成器就会创建一个包含事件详情的HTTP请求，并发送给目标服务器；最后，目标服务器根据接收到的信息执行相应操作。



### 3、Webhook有什么用

- Webhook广泛应用于需要实时响应的应用场景中，比如社交媒体更新、支付成功后的通知、代码仓库的变更通知等。它可以让不同的服务之间建立更加紧密和及时的联系，无需人工干预即可完成一系列复杂的业务流程。


## 二、EMQX配置Webhook
- 在emqx中，WebHook 是由 [emqx_web_hook](https://github.com/emqx/emqx-web-hook) 插件提供的 **将 EMQ X 中的钩子事件通知到某个 Web 服务** 的功能。
- WebHook 的内部实现是基于 [钩子](https://docs.emqx.com/zh/emqx/v4.0/advanced/hooks.html)，但它更靠近顶层一些。它通过在钩子上的挂载回调函数，获取到 EMQX 中的各种事件，并转发至 emqx_web_hook 中配置的 Web 服务器。

### 1、为什么配置webhook
- 根据业务需求，如果您需要保存EMQX客户端订阅的主题信息或发布消息的内容，可以通过配置Webhook将这些数据推送到外部服务器。



### 2、EMQX配置webhook
- 我们可以在EMQX的控制台中配置webhook
- 如下图：

![](webhook1.png)

- 在集成那里，选择webhook,进行创建

![](webhook2.png)

- 消息发布的时候，我们配置一个webhook,请求的URL为：`http://192.168.110.40:8888/webhook/publishHook`
- 其中上面的URL地址就是我们业务服务器暴露的webhook地址（见下面第3点），用于接收消息的

![](webhook3.png)

- 这个是监听事件的，想触发哪个事件就选哪个，我这里全选了


![](webhook4.png)

### 3、新建webhook接口

- 上面在EMQX控制台配置了webhook，但是其中URL地址我们是预先写的，目前还没有这个接口，所以需要新建webhook的请求接口，用于EMQX服务推送webhook的地址

- 在之前的demo项目中新建一个`WebHookController.java` 用于接收数据

```java
/**
 * EMQX webhook配置
 */
@Slf4j
@RestController
@RequestMapping("/webhook")
@RequiredArgsConstructor
public class WebHookController {

    /**
     * 接收消息发布的
     * @param data 参数
     * @return
     */
    @PostMapping("/publishHook")
    public Object publishHook(@RequestBody Map<String, Object> data) {
        log.info("webhook-收到发布消息data={}", data);
        // 这个payload就是消息内容
        String payload = (String) data.get("payload");
        // todo 根据业务自己处理数据，是否需要保存payload
        return "返回值随便返回";
    }

    /**
     * 事件监听的
     * @param data 参数
     * @return 随便
     */
    @PostMapping("/eventHook")
    public Object eventHook(@RequestBody Map<String, Object> data) {
        log.info("webhook-收到事件data={}", data);
        return "返回值随便返回";
    }

}
```

- `/publishHook` 接口可以接收消息发布的内容，
- 而`/eventHook` 就是EMQX的事件触发器触发的
- 上面这2个接口就是对应EMQX配置webhook的地址

常见的事件：

| 名称                 | 说明         | 执行时机                                       |
| :------------- | :----------- | :---------------------------------------- |
| client.connect       | 处理连接报文 | 服务端收到客户端的连接报文时                   |
| client.connack       | 下发连接应答 | 服务端准备下发连接应答报文时                   |
| client.connected     | 成功接入     | 客户端认证完成并成功接入系统后                 |
| client.disconnected  | 连接断开     | 客户端连接层在准备关闭时                       |
| client.subscribe     | 订阅主题     | 收到订阅报文后，执行 `client.check_acl` 鉴权前 |
| client.unsubscribe   | 取消订阅     | 收到取消订阅报文后                             |
| session.subscribed   | 会话订阅主题 | 完成订阅操作后                                 |
| session.unsubscribed | 会话取消订阅 | 完成取消订阅操作后                             |
| message.publish      | 消息发布     | 服务端在发布（路由）消息前                     |
| message.delivered    | 消息投递     | 消息准备投递到客户端前                         |
| message.acked        | 消息回执     | 服务端在收到客户端发回的消息 ACK 后            |
| message.dropped      | 消息丢弃     | 发布出的消息被丢弃后                           |


- 我们收到消息示例图如下：

![](webhook5.png)

- 上面配置之后我们就可以接收到EMQX推送过来的数据了，目前我们接口是没有做鉴权的。
- 如果需要接口安全，则可以在配置webhook，在header配置token之类的数据提高系统安全性


![](webhook6.png)

- 如上，配置token和userId,感兴趣的同学可以试试



## 三、总结

- 通过本文的介绍，我们了解了 Webhook 的基本概念、与传统 API 调用的区别、其工作机制和典型应用场景，并深入探讨了如何在 EMQX 中配置 Webhook 来实现事件驱动的消息推送。

- EMQX 作为一款功能强大的物联网消息中间件，借助 Webhook 插件可以将客户端连接、断开、订阅、发布等各类事件实时推送到外部业务服务器，极大地增强了系统的可扩展性和响应能力。这对于构建实时数据处理、设备状态监控、日志记录等业务场景具有重要意义。

- 在实际应用中，开发者可以根据自身业务需求灵活选择需要监听的事件类型，并通过编写接收 Webhook 请求的服务接口，完成对事件数据的处理、存储或转发到其他系统进行后续操作。

- 当然，在使用 Webhook 的过程中也要注意接口的安全性、稳定性以及错误重试机制的设计，以确保整个系统的可靠运行。

- 总之，Webhook 是一种轻量级、高效且易于集成的通信方式，结合 EMQX 使用，能够帮助我们更好地构建智能、高效的物联网平台。
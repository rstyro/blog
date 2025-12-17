---
title: Springboot2接口加解密全过程详解(含前端代码)
date: 2020-10-22 14:25:11
updated: 2020-10-22 14:25:11
tags: [Spring Boot]
categories: Java
---

### 前言

在数据安全日益重要的今天，仅靠HTTPS就够了吗？对于敏感业务接口，我们往往需要额外一层的应用级加密。今天，就和大家深入聊聊接口加密的**核心思路**与**SpringBoot一站式实现方案**。

<!--more-->

## 一、接口为什么要加密

接口加密的核心目的，用四个字概括就是：**保护数据**。具体体现在：
- **防泄漏**：防止敏感数据（如用户身份、交易信息）在传输过程中被截获。
- **防篡改**：确保接收到的数据就是发送方发出的原始数据，未被中间人修改。
- **防重放**：防止攻击者截获合法请求后，重复发送进行恶意操作。
- **抗伪装**：为客户端与服务端的双向身份验证提供基础。



当然不是说接口加密后，就能完完全全的保护我们的数据，但至少能防一部分人拿到我们的数据。而且接口加密在提升数据安全性的同时，也让系统的安全层级更上一层。而且接口加密感觉逼格是不是高过一点！！！



## 二、加密思路

### 1、加密简介
加密算法有很多，在能加密又能解密的算法可分为：
- 非对称加密算法，常见：`RSA`、`DSA`、`SM2`、`ECC`
    - 非对称加密：加密和解密用 **一对不同但配对的密钥**（公钥 + 私钥），两者是 “唯一绑定” 的
    - 特点：算法复杂，加解密速度慢，但安全性高。
    - 一般与对称加密结合使用(对称加密对内容加密，非对称对对称所使用的密钥加密)

- 对称加密算法，常见：`AES`、`DES`、`3DES`、`SM4`、`Blowfish`
    - 对称加密(也叫私钥加密)指加密和解密使用相同密钥的加密算法。有时又叫传统密码算法。
    - 特点：加密解密效率高，速度快，适合进行大数据量的加解密



单独用都有短板，混合使用才能扬长避短，我们选用混合加密：**RSA+AES**

**混合加密思路**：用AES加密业务数据（速度快），用RSA加密AES的密钥（安全性高），既保证效率又解决密钥传输问题。



### 2、加密流程
**思路**： 假设现在客户端是A，服务端是B，现在A要去B请求接口

**第一步：密钥交换**

- A生成RSA公私钥对，B也生成RSA公私钥对
- A和B互换公钥（公钥公开，私钥自己保存）



**第二步：数据传输**

- 客户端随机生成一个`AES密钥`。
- 客户端用服务端的`RSA公钥`加密这个`AES密钥`，并放在请求头（如key字段）中。
- 客户端用`AES密钥`加密业务报文，放在请求体。
- 服务端收到请求后，用自己的`RSA私钥`解开头部的key，得到`AES密钥`。
- 服务端用`AES密钥`解密请求体，得到明文数据，处理业务。
- 服务端返回响应时，用客户端的`RSA公钥`加密一个新的随机`AES密钥`，并用来加密响应体，流程同理。



这样做，既利用了非对称加密的安全性来完成最关键的密钥交换，又享受了对称加密处理业务数据时的高性能。





## 三、SpringBoot代码实现



**灵魂拷问**：如何在不改动既有业务代码的前提下，为接口统一加上加解密能力？

**答案是**：

- **方案一**：**使用 `@ControllerAdvice`配合 `RequestBodyAdvice`和 `ResponseBodyAdvice`**。这相当于在请求进入Controller之前和离开Controller之后，安插了两个“关卡”，进行自动化的解密/加密。
- **方案二**：**使用AOP通过 “环绕通知” 拦截目标接口**，在接口执行前解密请求参数，接口执行后加密返回值，全程不侵入业务代码。



用什么方案都行，如果没有特殊要求，其实用`方案一`更方便，因为它和SpringMVC 生命周期深度融合，兼容性更好。下面我们以`方案一`为例展开实现过程。



### 1、项目依赖准备

```xml
<!-- 用于加密处理 -->
<dependency>
    <groupId>top.lrshuai.encryption</groupId>
    <artifactId>encryption-tools</artifactId>
    <version>1.0.3</version>
</dependency>
<!-- 用于JSON处理 -->
<dependency>
    <groupId>com.alibaba</groupId>
    <artifactId>fastjson</artifactId>
    <version>1.2.83</version>
</dependency>
```

- encryption-tools 是自己搞的demo,可以用其他的第三方工具加密如：`hutool`也行



### 2、核心配置：密钥管理

```java
@Configuration
@Data
public class KeyConfig {

    /**
     * 服务端RSA公钥(给前端的)
     */
    @Value("${api.encrypt.rsa.publicKey}")
    private String rsaPublicKey;

    /**
     * 服务端RSA私钥（自己留存）
     */
    @Value("${api.encrypt.rsa.privateKey}")
    private String rsaPrivateKey;

    /**
     * 前端RSA公钥（客户端传给服务端的)
     */
    @Value("${api.encrypt.rsa.frontPublicKey}")
    private String frontRsaPublicKey;

    /**
     * aes向量 16位
     */
    @Value("${api.encrypt.aes.iv}")
    private String aesIv;

}
```

配置文件`application.yml`中添加密钥配置：

```yaml
api:
  encrypt:
    rsa:
      publicKey: MIGfMA0GCSqGSIb3DQEBAQUAA4GN...
      privateKey: MIICdgIBADANBgkqhkiG9w0BAQEFAASCAmAwggJc...
      frontPublicKey: MIGfMA0GCSqGSIb3DQEBA...
    aes:
      iv: 123456789abcdefh
```



### 3、自定义注解：控制接口是否加密

不是所有接口都需要加密（比如公开的查询接口），用注解标记需要加密的接口：



```java
/**
 * 返回数据是否加密
 * @author rstyro
 */
@Documented
@Inherited
@Target({ElementType.METHOD,ElementType.TYPE})
@Retention(RetentionPolicy.RUNTIME)
public @interface Encode {
}


/**
 * 接受参数是否需要解密
 * @author rstyro
 */
@Documented
@Inherited
@Target({ElementType.METHOD,ElementType.TYPE})
@Retention(RetentionPolicy.RUNTIME)
public @interface Decode {
}

/**
 * 组合注解，接受解密，返回加密
 * @author rstyro
 */
@Documented
@Inherited
@Target({ElementType.METHOD,ElementType.TYPE})
@Retention(RetentionPolicy.RUNTIME)
@Decode
@Encode
public @interface Encrypt {
}
```



### 4、 请求解密：RequestBodyAdvice实现

EncryptRequestAdvice类：在请求到达Controller前，自动解密前端传的加密数据，业务代码拿到的是原始数据。

```java
/**
 * 请求参数到controller之前的处理
 * @author rstyro
 */
@ControllerAdvice(basePackages = {"top.lrshuai.encrypt.controller"})
public class EncryptRequestAdvice implements RequestBodyAdvice {

    @Autowired
    private KeyConfig keyConfig;

    /**
     * 是否需要解码
     */
    private boolean isDecode;

    @Override
    public boolean supports(MethodParameter methodParameter, Type type, Class<? extends HttpMessageConverter<?>> aClass) {
        // 方法或类上有注解
        if (Utils.hasMethodAnnotation(methodParameter,new Class[]{Encrypt.class,Decode.class})) {
            isDecode=true;
            // 这里返回true 才支持
            return true;
        }
        return false;
    }

    @Override
    public HttpInputMessage beforeBodyRead(HttpInputMessage httpInputMessage, MethodParameter methodParameter, Type type, Class<? extends HttpMessageConverter<?>> aClass) throws IOException {
        if(isDecode){
            return new DecodeInputMessage(httpInputMessage, keyConfig);
        }
        return httpInputMessage;
    }

    @Override
    public Object afterBodyRead(Object obj, HttpInputMessage httpInputMessage, MethodParameter methodParameter, Type type, Class<? extends HttpMessageConverter<?>> aClass) {
        // 这里就是已经读取到body了，obj就是
        return obj;
    }

    @Override
    public Object handleEmptyBody(Object obj, HttpInputMessage httpInputMessage, MethodParameter methodParameter, Type type, Class<? extends HttpMessageConverter<?>> aClass) {
        // body 为空的时候调用
        return obj;
    }

}
```

#### 解密工具类：DecodeInputMessage

具体的解密逻辑封装在这里，负责从请求头拿加密的AES密钥，解密后得到原始业务数据：

```java
public class DecodeInputMessage implements HttpInputMessage {

    private HttpHeaders headers;
    private InputStream body;

    public DecodeInputMessage(HttpInputMessage httpInputMessage, KeyConfig keyConfig) {
        this.headers = httpInputMessage.getHeaders();
        try {
            // 1. 从请求头获取加密后的AES密钥
            String encodeAesKey = headers.getFirst("key");
            if (StringUtils.isEmpty(encodeAesKey)) {
                throw new RuntimeException("请求头缺少加密密钥key");
            }

            // 2. 用服务端RSA私钥解密AES密钥
            String decodeAesKey = RsaUtils.decodeBase64ByPrivate(keyConfig.getRsaPrivateKey(), encodeAesKey);

            // 3. 读取请求体中的AES加密数据
            String encodeContent = new BufferedReader(
                    new InputStreamReader(httpInputMessage.getBody(), StandardCharsets.UTF_8)
            ).lines().collect(Collectors.joining());

            // 4. 用AES密钥解密业务数据
            String aesDecode = AesUtils.decodeBase64(
                    encodeContent,
                    decodeAesKey,
                    keyConfig.getAesIv().getBytes(),
                    AesUtils.CIPHER_MODE_CBC_PKCS5PADDING
            );

            // 5. 把解密后的原始数据转为InputStream，供Controller读取
            this.body = new ByteArrayInputStream(aesDecode.getBytes(StandardCharsets.UTF_8));
        } catch (Exception e) {
            // 生产环境建议用日志框架，不要直接打印堆栈
            log.error("请求解密失败", e);
            throw new RuntimeException("接口解密异常");
        }
    }

    @Override
    public InputStream getBody() throws IOException {
        return body;
    }

    @Override
    public HttpHeaders getHeaders() {
        return headers;
    }
}
```

### 5、 响应加密：ResponseBodyAdvice实现

EncryptResponseAdvice类：对Controller的返回值自动加密，前端拿到的是加密后的数据：

```java
@Slf4j
@ControllerAdvice(basePackages = {"top.lrshuai.encrypt.controller"})
public class EncryptResponseAdvice implements ResponseBodyAdvice<Object> {

    @Autowired
    private KeyConfig keyConfig;

    @Override
    public boolean supports(MethodParameter methodParameter, Class<? extends HttpMessageConverter<?>> aClass) {
        return true; // 统一拦截，后续再判断是否需要加密
    }

    /**
     * 核心加密逻辑：在返回响应前执行
     */
    @Override
    public Object beforeBodyWrite(Object obj, MethodParameter methodParameter, MediaType mediaType, Class<? extends HttpMessageConverter<?>> aClass, ServerHttpRequest serverHttpRequest, ServerHttpResponse serverHttpResponse) {
        // 只有标记了@Encrypt的接口才加密
        if (Utils.hasMethodAnnotation(methodParameter, new Class[]{Encrypt.class})) {
            if (obj instanceof Result) {
                try {
                    // 1. 随机生成AES密钥（每次请求都不一样，更安全）
                    String randomAesKey = AesUtils.generateSecret(256);

                    // 2. 取出响应数据体，转为JSON字符串
                    Object data = ((Result) obj).getData();
                    String jsonData = JSON.toJSONString(data);

                    // 3. 用AES密钥加密业务数据
                    String aesEncryptData = AesUtils.encodeBase64(
                            jsonData,
                            randomAesKey,
                            keyConfig.getAesIv().getBytes(),
                            AesUtils.CIPHER_MODE_CBC_PKCS5PADDING
                    );

                    // 4. 用前端RSA公钥加密AES密钥（前端用自己的私钥解密）
                    String encryptAesKey = RsaUtils.encodeBase64PublicKey(keyConfig.getFrontRsaPublicKey(), randomAesKey);

                    // 5. 重新设置响应数据：加密后的业务数据+加密后的AES密钥
                    ((Result) obj).setData(aesEncryptData);
                    ((Result) obj).setKey(encryptAesKey);
                } catch (Exception e) {
                    log.error("响应加密失败", e);
                }
            }
        }
        return obj;
    }
}
```





## 四、前端配套实现（Vue示例）
前端需要配合完成“加密请求→解密响应”的流程，核心依赖两个库：
- `jsencrypt`：处理RSA加密（推荐增强版，支持长数据加密）
- `CryptoJS`：处理AES加密（Google开源，稳定可靠）

然后我使用的是Vue写的简单页面（业余前端）


### 1、核心代码实现
```html
<!DOCTYPE html>
<html lang="en" xmlns:th="http://www.thymeleaf.org">
<head>
    <meta charset="UTF-8">
    <title>请求</title>

    <style>
        #app {
            width: 500px;
            height: 500px;
            margin: 100px auto;
        }

        .mytable {
            border: 1px solid #A6C1E4;
            font-family: Arial;
            border-collapse: collapse;
        }

        table th {
            border: 1px solid black;
            background-color: #71c1fb;
            width: 100px;
            height: 20px;
            font-size: 15px;
        }

        table td {
            border: 1px solid #A6C1E4;
            text-align: center;
            height: 15px;
            padding-top: 5px;
            font-size: 12px;
        }

        .double {
            background-color: #c7dff6;
        }

        input {
            width: 95%;
            padding-left: 10px;
        }
    </style>
</head>
<body>
<div id="app">
    <table class="mytable">
        <tr class="double">
            <th>字段:</th>
            <th>Value:</th>
        </tr>
        <tr class="double">
            <td>userId:</td>
            <td><input v-model="userInfo.userId"></td>
        </tr>
        <tr class="double">
            <td>userName:</td>
            <td><input v-model="userInfo.userName"></td>
        </tr>
        <tr class="double">
            <td>age:</td>
            <td><input v-model="userInfo.age"></td>
        </tr>
        <tr class="double">
            <td>info:</td>
            <td>
                <textarea v-model="userInfo.info" cols="50" rows="5" placeholder="随便输一点"></textarea>
            </td>
        </tr>
        <tr class="double">
            <td>AES密钥:</td>
            <td>
                <textarea v-model="aes.key" cols="50" rows="2" placeholder="AES密钥"></textarea>
            </td>
        </tr>
        <tr class="double">
            <td>AES向量:</td>
            <td>
                <textarea v-model="aes.iv" cols="50" rows="1" placeholder="向量的长度为16位"></textarea>
            </td>
        </tr>
    </table>
    <button @click="testRequest">发送测试请求</button>
    <br>
    <div>
        <p>要发送的数据：<span>{{parameter}}</span></p>
        <p>加密后的数据：{{encodeContent}}</p>
        <br>
        <p>收到服务端的内容：{{result}}</p>
        <p>解密服务端AES密钥内容：{{decodeAes}}</p>
        <p>最终拿到服务端的内容：{{decodeContent}}</p>

    </div>
</div>
<script src="../static/js/vue.min.js" th:src="@{js/vue.min.js}"></script>
<script src="../static/js/rsa/jsencrypt.min.js" th:src="@{js/rsa/jsencrypt.min.js}"></script>
<script src="../static/js/aes/aes.js" th:src="@{js/aes/aes.js}"></script>
<script src ="https://unpkg.com/axios/dist/axios.min.js"></script>
<script>
    window.onload = function () {
        var vm = new Vue({
            el: '#app',
            data: {
                rsa: {
                    // 自己的rsa公私钥
                    mePublicKey: "MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCf0B4Al2wIuGK9Bj9Ao23siR2mMfkvdrxEGu2j0tNeA1LSyKOuw7FLmreRMYLCQMI4BTJNYsxUqvdS8IxFpD5hOx9mx6OqY2GQSIZq5a1lt3Rx4SpDiuuVGm7h5uuLN7bvMfaLBW3g4E5DAKapuZ/u5ULO+y2jczVXkaSb1IjNnwIDAQAB",
                    mePrivateKey:"MIICdQIBADANBgkqhkiG9w0BAQEFAASCAl8wggJbAgEAAoGBAJ/QHgCXbAi4Yr0GP0CjbeyJHaYx+S92vEQa7aPS014DUtLIo67DsUuat5ExgsJAwjgFMk1izFSq91LwjEWkPmE7H2bHo6pjYZBIhmrlrWW3dHHhKkOK65UabuHm64s3tu8x9osFbeDgTkMApqm5n+7lQs77LaNzNVeRpJvUiM2fAgMBAAECgYAq4FxcTkPm5wleq4Fm5zIDxxnUUA4J5PJH122wiUy6KWwcL0ZzCf/UR/M+Gil50oQJIaPITVyCzsfCUdVgjdtKL7x8e1dQwlI3/DLEat02Njj4fl6KsMq9EqLyleq0UdgYtevZOOoi+ZKXlqZjkM3yOsbwyu9u0D+s77KfHihwuQJBAODhWKTLywJwSXPC6CvlSoyCjscWgUadk8IN+ELyLq591DYFCQllYQPyMj8Cy0dY5OC9GvwRLZurs9LGi6C9d0UCQQC17a76RNHqmmGKsEEGIx3XIzvDrjSRmE3v+NLMcf+JUaUJiKmedDZeWnJuxIXVmFbHi2bzCb2NXUYqhuXsuJ2TAkBHxSO5VKEx4gxPOcFHYSJtva07tN8FXn0tza+SDiD/54C2zNyZdxWDYOTQX1/pIWHKqA/YqtLXf/EgL+WYI1/RAkAk+RwRgsECo8NlEzLz01kyKtfvicznNgPI3FHC+PwM5UncKSkHqeiOvmT5O/lTEnW4cg1HIVijjSxAYlACDvb/AkBmwlv6+gLoKpCU6h7+J6OxB9GKM2Hjs3Mh5tgXgveCwMg2Knz+RPIj92jq7CLm20xs2654yYnyHc4V+kzr3Zu1",
                    // 后端的rsa公钥
                    backPublicKey: "MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCJvCDW9GIBsiv9ma9r2btffIxQQHB98Pl1S2RV2PrQsK1O2yFSUf8P43l5EfAh+jiEn/k5egKEoeMRLdDZkt5afNgPYbNjiRFJP8NZTw4f3Yxp91+d04GGkeFcj59QIn/rqqHo2JLOESNae8IC1tKKQTqkwVIjLRwTIDcVmsq9NwIDAQAB"
                },
                aes: {
                    iv: "123456789abcdefh",
                    key:"",
                    encodeKey:""
                },
                userInfo: {
                    userId: "1",
                    userName: "rstyro",
                    age: 20,
                    info: "信息内容......",
                },
                parameter: "",
                encodeContent: "",
                decodeContent: "",
                decodeAes: "",
                result: ""
            },
            http: {
                root: '/',
                headers: {
                    loginToken: "asdb",
                }
            },
            methods: {
                testRequest: function () {
                    // 随机生成32位  aes 密钥
                    this.aes.key=generateKey();
                    // 参数转json 字符串
                    this.parameter = JSON.stringify(this.userInfo);
                    // aes 加密
                    this.encodeContent = aesEncode(this.parameter,this.aes.iv,this.aes.key);
                    // rsa 后端公钥加密aes密钥
                    let encodeAesKey = rsaEncode(this.rsa.backPublicKey,this.aes.key);
                    this.aes.encodeKey=encodeAesKey;
                    console.log("encodeAeskey:",this.aes.encodeKey);
                    axios.post('http://localhost:8800/test1', this.encodeContent,{
                        headers: {
                            "Content-Type": "application/json;charset=utf-8",
                            key:encodeAesKey
                        }
                    }).then(function (response) {
                        console.log("response:",response);
                        // 1、服务端返回的数据
                        vm.result=response.data;
                        // 2、rsa 解密拿到aes密钥
                        vm.decodeAes = rsaDecode(vm.rsa.mePrivateKey,vm.result.key);
                        // 3、aes 解密
                        vm.decodeContent = aesDecode(vm.result.data,vm.aes.iv,vm.decodeAes);
                    }).catch(function (error) {
                        console.log("error:",error);
                    });
                }
            }
        });
    }

    // aes 加密
    function aesEncode(content,iv,aesKey){
        iv = CryptoJS.enc.Utf8.parse(iv);
        aesKey = CryptoJS.enc.Utf8.parse(aesKey);
        let encrypted = CryptoJS.AES.encrypt(content, aesKey, {
            iv: iv,
            mode: CryptoJS.mode.CBC,
            padding: CryptoJS.pad.Pkcs7
        });
        return  encrypted.toString();
    }

    // aes 解密
    function aesDecode(encrypted,iv,aesKey){
        iv = CryptoJS.enc.Utf8.parse(iv);
        aesKey = CryptoJS.enc.Utf8.parse(aesKey);
        var decrypted = CryptoJS.AES.decrypt(encrypted, aesKey, {
            iv: iv,
            mode: CryptoJS.mode.CBC,
            padding: CryptoJS.pad.Pkcs7
        });
        // 转换为 utf8 字符串
        return CryptoJS.enc.Utf8.stringify(decrypted);
    }

    // rsa 公钥加密
    function rsaEncode(publicKey,content){
        // 加密+base64
        const encrypt = new JSEncrypt();
        // 设置公钥
        encrypt.setPublicKey('-----BEGIN PUBLIC KEY-----' + publicKey + '-----END PUBLIC KEY-----');
        return encrypt.encryptLong(content);
    }

    // rsa 私钥解密
    function rsaDecode(privateKey,content){
        // 加密+base64
        const encrypt = new JSEncrypt();
        encrypt.setPrivateKey(privateKey);
        return encrypt.decryptLong(content);
    }

    //随机生成aes 密钥
    function generateKey(){
        return CryptoJS.lib.WordArray.random(128/8).toString();
    }

</script>
</body>
</html>
```
核心逻辑集中在`testRequest()`方法，完成“生成AES密钥→加密业务数据→加密AES密钥→发送请求→解密响应”的全流程，代码注释已清晰标注关键步骤。



### 2、注意点
- 后端需要注意的就是，controller参数需要用`@RequestBody`包起来,如下：
```
@PostMapping("/test1")
@ResponseBody
public Object test1(@RequestBody(required = false) TestDto dto){
	System.out.println("dto="+dto);
	return Result.ok(dto);
}
```
-  而前端传上来的时候`header`需要设置`"Content-Type": "application/json;charset=utf-8"`，确保请求体格式与后端解析方式一致。



### 3、最终效果

![](test.png)

![](postman.png)

**在上面的postman中**
+ `data`：里面的数据就是aes加密后的数据
+ `key`：里面就是前端RSA公钥加密后的AES密钥(前端需要用私钥解密得到aes密钥，然后再用密钥解开data里面的数据)
+ `status`：这个是状态码，如果报错了就不是200，不然报错了返回的数据，前端解几百年都解不开。





## 五、最后



接口加密不仅是技术需求，更是对用户数据负责的体现。希望本文提供的**核心思路**与**完整实现**，能帮助你快速在项目中落地应用级加密，筑牢数据安全的第一道防线。



#### 扩展价值

本文方案具备良好的可扩展性，可根据业务需求快速迭代：

- **国密算法替换**：将RSA替换为SM2、AES替换为SM4，满足金融、政务等领域的国产化合规要求。
- **分布式场景适配**：密钥配置存入分布式配置中心，确保集群中所有节点密钥一致，支持水平扩展。
- **全链路加密**：结合网关（如Spring Cloud Gateway）实现入口层统一加密，搭配服务间调用加密（如Dubbo接口加密），构建全链路数据安全体系。




#### 源码地址

- 文中所有代码都已整理成可运行的Demo，包含SpringBoot后端、Vue前端、密钥生成工具，直接下载即可运行。
- 欢迎 Star ⭐ 和 Fork：：
    - Github地址：https://github.com/rstyro/Springboot/tree/master/Springboot2-api-encrypt
    - Gitee地址（国内快）：https://gitee.com/rstyro/spring-boot/tree/master/Springboot2-api-encrypt





**✨ 一个小小的邀请**

如果这篇文章帮你理清了思路，**不妨点个「赞&关注」**。

**期待在评论区，看到你的故事。** 我们一起，把代码写得更明白。
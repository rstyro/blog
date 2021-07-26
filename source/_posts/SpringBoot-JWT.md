---
title: SpringBoot-JWT
date: 2019-04-16 17:41:59
tags: [Spring Boot,JWT]
categories: Java
---

## 一、什么是JSON Web Token？
JSON Web Token（JWT）是一个开放标准（RFC7519），它定义了一种紧凑且独立的方式，用于在各方之间作为JSON对象安全地传输信息。  
此信息可以通过数字签名进行验证和信任。JWT可以使用秘密（使用HMAC算法）或使用RSA或ECDSA的公钥/私钥对进行签名。


## 二、JWT的使用场景主要包括：
+ 认证授权 
	这是比较常见的使用场景，只要用户登录过一次系统，之后的请求都会包含签名出来的token，通过token也可以用来实现单点登录。  
	因为它的开销很小，并且能够在不同的域中轻松使用。
+ 交换信息
	JSON Web令牌是在各方之间安全传输信息的好方法。因为JWT可以签名 - 例如，使用公钥/私钥对 - 您可以确定发件人是他们所说的人。此外，由于使用标头和有效负载计算签名，您还可以验证内容是否未被篡改。
	

## 三、JWT 的组成结构
实际的 jwt 产生的token，大概长得如下的格式
```
eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.
eyJzdWIiOiJ0ZXN0IiwiYXVkIjpbImFwcCIsIndlYiJdLCJkYXRhIjoie1wiYWdlXCI6MjQsXCJzZXhcIjoxLFwidXNlcklkXCI6MSxcInVzZXJuYW1lXCI6XCLluIXlpKflj5RcIn0iLCJpc3MiOiJyc3R5cm8iLCJleHAiOjE1NTUzOTg5NjIsImlhdCI6MTU1NTM5ODg0Mn0.
N1PbxQ1okvw-q8TWiSX0uMx1z6QL6IEUBtOfcwP7-Mg
```
它是一个很长的字符串，中间用点（.）分隔成三个部分。  
+ Header（头部）
+ Payload（负载）
+ Signature（签名）
 
> 注意，JWT 内部是没有换行的，这里只是为了便于展示，将它写成了几行  

### 1、Header（头部）
标头通常由两部分组成：令牌的类型，即JWT，以及正在使用的签名算法，例如HMAC SHA256或RSA。  
例如：
```
{
  "alg": "HS256",
  "typ": "JWT"
}
```
然后，这个JSON被编码为Base64Url，形成JWT的第一部分。  

### 2、Payload（负载）
令牌的第二部分是有效负载，其中包含声明。声明是关于实体（通常是用户）和其他数据的声明  
这个部分一般就是我们需要存贮的数据都放在这里。  
JWT 规定了7个官方字段，供选用。
```
iss (issuer)：发布者
sub (subject)：主题
iat (Issued At)：生成签名的时间
exp (expiration time)：签名过期时间
aud (audience)：观众，相当于接受者
nbf (Not Before)：生效时间
jti (JWT ID)：编号
```
当然，也可以自定义字段，例如下面的 `data` 字段  

```
{
  "sub": "test",
  "aud": [
    "app",
    "web"
  ],
  "nbf": 1555399851,
  "data": "{\"age\":24,\"sex\":1,\"userId\":1,\"username\":\"帅大叔\"}",
  "iss": "rstyro",
  "exp": 1555399971,
  "iat": 1555399851,
  "jti": "75f67651-4cc8-431a-9429-c15df52d5acd"
}
```
然后经过Base64Url编码，形成JSON Web令牌的第二部分  

### 3、Signature（签名）
Signature 部分是对前两部分的签名，防止数据篡改。
首先，需要指定一个密钥（secret）。这个密钥只有服务器才知道，不能泄露给用户。然后，使用 Header 里面指定的签名算法（默认是 HMAC SHA256），按照下面的公式产生签名
```
HMACSHA256(
  base64UrlEncode(header) + "." +
  base64UrlEncode(payload),
  secret)
```
算出签名以后，把 Header、Payload、Signature 三个部分拼成一个字符串，每个部分之间用"点"（.）分隔，就可以返回给用户。  


### 4、Base64URL
前面提到，`Header` 和 `Payload` 串型化的算法是 `Base64URL`。这个算法跟 `Base64` 算法基本类似，但有一些小的不同。

JWT 作为一个令牌`token`，有些场合可能会放到 URL（比如 `api.example.com/?token=xxx`）。Base64 有三个字符`+`、`/`和`=`，在 URL 里面有特殊含义，所以要被替换掉：`=`被省略、`+`替换成`-`，`/`替换成`_` 。这就是 `Base64URL` 算法


## 四、JWT 的特点
#### 1、号外
就我现在所知道的，互联网服务中的用户认证方式 有两种：
+ SessionId
比如，用户在浏览器中用户名密码登录成功之后，浏览器每次发请求都会自己带上sessionid 发送给服务器。服务器通过sessionID 得到用户信息
+ TOKEN
token,一般在手机app 端比较常用的方式，那就是用户登录成功之后，服务器返回一个 授权的token 字符串，app 每次请求也要带着这个token 转到服务器，服务器通过 token 得到用户信息 

如上两种方式都很类似，换汤不换药。它们的相同点就是：认证信息都保存在后端服务器  
而JWT 和 它们的区别就是：认证信息保存在了客户端，减轻服务端的内存压力。


#### 2、特点
+ JWT是无状态的，特别适用于分布式站点的单点登录（SSO）场景
+ JWT 不仅可以用于认证，也可以用于交换信息。有效使用 JWT，可以降低服务器查询数据库的次数。
+ 因为有签名，所以JWT可以防止被篡改
+ 由于JWT的payload是使用base64编码的，并没有加密，因此JWT中不能存储敏感数据。而session的信息是存在服务端的，相对来说更安全。
+ 由于是无状态使用JWT，所有的数据都被放到JWT里，如果还要进行一些数据交换，那载荷会很大，经过编码之后导致JWT非常长
+ JWT是一次性的。想修改里面的内容，就必须签发一个新的JWT
+ 一旦签发一个JWT，在到期之前就会始终有效，无法中途废弃。



## 五、JWT 的加密方式
JWT签名算法中，一般有两个选择，一个采用`HS256`,另外一个就是采用`RS256`。
签名实际上是一个加密的过程，生成一段标识（也是JWT的一部分）作为接收方验证信息是否被篡改的依据。
RS256 (采用`SHA-256` 的 `RSA` 签名) 是一种非对称算法, 它使用公共/私钥对: 标识提供方采用私钥生成签名, JWT 的使用方获取公钥以验证签名。由于公钥 (与私钥相比) 不需要保护, 因此大多数标识提供方使其易于使用方获取和使用 (通常通过一个元数据URL)。
另一方面, `HS256` (带有 `SHA-256` 的 `HMAC` 是一种对称算法, 双方之间仅共享一个 密钥。由于使用相同的密钥生成签名和验证签名, 因此必须注意确保密钥不被泄密。
在开发应用的时候启用JWT，使用`RS256`更加安全，你可以控制谁能使用什么类型的密钥。另外，如果你无法控制客户端，无法做到密钥的完全保密，`RS256`会是个更佳的选择，JWT的使用方只需要知道公钥。
由于公钥通常可以从元数据URL节点获得，因此可以对客户端进行进行编程以自动检索公钥。如果采用这种方式，从服务器上直接下载公钥信息，可以有效的减少配置信息



## 六、JWT 代码实现
在[官网:jwt.io](https://jwt.io/#libraries)中有各个语言的库可以使用,我用的是 auth0 的Java.  
地址：[https://github.com/auth0/java-jwt](https://github.com/auth0/java-jwt)  
#### 1、导入依赖
```
<dependency>
	<groupId>com.auth0</groupId>
	<artifactId>java-jwt</artifactId>
	<version>3.8.0</version>
</dependency>
```
#### 2、生成Token
有两种方式：  
+ HS256 方式
```
try {
    Algorithm algorithm = Algorithm.HMAC256("secret");
    String token = JWT.create()
                .withIssuer("rstyro")   //发布者
                .withSubject("test")    //主题
                .withAudience(audience)     //观众，相当于接受者
                .withIssuedAt(new Date())   // 生成签名的时间
                .withExpiresAt(DateUtils.offset(new Date(),2, Calendar.MINUTE))    // 生成签名的有效期,分钟
                .withClaim("data", JSON.toJSONString("Object")) //自定义字段存数据
                .withNotBefore(new Date())  //生效时间
                .withJWTId(UUID.randomUUID().toString())    //编号
                .sign(algorithm);
} catch (JWTCreationException exception){
    //签名不匹配
}
```

+ RS256 方式
```
RSAPublicKey publicKey = //Get the key instance
RSAPrivateKey privateKey = //Get the key instance
try {
    Algorithm algorithm = Algorithm.RSA256(publicKey, privateKey);
    String token = JWT.create()
                .withIssuer("rstyro")   //发布者
                .withSubject("test")    //主题
                .withAudience(audience)     //观众，相当于接受者
                .withIssuedAt(new Date())   // 生成签名的时间
                .withExpiresAt(DateUtils.offset(new Date(),2, Calendar.HOUR_OF_DAY))    // 生成签名的有效期,小时
                .withClaim("data", JSON.toJSONString("Object")) //自定义字段存数据
                .withNotBefore(new Date())  //生效时间
                .withJWTId(UUID.randomUUID().toString())    //编号
                .sign(algorithm);
} catch (JWTCreationException exception){
    //签名不匹配
}
```

#### 3、校验 Token
片段代码如下：
```
if("RS256".equalsIgnoreCase(jwtdto.getAlg())){
	algorithm = Algorithm.RSA256(CreateSecrteKey.getRSA256Key().getPublicKey(), null);
}else {// hs256 的方式
	algorithm = Algorithm.HMAC256(secret);
}
JWTVerifier verifier = JWT.require(algorithm)
		.withIssuer("rstyro")
		.build();
try {
	verify = verifier.verify(jwtdto.getToken());
}catch (TokenExpiredException ex){
	throw new ApiException(ApiResultEnum.TOKEN_EXPIRED);
}catch (JWTVerificationException ex){
	throw new ApiException(ApiResultEnum.SIGN_VERIFI_ERROR );
}
```

因为 RS256 加密，需要一个公私钥对，我们可以通过 `KeyPairGenerator` 随机获取一个公私钥对，工具类如下：
```java
import sun.misc.BASE64Decoder;
import sun.misc.BASE64Encoder;
import top.lrshuai.jwt.entity.RSA256Key;

import java.security.Key;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.interfaces.RSAPrivateKey;
import java.security.interfaces.RSAPublicKey;
import java.util.HashMap;
import java.util.Map;

/**
 * 抄录地址：https://www.cnblogs.com/only-jlk/p/5960900.html
 */
public class CreateSecrteKey {

    public static final String KEY_ALGORITHM = "RSA";
    private static final String PUBLIC_KEY = "RSAPublicKey";
    private static final String PRIVATE_KEY = "RSAPrivateKey";

    private static RSA256Key rsa256Key;

    //获得公钥
    public static String getPublicKey(Map<String, Object> keyMap) throws Exception {
        //获得map中的公钥对象 转为key对象
        Key key = (Key) keyMap.get(PUBLIC_KEY);
        //byte[] publicKey = key.getEncoded();
        //编码返回字符串
        return encryptBASE64(key.getEncoded());
    }
    public static String getPublicKey(RSA256Key rsa256Key) throws Exception {
        //获得map中的公钥对象 转为key对象
        Key key = rsa256Key.getPublicKey();
        //byte[] publicKey = key.getEncoded();
        //编码返回字符串
        return encryptBASE64(key.getEncoded());
    }

    //获得私钥
    public static String getPrivateKey(Map<String, Object> keyMap) throws Exception {
        //获得map中的私钥对象 转为key对象
        Key key = (Key) keyMap.get(PRIVATE_KEY);
        //byte[] privateKey = key.getEncoded();
        //编码返回字符串
        return encryptBASE64(key.getEncoded());
    }
    //获得私钥
    public static String getPrivateKey(RSA256Key rsa256Key) throws Exception {
        //获得map中的私钥对象 转为key对象
        Key key = rsa256Key.getPrivateKey();
        //byte[] privateKey = key.getEncoded();
        //编码返回字符串
        return encryptBASE64(key.getEncoded());
    }

    //解码返回byte
    public static byte[] decryptBASE64(String key) throws Exception {
        return (new BASE64Decoder()).decodeBuffer(key);
    }

    //编码返回字符串
    public static String encryptBASE64(byte[] key) throws Exception {
        return (new BASE64Encoder()).encodeBuffer(key);
    }

    //map对象中存放公私钥
    public static Map<String, Object> initKey() throws Exception {
        //  /** RSA算法要求有一个可信任的随机数源 */
        //获得对象 KeyPairGenerator 参数 RSA 1024个字节
        KeyPairGenerator keyPairGen = KeyPairGenerator.getInstance(KEY_ALGORITHM);
        keyPairGen.initialize(1024);
        //通过对象 KeyPairGenerator 生成密匙对 KeyPair
        KeyPair keyPair = keyPairGen.generateKeyPair();

        //通过对象 KeyPair 获取RSA公私钥对象RSAPublicKey RSAPrivateKey
        RSAPublicKey publicKey = (RSAPublicKey) keyPair.getPublic();
        RSAPrivateKey privateKey = (RSAPrivateKey) keyPair.getPrivate();
        //公私钥对象存入map中
        Map<String, Object> keyMap = new HashMap<String, Object>(2);
        keyMap.put(PUBLIC_KEY, publicKey);
        keyMap.put(PRIVATE_KEY, privateKey);
        return keyMap;
    }

    /**
     * 获取公私钥
     * @return
     * @throws Exception
     */
    public static synchronized RSA256Key getRSA256Key() throws Exception {
        if(rsa256Key == null){
            synchronized (RSA256Key.class){
                if(rsa256Key == null) {
                    rsa256Key = new RSA256Key();
                    Map<String, Object> map = initKey();
                    rsa256Key.setPrivateKey((RSAPrivateKey) map.get(CreateSecrteKey.PRIVATE_KEY));
                    rsa256Key.setPublicKey((RSAPublicKey) map.get(CreateSecrteKey.PUBLIC_KEY));
                }
            }
        }
        return rsa256Key;
    }

    public static void main(String[] args) {
        Map<String, Object> keyMap;
        try {
            keyMap = initKey();
            String publicKey = getPublicKey(keyMap);
            System.out.println("公钥：\n"+publicKey);
            String privateKey = getPrivateKey(keyMap);
            System.out.println("私钥：\n"+privateKey);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
```

## 完整代码地址
+ Github地址：[https://github.com/rstyro/Springboot/tree/master/SpringBoot-JWT](https://github.com/rstyro/Springboot/tree/master/SpringBoot-JWT)
+ Gitee 地址：[https://gitee.com/rstyro/spring-boot/tree/master/SpringBoot-JWT](https://gitee.com/rstyro/spring-boot/tree/master/SpringBoot-JWT)


#### 参考链接：
+ [https://jwt.io/introduction/](https://jwt.io/introduction/)
+ [http://www.ruanyifeng.com/blog/2018/07/json_web_token-tutorial.html](http://www.ruanyifeng.com/blog/2018/07/json_web_token-tutorial.html)


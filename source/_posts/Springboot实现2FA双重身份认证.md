---
title: Springboot实现2FA双重身份认证
tags: [Spring Boot, Java,2FA]
categories: Java
date: 2025-11-02 16:27:05
updated: 2025-11-02 16:27:05
---


在数字化时代，我们的日常生活与网络紧密相连。从社交软件、电子邮箱到移动支付，大量敏感信息需要在互联网上传输和处理。然而，传统的密码作为最主要的身份验证方式，存在着诸多安全隐患。

<!--more-->

你是否曾使用过简单易记的密码？或者在多个网站使用相同的密码？这些习惯让我们在不知不觉中暴露在风险之中。据统计，超过80%的数据泄露事件都与弱密码或密码被盗有关。在这个背景下，双重认证（2FA）应运而生，成为保护我们数字身份的重要防线。



### 一、什么是2FA双因素身份验证



**2FA**，全称为**Two-Factor Authentication**，中文译为“双因素身份验证”或“二步验证”。它是一种安全认证机制，要求用户提供两种不同类型的证明来验证身份，然后才能获得访问权限。

传统的身份验证通常只依赖一个因素——你知道的东西（如密码）。而2FA在此基础上增加了另外两种认证因素之一：

- **你知道的东西**：密码、PIN码、安全问题的答案
- **你拥有的东西**：手机、安全密钥、智能卡
- **你自身的特征**：指纹、面部识别

只有当其中两类因素同时验证通过时，系统才会允许访问。举个例子，使用银行卡在**ATM**机取款就是一个典型的2FA应用：你需要同时提供银行卡（你拥有的东西）和密码（你知道的东西）才能完成操作。



在数字世界中，2FA通常表现为：输入正确密码后，系统还会向你的手机发送一个验证码，或要求你使用身份验证器应用生成一次性代码。这种双重检查机制大大提高了账户安全性。



### 二、2FA解决了什么问题

2FA主要解决了单一密码验证带来的多种安全隐患。



- **弱密码问题**
许多人为了便于记忆，会使用“123456”、“password”等简单密码，或者使用生日、姓名等容易被猜到的密码。2FA确保即使密码简单，攻击者仍难以入侵账户。

- **密码重复使用问题**
调查显示，平均每个网民需要管理超过100个在线账户，65%的人会在多个网站使用相同密码。一旦某个网站被攻破，攻击者就能用获得的密码尝试登录其他网站。2FA可以有效阻止这种**“撞库攻击”**。

- **网络钓鱼攻击**
网络钓鱼是获取用户密码的常见手段。攻击者通过伪造登录页面诱骗用户输入密码。即使密码被窃，没有第二因素验证，攻击者仍然无法登录真实账户。

- **暴力破解**
攻击者使用自动化工具尝试数百万种密码组合，直到找到正确的密码。2FA使得即使密码被猜中，账户仍然安全。

- **社会工程学攻击**
攻击者通过电话或电子邮件冒充合法机构，诱骗用户透露密码。2FA确保仅凭密码不足以控制账户。

- **设备丢失或被盗**
当你的设备丢失或被盗时，如果有密码保护的设备同时启用了2FA，那么发现设备的人将难以访问你的账户。



在企业环境中，2FA为网络设备提供额外保护层，防止未授权访问导致敏感信息泄露甚至系统瘫痪。对于远程访问场景，2FA更是确保只有授权人员能接入关键系统的重要保障





### 三、2FA怎么使用



2FA有多种实现方式，每种方式各有特点：

- **SMS短信验证码**
  这是最常见的2FA形式。在输入正确密码后，系统会向绑定的手机号发送包含验证码的短信。优点是简单易用，无需额外应用；缺点是可能受到SIM卡交换攻击或信号问题影响。

- **认证器应用程序**
  如`Google Authenticator`、`Microsoft Authenticator`、等应用可以生成基于时间的一次性密码(TOTP)。这些应用即使在没有网络的情况下也能工作，生成30秒有效期的验证码。相比SMS，这种方式更安全，不易被拦截。

- **硬件安全密钥**
如YubiKey、Google Titan等物理设备，通过USB、NFC或蓝牙与设备连接进行验证。提供最高级别的安全性，尤其能有效防范网络钓鱼攻击。

- **生物识别验证**
使用指纹、面部识别或虹膜扫描作为第二因素。常见于智能手机和笔记本电脑，平衡了安全性和便捷性。

- **推送通知验证**
系统向已认证的设备发送推送通知，用户只需点击“批准”或“拒绝”即可完成验证。用户体验友好，但需要稳定的网络连接。



现在比较常用的是**SMS短信验证码**，因为现在人人都有手机，而且这种方式对用户来说操作比较简单。第二个常用的就是使用 **身份验证器应用**（TOTP）,比如我常用的Github也是需要启动2FA认证了，我这里使用的就是身份验证器，给你们看看。




![Github 2FA认证示例图](auth.png)



身份验证器应用和服务端基于相同的密钥和相同的TOTP算法（通常是基于时间，每30秒变化一次）独立生成6位动态验证码



### 四、2FA实战身份验证器的实现



Google Authenticator 是谷歌推出的一种双因素身份验证（2FA）应用程序，它通过基于时间的一次性密码（TOTP）算法，为用户账户安全增加了一层强有力的保障 。下面我们全面解析如何用 Java 实现它。



首先我们需要新建2个工具类：`TOTP`（算法实现）和`GoogleAuthenticator`（业务封装）。代码如下：


```java
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.math.BigInteger;
import java.security.GeneralSecurityException;
import java.time.Instant;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;

/**
 * TOTP (Time-based One-Time Password) 算法实现
 * 基于 RFC 6238 标准，用于生成基于时间的一次性密码。
 * 该类是工具类，所有方法均为静态方法，不可实例化。
 * 功能特点：
 * - 支持 HMAC-SHA1、HMAC-SHA256、HMAC-SHA512 算法
 * - 可自定义密码位数（1-8位）和时间步长
 * - 提供密码验证功能，支持时间偏移容错
 * 使用示例：
 * String key = "3132333435363738393031323334353637383930";
 * String totp = TOTP.generateCurrentTOTP(key);
 * boolean isValid = TOTP.verifyTOTP(key, "123456");
 *
 * @author rstyro
 */
public final class TOTP {

    /**
     * 数字幂数组，用于计算10的n次方，索引对应位数（1-8位）
     * 例如：DIGITS_POWER[6] = 1000000
     */
    private static final int[] DIGITS_POWER = {1, 10, 100, 1000, 10000, 100000, 1000000, 10000000, 100000000};

    /** HMAC-SHA1 算法标识 */
    public static final String HMAC_SHA1 = "HmacSHA1";
    /** HMAC-SHA256 算法标识 */
    public static final String HMAC_SHA256 = "HmacSHA256";
    /** HMAC-SHA512 算法标识 */
    public static final String HMAC_SHA512 = "HmacSHA512";

    /** 默认动态密码位数（6位） */
    private static final int DEFAULT_DIGITS = 6;
    /** 默认时间步长（秒） */
    private static final long DEFAULT_TIME_STEP = 30L;
    /** 默认起始时间（Unix纪元） */
    private static final long DEFAULT_START_TIME = 0L;
    /** 默认验证时间窗口大小（允许前后偏移的步数） */
    private static final int DEFAULT_TIME_WINDOW = 1;

    /**
     * 私有构造方法，防止类实例化
     * 工具类应避免实例化，所有方法均为静态方法
     */
    private TOTP() {
        throw new AssertionError("TOTP 是工具类，不能实例化");
    }

    /**
     * 使用HMAC算法计算哈希值
     *
     * @param crypto   加密算法 (HmacSHA1, HmacSHA256, HmacSHA512)
     * @param keyBytes 密钥字节数组
     * @param text     要认证的消息文本
     * @return HMAC哈希值
     * @throws GeneralSecurityException 安全算法异常
     */
    private static byte[] hmacSha(String crypto, byte[] keyBytes, byte[] text)
            throws GeneralSecurityException {
        Mac hmac = Mac.getInstance(crypto);
        SecretKeySpec macKey = new SecretKeySpec(keyBytes, "RAW");
        hmac.init(macKey);
        return hmac.doFinal(text);
    }

    /**
     * 将十六进制字符串转换为字节数组
     *
     * @param hex 十六进制字符串
     * @return 字节数组
     * @throws IllegalArgumentException 当十六进制字符串格式错误时
     */
    private static byte[] hexStr2Bytes(String hex) {
        // 使用BigInteger处理十六进制字符串，确保正确转换
        byte[] bArray = new BigInteger("10" + hex, 16).toByteArray();
        byte[] ret = new byte[bArray.length - 1];
        System.arraycopy(bArray, 1, ret, 0, ret.length);
        return ret;
    }

    /**
     * 生成TOTP值
     *
     * @param key          共享密钥，十六进制编码字符串
     * @param time         时间计数器值，十六进制编码字符串
     * @param returnDigits  返回的TOTP位数，必须在1到8之间
     * @param crypto       加密算法，如 "HmacSHA1"
     * @return TOTP数值字符串，指定位数
     * @throws IllegalArgumentException 如果位数无效或参数错误
     * @throws RuntimeException 如果安全算法出错
     */
    public static String generateTOTP(String key, String time, int returnDigits, String crypto) {
        // 参数校验
        if (returnDigits < 1 || returnDigits > 8) {
            throw new IllegalArgumentException("TOTP位数必须在1到8之间");
        }
        if (key == null || key.isEmpty() || time == null || time.isEmpty()) {
            throw new IllegalArgumentException("密钥和时间参数不能为空");
        }

        // 时间字符串填充至16字符（64位十六进制表示）
        String paddedTime = time;
        while (paddedTime.length() < 16) {
            paddedTime = "0" + paddedTime;
        }

        try {
            byte[] msg = hexStr2Bytes(paddedTime);
            byte[] k = hexStr2Bytes(key);
            byte[] hash = hmacSha(crypto, k, msg);

            // 动态截取：取最后一字节的低4位作为偏移量
            int offset = hash[hash.length - 1] & 0x0f;

            // 从偏移位置取4字节，按大端序组合为整数
            int binary = ((hash[offset] & 0x7f) << 24)
                    | ((hash[offset + 1] & 0xff) << 16)
                    | ((hash[offset + 2] & 0xff) << 8)
                    | (hash[offset + 3] & 0xff);

            // 取模得到指定位数的TOTP值
            int otp = binary % DIGITS_POWER[returnDigits];

            // 格式化为指定位数字符串，不足位补零
            return String.format("%0" + returnDigits + "d", otp);

        } catch (GeneralSecurityException e) {
            throw new RuntimeException("TOTP生成安全错误: " + e.getMessage(), e);
        } catch (Exception e) {
            throw new RuntimeException("TOTP生成失败: " + e.getMessage(), e);
        }
    }


    /**
     * 生成TOTP（默认6位数，HMAC-SHA1算法）
     */
    public static String generateTOTP(String key, String time) {
        return generateTOTP(key, time, DEFAULT_DIGITS, HMAC_SHA1);
    }

    /**
     * 生成TOTP（指定位数，HMAC-SHA1算法）
     */
    public static String generateTOTP(String key, String time, int returnDigits) {
        return generateTOTP(key, time, returnDigits, HMAC_SHA1);
    }

    /**
     * 生成TOTP（指定位数，HMAC-SHA256算法）
     */
    public static String generateTOTP256(String key, String time, int returnDigits) {
        return generateTOTP(key, time, returnDigits, HMAC_SHA256);
    }

    /**
     * 生成TOTP（指定位数，HMAC-SHA512算法）
     */
    public static String generateTOTP512(String key, String time, int returnDigits) {
        return generateTOTP(key, time, returnDigits, HMAC_SHA512);
    }

    /**
     * 基于当前时间生成TOTP
     * @param key 共享密钥（十六进制字符串）
     * @return TOTP值（6位数）
     */
    public static String generateCurrentTOTP(String key) {
        long currentTime = System.currentTimeMillis() / 1000;
        long timeStep = (currentTime - DEFAULT_START_TIME) / DEFAULT_TIME_STEP;
        return generateTOTP(key, Long.toHexString(timeStep).toUpperCase());
    }

    /**
     * 验证TOTP代码，考虑时间偏移容错
     *
     * @param key  共享密钥
     * @param code 要验证的代码
     * @param timeWindow 时间窗口大小（允许前后偏移的步数）
     * @return 验证是否成功
     */
    public static boolean verifyTOTP(String key, String code, int timeWindow) {
        if (key == null || key.isEmpty() || code == null || code.isEmpty()) {
            return false;
        }

        long currentTime = System.currentTimeMillis() / 1000;
        long currentTimeStep = (currentTime - DEFAULT_START_TIME) / DEFAULT_TIME_STEP;

        // 检查当前时间步及其前后时间窗口内的步数
        for (long i = -timeWindow; i <= timeWindow; i++) {
            long timeStep = currentTimeStep + i;
            String steps = Long.toHexString(timeStep).toUpperCase();
            try {
                String totp = generateTOTP(key, steps);
                if (totp.equals(code)) {
                    return true;
                }
            } catch (Exception e) {
                // 忽略单个时间步的错误，继续验证其他步数
                continue;
            }
        }
        return false;
    }

    /**
     * 验证TOTP代码（使用默认时间窗口）
     */
    public static boolean verifyTOTP(String key, String code) {
        return verifyTOTP(key, code, DEFAULT_TIME_WINDOW);
    }

}
```



- `GoogleAuthenticator` 如下：

```java
import org.apache.commons.codec.binary.Base32;
import org.apache.commons.codec.binary.Hex;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;

/**
 * Google Authenticator 工具类
 * 基于 TOTP (Time-based One-Time Password) 算法实现双因素认证
 * 参考 RFC 6238 标准，兼容 Google Authenticator 移动应用
 *
 * 主要功能：
 * - 生成随机密钥
 * - 生成TOTP动态验证码
 * - 生成Google Authenticator可识别的二维码数据
 * - 验证用户输入的验证码
 *
 * @author rstyro
 */
public final class GoogleAuthenticator {

    /** 默认密钥长度（字节） */
    private static final int DEFAULT_SECRET_KEY_LENGTH = 20;
    /** 默认时间窗口大小（30秒单位） */
    private static final int DEFAULT_WINDOW_SIZE = 2;
    /** 最大允许的时间窗口大小 */
    private static final int MAX_WINDOW_SIZE = 17;
    /** 时间步长（秒） */
    private static final long TIME_STEP = 30L;
    /** 验证码位数 */
    private static final int CODE_DIGITS = 6;
    /** HMAC算法名称 */
    private static final String HMAC_ALGORITHM = "HmacSHA1";

    /** 当前时间窗口大小 */
    private static int windowSize = DEFAULT_WINDOW_SIZE;

    /**
     * 私有构造方法，防止实例化
     */
    private GoogleAuthenticator() {
        throw new AssertionError("GoogleAuthenticator是工具类，不能实例化");
    }

    /**
     * 生成随机的Base32编码密钥
     * 密钥用于在客户端和服务器端之间共享，用于生成验证码
     *
     * @return Base32编码的随机密钥（大写，无分隔符）
     * @throws SecurityException 如果随机数生成失败
     */
    public static String generateRandomSecretKey() {
        try {
            SecureRandom random = SecureRandom.getInstanceStrong();
            byte[] bytes = new byte[DEFAULT_SECRET_KEY_LENGTH];
            random.nextBytes(bytes);

            Base32 base32 = new Base32();
            return base32.encodeToString(bytes).toUpperCase();
        } catch (NoSuchAlgorithmException e) {
            throw new SecurityException("安全随机数生成器不可用", e);
        }
    }

    /**
     * 生成当前时间的TOTP验证码
     *
     * @param secretKey Base32编码的共享密钥
     * @return 6位数字的TOTP验证码
     * @throws IllegalArgumentException 如果密钥为空或格式错误
     * @throws SecurityException 如果加密操作失败
     */
    public static String generateTOTPCode(String secretKey) {
        validateSecretKey(secretKey);

        try {
            // 标准化密钥：移除空格并转为大写
            String normalizedKey = secretKey.replace(" ", "").toUpperCase();
            Base32 base32 = new Base32();
            byte[] decodedBytes = base32.decode(normalizedKey);
            String hexKey = Hex.encodeHexString(decodedBytes);

            // 计算当前时间窗口
            long timeWindow = (System.currentTimeMillis() / 1000L) / TIME_STEP;
            String hexTime = Long.toHexString(timeWindow);

            return TOTP.generateTOTP(hexKey, hexTime, CODE_DIGITS, HMAC_ALGORITHM);

        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("无效的密钥格式: " + e.getMessage(), e);
        } catch (Exception e) {
            throw new SecurityException("生成TOTP验证码失败", e);
        }
    }

    /**
     * 生成Google Authenticator二维码内容URL
     * 该URL可用于生成二维码，供Google Authenticator应用扫描
     *
     * @param secretKey 共享密钥
     * @param account 用户账号（如邮箱或用户名）
     * @param issuer 发行者名称（应用或网站名称）
     * @return 二维码内容URL
     * @throws IllegalArgumentException 如果参数为空或格式错误
     */
    public static String generateQRCodeUrl(String secretKey, String account, String issuer) {
        validateParameters(secretKey, account, issuer);

        String normalizedKey = secretKey.replace(" ", "").toUpperCase();

        // 构建OTP Auth URL，符合Google Authenticator标准格式
        String url = "otpauth://totp/"
                + URLEncoder.encode(issuer + ":" + account, StandardCharsets.UTF_8).replace("+", "%20")
                + "?secret=" + URLEncoder.encode(normalizedKey, StandardCharsets.UTF_8).replace("+", "%20")
                + "&issuer=" + URLEncoder.encode(issuer, StandardCharsets.UTF_8).replace("+", "%20");
        return url;

    }

    /**
     * 验证TOTP验证码
     * 考虑时间窗口偏移，以处理客户端和服务端之间的时间差异
     *
     * @param secretKey 共享密钥
     * @param code 待验证的验证码
     * @param timestamp 时间戳（毫秒）
     * @return 验证是否成功
     * @throws IllegalArgumentException 如果参数无效
     */
    public static boolean verifyCode(String secretKey, long code, long timestamp) {
        validateSecretKey(secretKey);

        if (code < 0 || code > 999999) {
            throw new IllegalArgumentException("验证码必须是6位数字");
        }

        Base32 codec = new Base32();
        String normalizedKey = secretKey.replace(" ", "").toUpperCase();
        byte[] decodedKey;

        try {
            decodedKey = codec.decode(normalizedKey);
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("无效的Base32密钥格式", e);
        }

        // 计算基准时间窗口
        long timeWindow = (timestamp / 1000L) / TIME_STEP;

        // 检查当前及前后时间窗口内的验证码
        for (int i = -windowSize; i <= windowSize; i++) {
            try {
                long generatedCode = generateVerificationCode(decodedKey, timeWindow + i);
                if (generatedCode == code) {
                    return true;
                }
            } catch (GeneralSecurityException e) {
                // 记录日志但继续检查其他时间窗口
                System.err.println("验证码生成过程中出现安全异常: " + e.getMessage());
            }
        }

        return false;
    }

    /**
     * 验证当前时间的TOTP验证码（便捷方法）
     *
     * @param secretKey 共享密钥
     * @param code 待验证的验证码
     * @return 验证是否成功
     */
    public static boolean verifyCurrentCode(String secretKey, long code) {
        return verifyCode(secretKey, code, System.currentTimeMillis());
    }

    /**
     * 设置验证时间窗口大小
     * 时间窗口大小决定了允许的时间偏移范围（每个窗口30秒）
     * @param size 窗口大小（1-17）
     * @throws IllegalArgumentException 如果窗口大小超出范围
     */
    public static void setWindowSize(int size) {
        if (size < 1 || size > MAX_WINDOW_SIZE) {
            throw new IllegalArgumentException("窗口大小必须在1到" + MAX_WINDOW_SIZE + "之间");
        }
        windowSize = size;
    }

    /**
     * 获取当前时间窗口大小
     *
     * @return 当前时间窗口大小
     */
    public static int getWindowSize() {
        return windowSize;
    }

    /**
     * 生成指定时间窗口的验证码
     *
     * @param key 解码后的密钥字节数组
     * @param timeWindow 时间窗口值
     * @return 验证码数字
     * @throws NoSuchAlgorithmException 如果HMAC-SHA1算法不可用
     * @throws InvalidKeyException 如果密钥无效
     */
    private static long generateVerificationCode(byte[] key, long timeWindow)
            throws NoSuchAlgorithmException, InvalidKeyException {

        // 将时间窗口值转换为8字节数组（大端序）
        byte[] data = new byte[8];
        for (int i = 8; i-- > 0; timeWindow >>>= 8) {
            data[i] = (byte) timeWindow;
        }

        // 计算HMAC-SHA1哈希
        SecretKeySpec signKey = new SecretKeySpec(key, HMAC_ALGORITHM);
        Mac mac = Mac.getInstance(HMAC_ALGORITHM);
        mac.init(signKey);
        byte[] hash = mac.doFinal(data);

        // 动态截取（基于RFC 4226标准）
        int offset = hash[hash.length - 1] & 0x0F;

        // 从偏移位置提取4字节
        long truncatedHash = 0;
        for (int i = 0; i < 4; i++) {
            truncatedHash <<= 8;
            truncatedHash |= (hash[offset + i] & 0xFF);
        }

        // 取模得到6位数
        truncatedHash &= 0x7FFFFFFF;
        truncatedHash %= 1000000;

        return truncatedHash;
    }

    /**
     * 验证密钥格式
     */
    private static void validateSecretKey(String secretKey) {
        if (secretKey == null || secretKey.trim().isEmpty()) {
            throw new IllegalArgumentException("密钥不能为空");
        }
        if (!secretKey.matches("^[A-Z2-7\\s]+$")) {
            throw new IllegalArgumentException("密钥必须包含有效的Base32字符（A-Z, 2-7）");
        }
    }

    /**
     * 验证二维码生成参数
     */
    private static void validateParameters(String secretKey, String account, String issuer) {
        validateSecretKey(secretKey);

        if (account == null || account.trim().isEmpty()) {
            throw new IllegalArgumentException("账号不能为空");
        }
        if (issuer == null || issuer.trim().isEmpty()) {
            throw new IllegalArgumentException("发行者名称不能为空");
        }
    }

    
}
```



- **TOTP类**：实现TOTP (Time-based One-Time Password) 算法的核心逻辑
- **GoogleAuthenticator类**：Google身份验证的业务工具类，提供便捷的API



```java
/**
 * 测试示例
 */
private static void testExample(){
    System.out.println("=== Google Authenticator 测试 ===\n");

    // 生成测试密钥
    String secretKey = generateRandomSecretKey();
    System.out.println("1. 生成的密钥: " + secretKey);

    // 生成当前验证码
    String totpCode = generateTOTPCode(secretKey);
    System.out.println("2. 当前TOTP验证码: " + totpCode);

    // 生成二维码URL
    String qrCodeUrl = generateQRCodeUrl(secretKey, "16888888@qq.com", "2FA-demo");
    System.out.println("3. 二维码URL: " + qrCodeUrl);

    // 验证验证码（使用当前生成的验证码进行验证）
    boolean isValid = verifyCurrentCode(secretKey, Long.parseLong(totpCode));
    System.out.println("4. 验证码验证结果: " + (isValid ? "通过" : "失败"));

    // 错误验证码测试
    boolean isInvalid = verifyCurrentCode(secretKey, 123456L);
    System.out.println("5. 错误验证码测试: " + (isInvalid ? "测试不通过-错误验证码也通过" : "测试通过-验证码错误"));

    System.out.println("\n=== 测试完成 ===");
}

/**
 * 测试示例
 */
public static void main(String[] args) {
	testExample();
}
```



![测试示例运行结果示例图](result.png)



#### 2FA身份验证绑定流程

- 1、**用户发起绑定请求**
   - 用户登录系统后，在安全设置中选择启用2FA功能，向服务器发送生成2FA密钥的请求。
   
- 2、**服务器生成并返回密钥信息**
   - 服务器生成一个唯一的随机密钥（Base32编码，例如：`JDFVW66IN54KRAEQRSS2WQJSC4I54WG3`），并将该密钥与用户账户临时关联（此时尚未正式绑定）。
   - 服务器同时生成一个二维码URL，格式如下：`otpauth://totp/2FA-DEMO%3A16888888%40qq.com?secret=JDFVW66IN54KRAEQRSS2WQJSC4I54WG3&issuer=2FA-DEMO`
   - 服务器将密钥和二维码URL返回给用户。

- 3、 **用户扫描二维码**
   - 用户使用身份验证器应用（如Google Authenticator、Microsoft Authenticator等）扫描返回的二维码。
   - 身份验证器应用将自动解析二维码中的信息（包括密钥、发行者名称和用户账户），并开始生成基于时间的动态验证码。

- 4、**用户验证并完成绑定**
  - 身份验证器应用每30秒生成一个新的6位动态验证码。
  - 用户将当前显示的动态验证码，提交给服务器。
  - 服务器验证动态验证码的正确性：
    - 使用存储的密钥和当前时间窗口计算期望的验证码。
    - 检查用户提交的验证码是否与期望的验证码匹配（允许一定的时间窗口偏移，通常为1~3个窗口）。
  - 验证通过后，服务器将该密钥正式与用户账户绑定，并启用2FA保护。
  - 验证失败时，服务器返回错误信息，用户可重新输入验证码再次尝试。



上面是标准的完整流程了，涉及到用户与服务器之间的交互，我们为了简单测试，直接使用，`GoogleAuthenticator` 来生成和验证动态验证码就行，我们的动态验证码需要安装身份验证器客户端。



安装身份验证器的应用：

+ **IOS 版本：** [Google Authenticator](https://itunes.apple.com/cn/app/google-authenticator/id388497605)  
  可以在App Store搜索`google authenticator`

+ **安卓：** [Google Authenticator](https://play.google.com/store/apps/details?id=com.google.android.apps.authenticator2)  ，访问手机商店搜索：`Authenticator` 一般都有应用的

+ **浏览器插件：** 除了安装app应用，也可以安装浏览器插件，Authenticator: 2FA Client（Edge/Chrome插件）

  

为了快速测试，我们使用浏览器插件的方式，我使用的是`Edge` 浏览器（因为它的浏览器插件安装不用梯子，Google浏览器这些需要梯子）。我要安装的是：`Authenticator: 2FA Client` 。



![](2FA.png)





![](2FA2.png)



- 上面是我身份验证器，目前已经绑定了`Github` 和`ngrok`的 身份验证，那我们要如何绑定呢？

- 安装之后点击插件，就可以手动添加或者导入OTP链接或者二维码图片，我们可以导入上面例子中的链接：`otpauth://totp/2FA-DEMO%3A16888888%40qq.com?secret=JDFVW66IN54KRAEQRSS2WQJSC4I54WG3&issuer=2FA-DEMO`  来测试





![](step1.png)

![](step2.png)

![](step3.png)

![](step4.png)

![](step5.png)



现在我们的动态验证码已经配置好了，我们就可以通过`GoogleAuthenticator` 的验证方法来进行2FA身份验证了。





![动态验证示例图](verify.png)



- 我们可以看到，第一个验证码是错误，结果就是错的，第二个验证码：`359926` 是当前动态验证码，结果验证是对的。
- 至此，我们已经实现了2FA的验证流程DEMO,不懂我有没有表达清楚，欢迎各位读者讨论留言。



### 五、总结



- 2FA二步验证已经从一项高级安全功能逐渐变为网络账户的标准保护措施。它通过在传统密码基础上增加一层保护，极大地提高了账户安全性，有效防御多种常见网络攻击。

- 尽管2FA并非绝对安全（如针对SMS的SIM卡交换攻击仍存在风险），但它无疑大大增加了攻击者的入侵难度。安全性与便利性之间总是需要权衡，但2FA在两者之间找到了良好的平衡点。

- 随着技术发展，我们可能会看到更多无缝且安全的认证方式，如无密码认证、生物特征识别等。但在可预见的未来，2FA仍将是保护我们数字身份的重要工具。

- 在日益复杂的网络环境中，保护数字身份已成为每个人的必修课。启用2FA只需几分钟，却能为你避免可能的数据泄露和财产损失。现在就行动，为你的数字生活加上这把可靠的“安全锁”吧！



#### 资源获取：

- 本文完整代码已上传至 GitHub，欢迎 Star ⭐ 和 Fork： https://github.com/rstyro/Springboot/tree/master/springboot-2FA




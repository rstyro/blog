---
title: SpringBoot-Google二步验证
date: 2019-04-29 16:19:47
tags:
---

# SpringBoot-Google二步验证
+ 概念：Google身份验证器Google Authenticator是谷歌推出的基于时间的一次性密码(Time-based One-time Password，简称TOTP)，只需要在手机上安装该APP，就可以生成一个随着时间变化的一次性密码，用于帐户验证。
+ Google身份验证器是一款基于时间与哈希的一次性密码算法的两步验证软件令牌，此软件用于Google的认证服务。此项服务所使用的算法已列于RFC 6238和RFC 4226中。

## 一、流程
+ 用户请求服务器生成密钥
+ 服务器生成一个密钥并与用户信息进行关联，并返回密钥(类似：`XX57HWC7D2FA4X4GLOHOASTGPMVI5EFA`)和一个二维码信息（此步骤还没有绑定）
+ 用户把返回的二维码信息传给服务器，生成一个二维码  
	信息大概长这样的：`otpauth://totp/https%3A%2F%2Fwww.lrshuai.top%3Arstyro?secret=XX57HWC7D2FA4X4GLOHOASTGPMVI5EFA&issuer=https%3A%2F%2Fwww.lrshuai.top`
+ 用户通过身份验证器扫描二维码即可生成一个动态的验证码
+ 用户传当前动态的验证码和密钥给服务器，校验密钥的正确性（此密钥与用户真正的绑定）

> + 上面有些步骤不必须的，看需求，可以简化为两步。
> + 1、生成密钥
> + 2、扫码
> 上面那么多只是为了准确性而已

## 二、安装身份验证器
+ IOS 版本：[Google Authenticator](https://itunes.apple.com/cn/app/google-authenticator/id388497605)  
可以在App Store搜索`google authenticator`
+ 安卓：[Google Authenticator](https://play.google.com/store/apps/details?id=com.google.android.apps.authenticator2)  

> + 客户端每30秒就会生成新的验证码
> + 界面大概如下：
> + ![Google Authenticator界面](/SpringBoot-Google二步验证/0.png)


## 三、代码实现
![全部接口](/SpringBoot-Google二步验证/1.png)
#### 1、前言
+ 为了比较真实所以添加了注册和登录接口 
+ 为了方便集成了`Swagger-ui` 和全部是`GET`请求，不会用`Swagger-ui`,就直接地址栏请求或者`Postman`都可
+ 注册用户全部放Redis
+ 登录与Google校验，也以注解方式实现
+ 登录以token方式，所以请求其他接口的时候都要带上token，可以把token放在header里面

#### 2、代码

##### UserController
+ 控制层接口
+ 流程从上往下执行即可
```
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;
import top.lrshuai.googlecheck.annotation.NeedLogin;
import top.lrshuai.googlecheck.base.BaseController;
import top.lrshuai.googlecheck.common.Result;
import top.lrshuai.googlecheck.dto.GoogleDTO;
import top.lrshuai.googlecheck.dto.LoginDTO;
import top.lrshuai.googlecheck.service.UserService;
import top.lrshuai.googlecheck.utils.QRCodeUtil;

import javax.imageio.ImageIO;
import javax.servlet.http.HttpServletResponse;
import java.awt.image.BufferedImage;
import java.io.OutputStream;

@Controller
@RequestMapping("/user")
@Api(tags = "用户模块")
public class UserController extends BaseController {

    @Autowired
    private UserService userService;

    @GetMapping("/register")
    @ApiOperation("注册")
    @ResponseBody
    public Result register(LoginDTO dto) throws Exception {
        return userService.register(dto);
    }


    @GetMapping("/login")
    @ApiOperation("登录")
    @ResponseBody
    public Result login(LoginDTO dto)throws Exception{
        return userService.login(dto);
    }


    @GetMapping("/generateGoogleSecret")
    @ResponseBody
    @NeedLogin
    @ApiOperation("生成google密钥")
    public Result generateGoogleSecret()throws Exception{
        return userService.generateGoogleSecret(this.getUser());
    }

    /**
     * 显示一个二维码图片
     * @param secretQrCode   generateGoogleSecret接口返回的：secretQrCode
     * @param response
     * @throws Exception
     */
    @GetMapping("/genQrCode")
    @ApiOperation("生成二维码")
    public void genQrCode(String secretQrCode, HttpServletResponse response) throws Exception{
        response.setContentType("image/png");
        OutputStream stream = response.getOutputStream();
        QRCodeUtil.encode(secretQrCode,stream);
    }


    @GetMapping("/bindGoogle")
    @ResponseBody
    @NeedLogin
    @ApiOperation("绑定google验证")
    public Result bindGoogle(GoogleDTO dto)throws Exception{
        return userService.bindGoogle(dto,this.getUser(),this.getRequest());
    }

    @GetMapping("/googleLogin")
    @ResponseBody
    @NeedLogin
    @ApiOperation("google登录")
    public Result googleLogin(Long code) throws Exception{
        return userService.googleLogin(code,this.getUser(),this.getRequest());
    }


    @GetMapping("/getData")
    @NeedLogin(google = true)
    @ApiOperation("获取用户数据与token数据，前提需要google认证才能访问")
    @ResponseBody
    public Result getData()throws Exception{
        return userService.getData();
    }

}
```


##### UserService
+ 服务层，业务代码
```
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import top.lrshuai.encryption.MDUtil;
import top.lrshuai.googlecheck.common.*;
import top.lrshuai.googlecheck.dto.GoogleDTO;
import top.lrshuai.googlecheck.dto.LoginDTO;
import top.lrshuai.googlecheck.entity.User;
import top.lrshuai.googlecheck.utils.GoogleAuthenticator;
import top.lrshuai.googlecheck.utils.Tools;

import javax.servlet.http.HttpServletRequest;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.TimeUnit;

@Service
public class UserService {

    @Autowired
    private RedisTemplate<String,Object> redisTemplate;

    /**
     * 获取缓存中的数据
     * @return
     */
    public Result getData(){
        Map<String,Object> data = new HashMap<>();
        setData(CacheKey.REGISTER_USER_KEY,data);
        setData(CacheKey.TOKEN_KEY_LOGIN_KEY,data);
        return Result.ok(data);
    }

    public void setData(String keyword,Map<String,Object> data){
        Set<String> keys = redisTemplate.keys(keyword);
        Iterator<String> iterator = keys.iterator();
        while (iterator.hasNext()){
            String key = iterator.next();
            data.put(key,redisTemplate.opsForValue().get(key));
        }
    }

    /**
     * 注册
     * @param dto
     * @return
     * @throws Exception
     */
    public Result register(LoginDTO dto) throws Exception {
        User user = new User();
        user.setUserId(Tools.getUUID());
        user.setUsername(dto.getUsername());
        user.setPassword(MDUtil.bcMD5(dto.getPassword()));
        addUser(user);
        return Result.ok();
    }


    //获取用户
    public User getUser(String username){
        User cacheUser = (User) redisTemplate.opsForValue().get(String.format(CacheKey.REGISTER_USER, username));
        return cacheUser;
    }

    //添加注册用户
    public void addUser(User user){
        if(user == null) throw new ApiException(ApiResultEnum.ERROR_NULL);
        User isRepeat = getUser(user.getUsername());
        if(isRepeat != null ){
            throw new ApiException(ApiResultEnum.USER_IS_EXIST);
        }
        redisTemplate.opsForValue().set(String.format(CacheKey.REGISTER_USER, user.getUsername()),user,1, TimeUnit.DAYS);
    }

    //更新token用户
    public void updateUser(User user,HttpServletRequest request){
        if(user == null) throw new ApiException(ApiResultEnum.ERROR_NULL);
        redisTemplate.opsForValue().set(Tools.getTokenKey(request,CacheEnum.LOGIN),user,1, TimeUnit.DAYS);
    }


    /**
     * 登录
     * @param dto
     * @return
     * @throws Exception
     */
    public Result login(LoginDTO dto) throws Exception {
        User user = getUser(dto.getUsername());
        if(user == null){
            throw new ApiException(ApiResultEnum.USER_NOT_EXIST);
        }
        if(!user.getPassword().equals(MDUtil.bcMD5(dto.getPassword()))){
            throw new ApiException(ApiResultEnum.USERNAME_OR_PASSWORD_IS_WRONG);
        }
        //随机生成token
        String token = Tools.getUUID();
        redisTemplate.opsForValue().set(String.format(CacheKey.TOKEN_KEY_LOGIN,token),user,1,TimeUnit.DAYS);
        Map<String,Object> data = new HashMap<>();
        data.put(Consts.TOKEN,token);
        return Result.ok(data);
    }

    /**
     * 生成Google 密钥
     * secret：密钥
     * secretQrCode：Google Authenticator 扫描条形码的内容
     * @param user
     * @return
     */
    public Result generateGoogleSecret(User user){
        //Google密钥
        String randomSecretKey = GoogleAuthenticator.getRandomSecretKey();
        String googleAuthenticatorBarCode = GoogleAuthenticator.getGoogleAuthenticatorBarCode(randomSecretKey, user.getUsername(), "https://www.lrshuai.top");
        Map<String,Object> data = new HashMap<>();
        //Google密钥
        data.put("secret",randomSecretKey);
        //用户二维码内容
        data.put("secretQrCode",googleAuthenticatorBarCode);
        return Result.ok(data);
    }


    /**
     * 绑定Google
     * @param dto
     * @param user
     * @return
     */
    public Result bindGoogle(GoogleDTO dto, User user, HttpServletRequest request){
        if(!StringUtils.isEmpty(user.getGoogleSecret())){
            throw new ApiException(ApiResultEnum.GOOGLE_IS_BIND);
        }
        boolean isTrue = GoogleAuthenticator.check_code(dto.getSecret(), dto.getCode(), System.currentTimeMillis());
        if(!isTrue){
            throw new ApiException(ApiResultEnum.GOOGLE_CODE_NOT_MATCH);
        }
        User cacheUser = getUser(user.getUsername());
        cacheUser.setGoogleSecret(dto.getSecret());
        updateUser(cacheUser,request);
        return Result.ok();
    }

    /**
     * Google登录
     * @param code
     * @param user
     * @return
     */
    public Result googleLogin(Long code,User user,HttpServletRequest request){
        if(StringUtils.isEmpty(user.getGoogleSecret())){
            throw new ApiException(ApiResultEnum.GOOGLE_NOT_BIND);
        }
        boolean isTrue = GoogleAuthenticator.check_code(user.getGoogleSecret(), code, System.currentTimeMillis());
        if(!isTrue){
            throw new ApiException(ApiResultEnum.GOOGLE_CODE_NOT_MATCH);
        }
        redisTemplate.opsForValue().set(Tools.getTokenKey(request,CacheEnum.GOOGLE),Consts.SUCCESS,1,TimeUnit.DAYS);
        return Result.ok();
    }


}

```
#### GoogleAuthenticator
+ Google身份验证器工具类
```
import com.google.zxing.BarcodeFormat;
import com.google.zxing.MultiFormatWriter;
import com.google.zxing.WriterException;
import com.google.zxing.client.j2se.MatrixToImageWriter;
import com.google.zxing.common.BitMatrix;
import org.apache.commons.codec.binary.Base32;
import org.apache.commons.codec.binary.Hex;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;

public class GoogleAuthenticator {
	public static String getRandomSecretKey() {
		SecureRandom random = new SecureRandom();
		byte[] bytes = new byte[20];
		random.nextBytes(bytes);
		Base32 base32 = new Base32();
		String secretKey = base32.encodeToString(bytes);
		// make the secret key more human-readable by lower-casing and
		// inserting spaces between each group of 4 characters
		return secretKey.toUpperCase(); // .replaceAll("(.{4})(?=.{4})", "$1 ");
	}

	public static String getTOTPCode(String secretKey) {
		String normalizedBase32Key = secretKey.replace(" ", "").toUpperCase();
		Base32 base32 = new Base32();
		byte[] bytes = base32.decode(normalizedBase32Key);
		String hexKey = Hex.encodeHexString(bytes);
		long time = (System.currentTimeMillis() / 1000) / 30;
		String hexTime = Long.toHexString(time);
		return TOTP.generateTOTP(hexKey, hexTime, "6");
	}

	public static String getGoogleAuthenticatorBarCode(String secretKey,
			String account, String issuer) {
		String normalizedBase32Key = secretKey.replace(" ", "").toUpperCase();
		try {
			return "otpauth://totp/"
					+ URLEncoder.encode(issuer + ":" + account, "UTF-8")
							.replace("+", "%20")
					+ "?secret="
					+ URLEncoder.encode(normalizedBase32Key, "UTF-8").replace(
							"+", "%20") + "&issuer="
					+ URLEncoder.encode(issuer, "UTF-8").replace("+", "%20");
		} catch (UnsupportedEncodingException e) {
			throw new IllegalStateException(e);
		}
	}

	public static void createQRCode(String barCodeData, String filePath,
			int height, int width) throws WriterException, IOException {
		BitMatrix matrix = new MultiFormatWriter().encode(barCodeData,
				BarcodeFormat.QR_CODE, width, height);
		try (FileOutputStream out = new FileOutputStream(filePath)) {
			MatrixToImageWriter.writeToStream(matrix, "png", out);
		}
	}

	static int window_size = 3; // default 3 - max 17 (from google docs)最多可偏移的时间

	/**
	 * set the windows size. This is an integer value representing the number of
	 * 30 second windows we allow The bigger the window, the more tolerant of
	 * clock skew we are.
	 * 
	 * @param s
	 *            window size - must be >=1 and <=17. Other values are ignored
	 */
	public static void setWindowSize(int s) {
		if (s >= 1 && s <= 17)
			window_size = s;
	}

	/**
	 * Check the code entered by the user to see if it is valid
	 * 
	 * @param secret
	 *            The users secret.
	 * @param code
	 *            The code displayed on the users device
	 * @param timeMsec
	 *            The time in msec (System.currentTimeMillis() for example)
	 * @return
	 */
	public static boolean check_code(String secret, long code, long timeMsec) {
		Base32 codec = new Base32();
		byte[] decodedKey = codec.decode(secret);
		// convert unix msec time into a 30 second "window"
		// this is per the TOTP spec (see the RFC for details)
		long t = (timeMsec / 1000L) / 30L;
		// Window is used to check codes generated in the near past.
		// You can use this value to tune how far you're willing to go.
		for (int i = -window_size; i <= window_size; ++i) {
			long hash;
			try {
				hash = verify_code(decodedKey, t + i);
			} catch (Exception e) {
				// Yes, this is bad form - but
				// the exceptions thrown would be rare and a static
				// configuration problem
				// e.printStackTrace();
				throw new RuntimeException(e.getMessage());
				// return false;
			}
			if (hash == code) {
				return true;
			}
		}
		// The validation code is invalid.
		return false;
	}

	private static int verify_code(byte[] key, long t)
			throws NoSuchAlgorithmException, InvalidKeyException {
		byte[] data = new byte[8];
		long value = t;
		for (int i = 8; i-- > 0; value >>>= 8) {
			data[i] = (byte) value;
		}
		SecretKeySpec signKey = new SecretKeySpec(key, "HmacSHA1");
		Mac mac = Mac.getInstance("HmacSHA1");
		mac.init(signKey);
		byte[] hash = mac.doFinal(data);
		int offset = hash[20 - 1] & 0xF;
		// We're using a long because Java hasn't got unsigned int.
		long truncatedHash = 0;
		for (int i = 0; i < 4; ++i) {
			truncatedHash <<= 8;
			// We are dealing with signed bytes:
			// we just keep the first byte.
			truncatedHash |= (hash[offset + i] & 0xFF);
		}
		truncatedHash &= 0x7FFFFFFF;
		truncatedHash %= 1000000;
		return (int) truncatedHash;
	}
}

```

#### 主要流程图
![登录](/SpringBoot-Google二步验证/2.png)
![生成google密钥](/SpringBoot-Google二步验证/3.png)
![扫描二维码](/SpringBoot-Google二步验证/4.png)
![Google验证器动态验证码](/SpringBoot-Google二步验证/5.png)
![绑定Google](/SpringBoot-Google二步验证/6.png)

#### 代码地址
+ Github: [https://github.com/rstyro/Springboot/tree/master/SpringBoot-Google-Check](https://github.com/rstyro/Springboot/tree/master/SpringBoot-Google-Check)
+ Gitee: [https://gitee.com/rstyro/spring-boot/tree/master/SpringBoot-Google-Check](https://gitee.com/rstyro/spring-boot/tree/master/SpringBoot-Google-Check)


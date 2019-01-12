---
title: Java加密工具类
date: 2017-10-10 20:46:49
tags: [Java]
categories: Java
---
#导包
##maven依赖
```
<!-- jdk-->
<dependency>
	<groupId>commons-codec</groupId>
	<artifactId>commons-codec</artifactId>
</dependency>
<!-- bc -->
<dependency>
<groupId>org.bouncycastle</groupId>
	<artifactId>bcprov-jdk15on</artifactId>
	<version>1.58</version>
</dependency>
```
#代码示例
##MD5加密算法 示例
```
package top.lrshuai.blog.util;

import java.security.MessageDigest;
import java.security.Security;

import org.apache.commons.codec.binary.Hex;
import org.apache.commons.codec.digest.DigestUtils;
import org.bouncycastle.crypto.Digest;
import org.bouncycastle.crypto.digests.MD4Digest;
import org.bouncycastle.crypto.digests.MD5Digest;
import org.bouncycastle.jce.provider.BouncyCastleProvider;

public class MDUtil {
	private static String key = "www.lrshuai.top";
	
	public static String jdkMD5() throws Exception{
		MessageDigest md = MessageDigest.getInstance("MD5");
		byte[] mdbyte = md.digest(key.getBytes());
		return Hex.encodeHexString(mdbyte);
	}
	public static String jdkMD2() throws Exception{
		MessageDigest md = MessageDigest.getInstance("MD2");
		byte[] mdbyte = md.digest(key.getBytes());
		return Hex.encodeHexString(mdbyte);
	}
	
	public static String bcMD4() throws Exception{
		Security.addProvider(new BouncyCastleProvider());
		MessageDigest md = MessageDigest.getInstance("MD4");
		byte[] mdbyte = md.digest(key.getBytes());
		return Hex.encodeHexString(mdbyte);
	}
	
	public static String bcMD4Two() throws Exception{
		Digest digest = new MD4Digest();
		digest.update(key.getBytes(), 0,key.getBytes().length);
		byte[] bcbtyte = new byte[digest.getDigestSize()];
		digest.doFinal(bcbtyte, 0);
		return org.bouncycastle.util.encoders.Hex.toHexString(bcbtyte);
	}
	
	public static String bcMD5() throws Exception{
		Digest digest = new MD5Digest();
		digest.update(key.getBytes(), 0,key.getBytes().length);
		byte[] bcbtyte = new byte[digest.getDigestSize()];
		digest.doFinal(bcbtyte, 0);
		return org.bouncycastle.util.encoders.Hex.toHexString(bcbtyte);
	}
	
	public static String ccMD5() {
		return DigestUtils.md5Hex(key.getBytes());
	}
	
	public static String ccMD2() {
		return DigestUtils.md2Hex(key.getBytes());
	}
	
	public static void main(String[] args) throws Exception {
		System.out.println(jdkMD5());
		System.out.println(jdkMD2());
		System.out.println(bcMD4());
		System.out.println(bcMD4Two());
		System.out.println(bcMD5());
		System.out.println(ccMD5());
		System.out.println(ccMD2());
	}
}

```
##SHA1加密算法 示例
###SHA 分为
####SHA1
####SHA2 
#####SHA2又分有 SHA-224、SHA-256、SHA-384，和SHA-512。
###所以SHA 的算法可以说有5种
```
package top.lrshuai.blog.util;

import java.security.MessageDigest;
import java.security.Security;

import org.apache.commons.codec.binary.Hex;
import org.apache.commons.codec.digest.DigestUtils;
import org.bouncycastle.crypto.Digest;
import org.bouncycastle.crypto.digests.MD4Digest;
import org.bouncycastle.crypto.digests.MD5Digest;
import org.bouncycastle.crypto.digests.SHA1Digest;
import org.bouncycastle.crypto.digests.SHA224Digest;
import org.bouncycastle.jce.provider.BouncyCastleProvider;

public class SHAUtil {
	private static String key = "www.lrshuai.top";
	
	public static String jdkSHA1() throws Exception{
		MessageDigest md = MessageDigest.getInstance("SHA");
		md.update(key.getBytes());
		return Hex.encodeHexString(md.digest());
	}
	
	
	public static String bcSHA1() throws Exception{
		Digest digest = new SHA1Digest();
		digest.update(key.getBytes(), 0,key.getBytes().length);
		byte[] shabtyte = new byte[digest.getDigestSize()];
		digest.doFinal(shabtyte, 0);
		return org.bouncycastle.util.encoders.Hex.toHexString(shabtyte);
	}
	public static String bcSHA224() throws Exception{
		Digest digest = new SHA224Digest();
		digest.update(key.getBytes(), 0,key.getBytes().length);
		byte[] shabtyte = new byte[digest.getDigestSize()];
		digest.doFinal(shabtyte, 0);
		return org.bouncycastle.util.encoders.Hex.toHexString(shabtyte);
	}
	
	public static String bcSHA224Two() throws Exception{
		Security.addProvider(new BouncyCastleProvider());
		MessageDigest md = MessageDigest.getInstance("SHA-224");
		md.update(key.getBytes());
		return Hex.encodeHexString(md.digest());
	}
	
	
	public static String ccSHA1() {
		return DigestUtils.sha1Hex(key.getBytes());
	}
	
	public static String ccSHA2() {
		return DigestUtils.shaHex(key);
	}
	
	public static void main(String[] args) throws Exception {
		System.out.println(jdkSHA1());
		System.out.println(bcSHA1());
		System.out.println(bcSHA224());
		System.out.println(bcSHA224Two());
	}
}

```

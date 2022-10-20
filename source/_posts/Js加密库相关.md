---
title: Js加密库相关
date: 2022-10-20 10:44:18
updated: 2022-10-20 10:44:18
tags: [加解密]
categories: 前端
---

### 一、Crypto-JS
- CryptoJS (crypto.js) 为 JavaScript 提供了各种各样的加密算法。
- 库里支持的加密算法有：MD5、SHA、RIPEMD-160、HMAC、PBKDF2、AES、DES、3DES（Triple DES）、Rabbit、RC4
- 官方文档：[https://cryptojs.gitbook.io/docs/](https://cryptojs.gitbook.io/docs/)
- Github地址：[https://github.com/brix/crypto-js](https://github.com/brix/crypto-js)
- npm安装crypto-js: `npm install crypto-js -S`
- 使用示例:


#### 1、引入单个库
```js
// 引入单个库
import sha256 from 'crypto-js/sha256';
import hmacSHA512 from 'crypto-js/hmac-sha512';
import Base64 from 'crypto-js/enc-base64';

console.log("SHA256加密：",sha256("Message").toString());
console.log("HmacSHA512加密", hmacSHA512("Message","Secret Passphrase").toString());
// base64
const base64en=Base64.stringify(CryptoJS.enc.Utf8.parse("Message"));
console.log("Base64 加密：",base64en);
const base64De = Base64.parse(base64en).toString(CryptoJS.enc.Utf8);
console.log("Base64 解密：",base64De);
```

#### 2、引入所有库
```js
// Crypto-JS 支持 MD5、SHA、RIPEMD-160、HMAC、PBKDF2、AES、DES、3DES(Triple DES)等
import CryptoJS from 'crypto-js';

console.log("md5 加密：", CryptoJS.MD5("Message").toString(CryptoJS.enc.Hex));
console.log("md5 加密转base64：", CryptoJS.MD5("Message").toString(CryptoJS.enc.Base64));
// SHA哈希函数由国家安全局（NSA）设计。SHA-1是现有SHA哈希函数中最成熟的，它用于各种安全应用程序和协议。然而，随着新攻击的发现或改进，SHA-1的抗碰撞性一直在减弱。
console.log("SHA1 加密：", CryptoJS.SHA1("Message").toString(CryptoJS.enc.Hex));
//SHA-256是SHA-2系列中的四种变体之一。它不像SHA-1那样被广泛使用，尽管它似乎提供了更好的安全性  
console.log("SHA256 加密：", CryptoJS.SHA256("Message").toString(CryptoJS.enc.Hex));
console.log("SHA224 加密：", CryptoJS.SHA224("Message").toString(CryptoJS.enc.Hex));
console.log("SHA384 加密：", CryptoJS.SHA384("Message").toString(CryptoJS.enc.Hex));
//SHA-512 与 SHA-256 基本相同，但操作的是 64 位字而不是 32 位字
console.log("SHA512 加密：", CryptoJS.SHA512("Message").toString(CryptoJS.enc.Hex));
//SHA-3是一项为期五年的比赛的获胜者，该竞赛旨在选择一种新的加密哈希算法，其中评估了64种竞争设计。
console.log("SHA3 加密：", CryptoJS.SHA3("Message").toString(CryptoJS.enc.Hex));
// SHA-3可以配置为输出224、256、384或512位之一的散列长度。默认值为512位。
console.log("SHA3 512加密：", CryptoJS.SHA3("Message", {
	outputLength: 512
}).toString(CryptoJS.enc.Hex));
console.log("SHA3 384加密：", CryptoJS.SHA3("Message", {
	outputLength: 384
}).toString(CryptoJS.enc.Hex));
console.log("SHA3 256加密：", CryptoJS.SHA3("Message", {
	outputLength: 256
}).toString(CryptoJS.enc.Hex));
console.log("SHA3 224加密：", CryptoJS.SHA3("Message", {
	outputLength: 224
}).toString(CryptoJS.enc.Hex));


//HMAC
console.log("HmacMD5 加密：", CryptoJS.HmacMD5("Message","Secret Passphrase").toString(CryptoJS.enc.Hex));
console.log("HmacSHA1 加密：", CryptoJS.HmacSHA1("Message","Secret Passphrase").toString(CryptoJS.enc.Hex));
console.log("HmacSHA256 加密：", CryptoJS.HmacSHA256("Message","Secret Passphrase").toString(CryptoJS.enc.Hex));
console.log("HmacSHA512 加密：", CryptoJS.HmacSHA512("Message","Secret Passphrase").toString(CryptoJS.enc.Hex));
// console.log("RIPEMD160 加密：", CryptoJS.RIPEMD160("Message");


// PBKDF2
var salt = CryptoJS.lib.WordArray.random(128 / 8);
var key128Bits = CryptoJS.PBKDF2("Secret Passphrase", salt, {
  keySize: 128 / 32
});
var key256Bits = CryptoJS.PBKDF2("Secret Passphrase", salt, {
  keySize: 256 / 32
});
var key512Bits = CryptoJS.PBKDF2("Secret Passphrase", salt, {
  keySize: 512 / 32
});
var key512Bits1000Iterations = CryptoJS.PBKDF2("Secret Passphrase", salt, {
  keySize: 512 / 32,
  iterations: 1000
});
console.log("PBKDF2 key128Bits加密：", key128Bits.toString(CryptoJS.enc.Hex));
console.log("PBKDF2 key256Bits 加密：", key256Bits.toString(CryptoJS.enc.Hex));
console.log("PBKDF2 key512Bits 加密：", key512Bits.toString(CryptoJS.enc.Hex));
console.log("PBKDF2 key512Bits1000Iterations 加密：", key512Bits1000Iterations.toString(CryptoJS.enc.Hex));


// AES 
var encrypted = CryptoJS.AES.encrypt("Message", "111");
var decrypted = CryptoJS.AES.decrypt(encrypted.toString(), "111");
console.log("encrypted AES加密：", encrypted.toString());
console.log("encrypted AES解密：", decrypted.toString(CryptoJS.enc.Utf8));
//AES 有参数的写法，key可选：128位对应16个字节（8位一个字节）、192位对应24个字节、256位对应32个字节
var key = CryptoJS.enc.Utf8.parse("1234567891012345");
// 向量16个字节，ECB模式不需要向量参数
var iv = CryptoJS.enc.Utf8.parse("1234567891012345");
var encryptedIv = CryptoJS.AES.encrypt("Message", key, {
	iv: iv,
	mode: CryptoJS.mode.CBC,
	padding: CryptoJS.pad.Pkcs7
});
var decryptedIv = CryptoJS.AES.decrypt(encryptedIv.toString(), key, {
	iv: iv,
	mode: CryptoJS.mode.CBC,
	padding: CryptoJS.pad.Pkcs7
});
let aesEncodeBase64Str = encryptedIv.toString();
let aesEncodeHexStr = encryptedIv.ciphertext.toString();
console.log("encrypted AES参数BASE64加密：", aesEncodeBase64Str);
console.log("encrypted AES参数Hex加密：", aesEncodeHexStr);
// 如果是hex,先解析后转base64才能解密
var decryptedIv2 = CryptoJS.AES.decrypt(CryptoJS.enc.Base64.stringify(CryptoJS.enc.Hex.parse(aesEncodeHexStr)), key, {
	iv: iv,
	mode: CryptoJS.mode.CBC,
	padding: CryptoJS.pad.Pkcs7
});
console.log("encrypted AES向量解密1：", decryptedIv.toString(CryptoJS.enc.Utf8));
console.log("encrypted AES向量解密2：", decryptedIv2.toString(CryptoJS.enc.Utf8));

// DES
var encrypted1 = CryptoJS.DES.encrypt("Message", "Secret Passphrase");
var decrypted1 = CryptoJS.DES.decrypt(encrypted1.toString(), "Secret Passphrase");
console.log("encrypted DES加密：", encrypted1.toString());
console.log("encrypted DES解密：", decrypted1.toString(CryptoJS.enc.Utf8));

// TripleDES
var encrypted2 = CryptoJS.TripleDES.encrypt("Message", "Secret Passphrase");
var decrypted2 = CryptoJS.TripleDES.decrypt(encrypted2, "Secret Passphrase");
console.log("encrypted TripleDES加密：", encrypted2.toString());
console.log("encrypted TripleDES解密：", decrypted2.toString(CryptoJS.enc.Utf8));

// Rabbit
var encrypted3 = CryptoJS.Rabbit.encrypt("Message", "Secret Passphrase");
var decrypted3 = CryptoJS.Rabbit.decrypt(encrypted3, "Secret Passphrase");
console.log("encrypted Rabbit加密：", encrypted3.toString());
console.log("encrypted Rabbit解密：", decrypted3.toString(CryptoJS.enc.Utf8));

// RC4, RC4Drop
var encrypted4 = CryptoJS.RC4.encrypt("Message", "Secret Passphrase");
var decrypted4 = CryptoJS.RC4.decrypt(encrypted4, "Secret Passphrase");
console.log("encrypted RC4加密：", encrypted4.toString());
console.log("encrypted RC4解密：", decrypted4.toString(CryptoJS.enc.Utf8));

var encrypted5 = CryptoJS.RC4Drop.encrypt("Message", "Secret Passphrase", {
	drop: 3072 / 4
});
var decrypted5 = CryptoJS.RC4Drop.decrypt(encrypted5, "Secret Passphrase", {
	drop: 3072 / 4
});
console.log("encrypted RC4Drop加密：", encrypted5.toString());
console.log("encrypted RC4Drop解密：", decrypted5.toString(CryptoJS.enc.Utf8));

// Base64
let base64en = CryptoJS.enc.Base64.stringify(CryptoJS.enc.Utf8.parse("Message"));
console.log("Base64加密：", base64en);
const base64De = CryptoJS.enc.Base64.parse(base64en).toString(CryptoJS.enc.Utf8);
console.log("Base64 解密：",base64De);
```
- 其他用法可参考官方文档

### 二、Node-RSA
- 
---
title: 分享一个Java生成验证码工具类
date: 2017-10-18 13:50:48
tags: [Java]
categories: Java
---
# 分享一个Java生成验证码工具类
## 直接上代码：
#### 1、CodeUtil.class
```java
package top.lrshuai.blog.util;

import java.awt.BasicStroke;
import java.awt.Color;
import java.awt.Font;
import java.awt.Graphics2D;
import java.awt.image.BufferedImage;
import java.util.Random;

/**
 * 验证码工具类
 *
 */
public class CodeUtil {

	private static final String[] CODE = { "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "P",
			"Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "1", "2", "3", "4", "5", "6", "7", "8", "9" };

	/**
	 * 生成验证码图片
	 * 
	 * @return obj[0]: 图片; obj[1]:字符串
	 */
	public static Object[] CreateCode() {
		int imgW = 120;
		int imgH = 42;
		int r, g, b;
		Color color;
		String result = "";
		Random random = new Random();
		BufferedImage img = new BufferedImage(imgW, imgH, BufferedImage.TYPE_INT_RGB);
		Graphics2D graphics = img.createGraphics();
		graphics.setFont(new Font("MicroSoft YaHei", Font.PLAIN, 30));

		// 绘制背景色
		r = random.nextInt(20) + 230;
		g = random.nextInt(20) + 230;
		b = random.nextInt(20) + 230;
		color = new Color(r, g, b);
		graphics.setColor(color);
		graphics.fillRect(0, 0, imgW, imgH);

		// 绘制背景干扰线条
		for (int i = 0; i < 3; i++) {
			r = random.nextInt(50) + 200;
			g = random.nextInt(50) + 200;
			b = random.nextInt(50) + 200;
			color = new Color(r, g, b);
			graphics.setColor(color);
			graphics.setStroke(new BasicStroke(2.0f));
			graphics.drawLine(random.nextInt(20), random.nextInt(imgH), random.nextInt(20) + 80, random.nextInt(imgH));
		}

		if (random.nextInt(100) >= 50) {
			// 绘制字符串验证码
			for (int i = 0; i < 4; i++) {
				String str = CODE[random.nextInt(CODE.length)];
				r = random.nextInt(180) + 50;
				g = random.nextInt(180) + 50;
				b = random.nextInt(180) + 50;
				color = new Color(r, g, b);
				graphics.setColor(color);
				graphics.drawString(str, (i * 20) + 20, random.nextInt(4) + 30);
				result += str;
			}
		} else {
			// 绘制计算题验证码
			int is = random.nextInt(100);
			int num1 = 0, num2 = 0;
			if (is >= 50) {
				// 加法
				r = random.nextInt(180) + 50;
				g = random.nextInt(180) + 50;
				b = random.nextInt(180) + 50;
				color = new Color(r, g, b);
				graphics.setColor(color);
				num1 = random.nextInt(9) + 1;
				graphics.drawString(num1 + "", 20, random.nextInt(4) + 30);

				r = random.nextInt(180) + 50;
				g = random.nextInt(180) + 50;
				b = random.nextInt(180) + 50;
				color = new Color(r, g, b);
				graphics.setColor(color);
				graphics.drawString("+", 40, random.nextInt(4) + 30);

				r = random.nextInt(180) + 50;
				g = random.nextInt(180) + 50;
				b = random.nextInt(180) + 50;
				color = new Color(r, g, b);
				graphics.setColor(color);
				num2 = random.nextInt(9) + 1;
				graphics.drawString(num2 + "", 60, random.nextInt(4) + 30);

				r = random.nextInt(180) + 50;
				g = random.nextInt(180) + 50;
				b = random.nextInt(180) + 50;
				color = new Color(r, g, b);
				graphics.setColor(color);
				graphics.drawString("=", 80, random.nextInt(4) + 30);

				result = (num1 + num2) + "";
			} else {
				// 乘法
				r = random.nextInt(180) + 50;
				g = random.nextInt(180) + 50;
				b = random.nextInt(180) + 50;
				color = new Color(r, g, b);
				graphics.setColor(color);
				num1 = random.nextInt(9) + 1;
				graphics.drawString(num1 + "", 20, random.nextInt(4) + 30);

				r = random.nextInt(180) + 50;
				g = random.nextInt(180) + 50;
				b = random.nextInt(180) + 50;
				color = new Color(r, g, b);
				graphics.setColor(color);
				graphics.drawString("×", 40, random.nextInt(4) + 30);

				r = random.nextInt(180) + 50;
				g = random.nextInt(180) + 50;
				b = random.nextInt(180) + 50;
				color = new Color(r, g, b);
				graphics.setColor(color);
				num2 = random.nextInt(9) + 1;
				graphics.drawString(num2 + "", 60, random.nextInt(4) + 30);

				r = random.nextInt(180) + 50;
				g = random.nextInt(180) + 50;
				b = random.nextInt(180) + 50;
				color = new Color(r, g, b);
				graphics.setColor(color);
				graphics.drawString("=", 80, random.nextInt(4) + 30);

				result = (num1 * num2) + "";
			}
		}

		// 绘制前景干扰线条
		for (int i = 0; i < 3; i++) {
			r = random.nextInt(50) + 200;
			g = random.nextInt(50) + 200;
			b = random.nextInt(50) + 200;
			color = new Color(r, g, b);
			graphics.setColor(color);
			graphics.setStroke(new BasicStroke(1.0f));
			graphics.drawLine(0, random.nextInt(imgH), imgW, random.nextInt(imgH));
		}
		return new Object[] { img, result };
	}

}
```

#### 2、controller 请求
```
/**
* 生成验证码
* @throws IOException 
*/
@GetMapping(value = "/code")
public String getCode(HttpServletResponse response){
	OutputStream os = null;
	try {
		// 获取图片
		Object[] img = CodeUtil.CreateCode();
		System.out.println("code="+img[1].toString());
		BufferedImage image = (BufferedImage) img[0];
		// 输出到浏览器
		response.setContentType("image/png");
		os = response.getOutputStream();
		ImageIO.write(image, "png", os);
		os.flush();
		// 用于验证的字符串存入session
		this.getSession().setAttribute(Const.AUTH_CODE, img[1].toString());
	} catch (IOException e) {
		log.error("验证码输出异常",e);
	}finally {
		if(os != null) {
			try {
				os.close();
			} catch (IOException e) {
				System.out.println("close error");
				e.printStackTrace();
			}
		}
	}
	return null;
}
```

#### 3、html 页面调用
```
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <meta content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" name="viewport">
</head>
<body>
<img id="authCode" onclick="changeCode()" src="/code" alt="验证码" title="点击更换" />

<script>
function changeCode() {
	document.getElementById("authCode").src = "/code?t=" + genTimestamp();
}
function genTimestamp() {
	var time = new Date();
	return time.getTime();
}
</script>
</body>
</html>
```

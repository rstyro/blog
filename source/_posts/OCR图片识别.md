---
title: OCR图片识别
date: 2023-09-25 16:44:07
updated: 2023-09-25 16:44:07
tags: [OCR,图片识别]
categories: Java
---

### 一、OCR图片识别

- 可以使用开源的 Tesseract转换文本
- Tesseract最初于1985年至1994年间在英国布里斯托尔的惠普实验室和美国科罗拉多州格里利的惠普公司开发，1996年对移植到Windows进行了更多更改，并在1998年进行了一些C++化。2005年，Tesseract由HP开源。从 2006 年到 2018 年，它由谷歌开发。


#### 1、安装Tesseract

- 安装介绍页：[https://tesseract-ocr.github.io/tessdoc/Installation.html](https://tesseract-ocr.github.io/tessdoc/Installation.html)
- Windows安装包下载地址：[https://github.com/UB-Mannheim/tesseract/wiki](https://github.com/UB-Mannheim/tesseract/wiki)
- 各个语言的数据集：[https://github.com/tesseract-ocr/tessdata](https://github.com/tesseract-ocr/tessdata)
- 以windows为例，直接双击傻瓜式安装在即可。有个问题就是默认没有中文的，可以选择英文，安装成功之后把中文的包放到安装目录下的：`tessdata` 即可,可以下载中文包地址：[https://github.com/tesseract-ocr/tessdata/raw/4.00/chi_sim.traineddata](https://github.com/tesseract-ocr/tessdata/raw/4.00/chi_sim.traineddata)


#### 2、使用Tesseract
- 可以使用 `tesseract.exe --help` 或者 `tesseract.exe --help-extra`查看命令提示

![](help.png)

- 简单例子，图片转文字

```bash
# 把图片help.png转换文字，输出到D:/test.txt
tesseract.exe D:/help.png D:/test.txt -l eng+chi_sim  --dpi 300

# 把图片help.png转换文字，控制台输出
tesseract.exe D:/help.png - -l eng+chi_sim  --dpi 300

```

#### 3、Java调用
- Java调用，可以使用`tess4j`
- 导入pom依赖

```
<!-- https://mvnrepository.com/artifact/net.sourceforge.tess4j/tess4j -->
<dependency>
    <groupId>net.sourceforge.tess4j</groupId>
    <artifactId>tess4j</artifactId>
    <version>5.7.0</version>
</dependency>
```

- 代码示例：

```java
import net.sourceforge.tess4j.Tesseract;
import net.sourceforge.tess4j.TesseractException;
import java.io.File;

public class ImageToText {
    public static void main(String[] args) throws TesseractException {
        // 安装tesseract的路径
        String tessData = "C:\\install\\tesseract-ocr\\tessdata";
        Tesseract tesseract = new Tesseract();
        // 设置 Tesseract OCR 引擎的语言
//        tesseract.setLanguage("eng");
        tesseract.setLanguage("eng+chi_sim");
        tesseract.setDatapath(tessData);
        //设置 psm  默认也是3
        tesseract.setPageSegMode(3);
        String pngPath = "D://test.png";
        String text = tesseract.doOCR(new File(pngPath));
        System.out.println("图片转文字="+text);
    }
}
```

#### 4、PDF图片转文字
- 有些pdf是又有图片又有文字的，如果直接获取文字可能会漏字符
- 可以尝试pdf转图片，然后再使用过OCR识别
- PDF转图片，可以使用`pdfbox`
- 依赖如下：
```xml
<dependency>
    <groupId>org.apache.pdfbox</groupId>
    <artifactId>pdfbox</artifactId>
    <version>2.0.27</version>
</dependency>
```

- 完整的PDF图片识别文字代码

```java
import cn.hutool.core.io.file.FileWriter;
import lombok.extern.slf4j.Slf4j;
import net.sourceforge.tess4j.Tesseract;
import net.sourceforge.tess4j.TesseractException;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.rendering.PDFRenderer;
import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;

@Slf4j
public class PdfToTextConverter {

    public static void main(String[] args) {
        // 安装tesseract的路径
        String tessData = "C:\\install\\tesseract-ocr\\tessdata";
        Tesseract tesseract = new Tesseract();
        // 设置 Tesseract OCR 引擎的语言
        tesseract.setLanguage("eng+chi_sim");
        tesseract.setDatapath(tessData);
        //设置 psm  默认也是3
        tesseract.setPageSegMode(3);
        tesseract.setTessVariable("user_defined_dpi", "300");
        // 设置字体
        tesseract.setTessVariable("textonly_pdf", "1");
        tesseract.setTessVariable("tessedit_create_pdf", "1");
        //选项来将不可识别的字符替换为占位符。
        tesseract.setTessVariable("pdf_font_name", "Arial");
        // 定义 PDF 文件路径和输出文本文件路径
        String pdfFilePath = "D:\\pdf\\email\\a.pdf";
        try {
            pdfToText(tesseract,pdfFilePath);
        } catch (Exception e) {
           log.error(e.getMessage(),e);
        }
    }

    /**
     * pdf提取文字
     * @param tesseract tesseract安装路径
     * @param pdfPath pdf路径
     */
    public static void pdfToText(Tesseract tesseract, String pdfPath) throws IOException, TesseractException {
        long begin = System.currentTimeMillis();
        // 将 PDF 文件转换为图像文件，并保存在指定目录中
        File file = new File(pdfPath);
        String pngPath = file.getPath().replace(".pdf", "_png");
        String txtPath = file.getPath().replace(".pdf", ".txt");
        int pages = convertToImage(pdfPath, pngPath, 300);
        FileWriter fileWriter = new FileWriter(txtPath);
        fileWriter.write("");
        // 逐个处理图像文件，并将 OCR 文本输出到文本文件中
        for (int i = 1; i <= pages; i++) {
            String imagePath = pngPath + "/page" + i + ".png";
            File imageFile = new File(imagePath);
            // 使用 Tesseract OCR 引擎提取文本内容
            String ocrText = tesseract.doOCR(imageFile);
            // 将 OCR 文本追加到输出文本文件中
            fileWriter.write(ocrText, true);
        }
        long end = System.currentTimeMillis();
        log.info("解析耗时={}秒，输出文件为={}", (end - begin) / 1000, txtPath);
    }

    /**
     * pdf转图片
     * @param pdfFilePath pdf文件路径
     * @param outputImageFolder 输出pdf的图片路径
     * @param dpi
     *  dpi 取值越高，输出的图片文件大小和渲染时间就越大（取值范围是 72 到 300）
     *  72 DPI：适用于屏幕显示和网络共享的低分辨率图片，例如 Web 图片、电子邮件附件等。
     *  96 DPI：适用于打印机打印和屏幕显示的中等分辨率图片，例如办公文档、幻灯片、简单的海报等。
     *  150 DPI：适用于打印机打印的高质量图片，例如印刷品、照片等。
     *  300 DPI：适用于高质量打印、印刷和出版，例如印刷品、高质量照片、艺术品等。
     * @return 图片个数
     */
    public static int convertToImage(String pdfFilePath, String outputImageFolder, int dpi) throws IOException {
        long start = System.currentTimeMillis();
        PDDocument document = null;
        try {
            File file = new File(outputImageFolder);
            if(!file.exists()){
                file.mkdirs();
            }
            // 加载 PDF 文件
            document = PDDocument.load(new File(pdfFilePath));
            // 初始化 PDF 渲染器
            PDFRenderer pdfRenderer = new PDFRenderer(document);
            // 逐页将 PDF 文件渲染成图片，并保存到指定目录中
            for (int i = 0; i < document.getNumberOfPages(); i++) {
                BufferedImage image = pdfRenderer.renderImageWithDPI(i, dpi);
                String imagePath = outputImageFolder + File.separator + "page" + (i + 1) + ".png";
                ImageIO.write(image, "png", new File(imagePath));
            }
        } finally {
            if (document != null) {
                document.close();
            }
            long end = System.currentTimeMillis();
            log.info("pdf转图片耗时={}毫秒",end-start);
        }
        return document.getNumberOfPages();
    }

}
```
- 首先把pdf的每页转为图片，然后再识别每张图片转为文字
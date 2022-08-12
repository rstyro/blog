---
title: Java如何操作办公软件
date: 2022-07-27 15:54:52
updated: 2022-07-27 15:54:52
tags: [Java]
categories: Java
---

## Java如何操作Office办公软件
- 在工作中，大家应该有遇到，用代码去读取或导出Excel、WORD、PDF 这类的需求吧
- 如果有做过这方面的大佬，应该都了解过 Apache POI .
- Apache POI 是用Java编写的免费开源的跨平台的 Java API.
- Apache POI提供API给Java对Microsoft Office格式档案读和写的功能。
- 但是大部分人都是用其他的框架，因为POI比较耗内存，如果导出数据量大的话容易OOM
- 而大部分的其他框架都是基于 POI基础上再次开发的。
- 废话不多说，直接上代码

### 一、操作Excel
- 操作Excel，现在国内比较出名的就是：阿里的 `easyexcel`
- 在POI的基础上优化与封装，让使用者更简单方便
- Github地址：[https://github.com/alibaba/easyexcel](https://github.com/alibaba/easyexcel)
- 文档地址：[https://easyexcel.opensource.alibaba.com/docs/current/](https://easyexcel.opensource.alibaba.com/docs/current/)
- 其实我觉得最好的文档就是他们写的Demo例子：
	- 进入Github,然后在源码的：`easyexcel-test`模块中
	- 找到：`com.alibaba.easyexcel.test.demo`这个包下的
	- 可以看到有：fill、read、web、write 四个包
	- fill 包介绍 Excel 填充的相关示例
	- read 就是去读Excel的相关示例
	- web 就是我们网页的上传和下载的操作
	- write 就是写Excel的相关操作示例
	- 上面的4个包里面的代码就是最好的文档。
- 来吧，入门

#### 1、快速使用
- **导入POM文件**
```
<dependency>
    <groupId>com.alibaba</groupId>
    <artifactId>easyexcel</artifactId>
    <version>3.1.1</version>
</dependency>
```

- 然后就可以开始使用了：EasyExcel 这个工具类了。
```Java
    /**
     * 最简单的读
     * <p>1. 创建excel对应的实体对象 参照{@link DemoData}
     * <p>2. 由于默认一行行的读取excel，所以需要创建excel一行一行的回调监听器，参照{@link DemoDataListener}
     * <p>3. 直接读即可
     */
    @Test
    public void simpleRead() {
        String fileName = TestFileUtil.getPath() + "demo" + File.separator + "demo.xlsx";
        // 这里 需要指定读用哪个class去读，然后读取第一个sheet 文件流会自动关闭
        EasyExcel.read(fileName, DemoData.class, new DemoDataListener()).sheet().doRead();
    }
    
        /**
     * 最简单的写
     * <p>1. 创建excel对应的实体对象 参照{@link com.alibaba.easyexcel.test.demo.write.DemoData}
     * <p>2. 直接写即可
     */
    @Test
    public void simpleWrite() {
        String fileName = TestFileUtil.getPath() + "write" + System.currentTimeMillis() + ".xlsx";
        // 这里 需要指定写用哪个class去读，然后写到第一个sheet，名字为模板 然后文件流会自动关闭
        // 如果这里想使用03 则 传入excelType参数即可
        EasyExcel.write(fileName, DemoData.class).sheet("模板").doWrite(data());
    }
    
    
       /**
     * 文件下载（失败了会返回一个有部分数据的Excel）
     * <p>
     * 1. 创建excel对应的实体对象 参照{@link DownloadData}
     * <p>
     * 2. 设置返回的 参数
     * <p>
     * 3. 直接写，这里注意，finish的时候会自动关闭OutputStream,当然你外面再关闭流问题不大
     */
    @GetMapping("download")
    public void download(HttpServletResponse response) throws IOException {
        // 这里注意 有同学反应使用swagger 会导致各种问题，请直接用浏览器或者用postman
        response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
        response.setCharacterEncoding("utf-8");
        // 这里URLEncoder.encode可以防止中文乱码 当然和easyexcel没有关系
        String fileName = URLEncoder.encode("测试", "UTF-8").replaceAll("\\+", "%20");
        response.setHeader("Content-disposition", "attachment;filename*=utf-8''" + fileName + ".xlsx");
        EasyExcel.write(response.getOutputStream(), DownloadData.class).sheet("模板").doWrite(data());
    }

    /**
     * 文件上传
     * <p>1. 创建excel对应的实体对象 参照{@link UploadData}
     * <p>2. 由于默认一行行的读取excel，所以需要创建excel一行一行的回调监听器，参照{@link UploadDataListener}
     * <p>3. 直接读即可
     */
    @PostMapping("upload")
    @ResponseBody
    public String upload(MultipartFile file) throws IOException {
        EasyExcel.read(file.getInputStream(), UploadData.class, new UploadDataListener(uploadDAO)).sheet().doRead();
        return "success";
    }
    
```
- 如上是最简单的用法，复杂用法可参考`com.alibaba.easyexcel.test.demo`这个包下示例


### 二、操作Word
- 也可以用POI，但是更推荐使用：`Poi-tl`
- Poi-tl 也是基于 POI 再次封装的。
- Github地址：[https://github.com/Sayi/poi-tl](https://github.com/Sayi/poi-tl)
- pot-tl 主要用于 Word模板 导出，在模板中可定制多种类型的数据：包含有文本、图片、表格、列表、图表、等等。
- 有多个版本，使用不同POI 就引入不同的版本，对照表如下：


|版本|POI版本|JDK版本|
|--|--|--|
|1.12.0 Documentation(当前最新版本)| Apache POI5.2.2+ |JDK1.8+|
|1.11.x Documentation| Apache POI5.1.0+ |JDK1.8+|
|1.10.x Documentation| Apache POI4.1.2 |JDK1.8+|
|1.10.3 Documentation| Apache POI4.1.2 |JDK1.8+|
|1.9.x Documentation| Apache POI4.1.2 |JDK1.8+|
|1.8.x Documentation| Apache POI4.1.2 |JDK1.8+|
|1.7.x Documentation| Apache POI4.0.0+ |JDK1.8+|
|1.6.x Documentation| Apache POI4.0.0+ |JDK1.8+|
|1.5.x Documentation| Apache POI3.16+ |JDK1.6+|


#### 1、快速开始
- **引入POM**
```xml
<dependency>
  <groupId>com.deepoove</groupId>
  <artifactId>poi-tl</artifactId>
  <version>1.12.0</version>
</dependency>
```

- 然后我们要先创建一个word模板，如： `template.docx`
- 比如我们在模板中，编写一个： {{title}}
- 我们简单的导出代码如下：

```java
XWPFTemplate template = XWPFTemplate.compile("template.docx").render(
  new HashMap<String, Object>(){{
    put("title", "Hi, poi-tl Word模板引擎");
}}).writeAndClose(new FileOutputStream("output.docx"));

```

- 所有的标签都是以 {{ 开头，以 }} 结尾，标签可以出现在任何位置，包括页眉，页脚，表格内部，文本框等，表格布局可以设计出很多优秀专业的文档，推荐使用表格布局。
- 当我们需要遍历的时候就用区块对,
- 区块对由前后两个标签组成，开始标签以?标识，结束标签以 `/` 。
- 图片和图表的使用
- 图片和多系列图表的标签是一个文本：`{{var}}`，标签位置在：`图表区格式—> 可选文字—>（新版本Microsoft Office标签位置在：编辑替换文字-替换文字）`。
- 我目前是新版本，所以位置在 `替换文字`。
- 如下图：


![](pie.png)

- 然后代码如下：

```java
ChartSingleSeriesRenderData pie = Charts.ofPie("编程语言分类",
             new String[] { "Java", "C++", "Go", "python"})
    .series("countries4", new Integer[] { 888, 666,333,222 }).create();
  
XWPFTemplate.compile(templateFile).render(new HashMap<String, Object>(){{
    put("title", "2022年7月");
    put("pieChart", pie);
}}).writeAndClose(new FileOutputStream("output.docx"));
```
- 更多详细用法可参数官方文档：[http://deepoove.com/poi-tl/](http://deepoove.com/poi-tl/)
- 文档还是很详细的。


### 三、操作PDF
- PDF一般导出功能也挺多的，如：HTML导出为PDF、word导出为PDF、excel导出为PDF等
- 其他我没用过我就不介绍了，我只用过excel导出为PDF。

#### 1、Excel导出PDF
- 在网上找到一个使用：`aspose-cells-8.5.2.jar`包的。
- 这个没有可以用的pom地址，需要额外下载。
- 代码如下：

```java
import com.aspose.cells.License;
import com.aspose.cells.PdfSaveOptions;
import com.aspose.cells.Workbook;
import java.io.FileOutputStream;
import java.io.InputStream;
public class Excel2Pdf {
    public static void main(String[] args) {
        String sourceFilePath="D:\\work_space\\文档\\产品需求文档\\文献收录情况检索报告参考模版（珠江医院图书馆）.xlsx";
        String desFilePath="D:\\work_space\\文档\\产品需求文档\\rest.pdf";
        excel2pdf(sourceFilePath, desFilePath);
    }

    /**
     * 获取license 去除水印
     * @return
     */
    public static boolean getLicense() {
        boolean result = false;
        try {
            InputStream is = Excel2Pdf.class.getClassLoader().getResourceAsStream("\\license.xml");
            License aposeLic = new License();
            aposeLic.setLicense(is);
            result = true;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return result;
    }

    /**
     * excel 转为pdf 输出。
     *
     * @param sourceFilePath  excel文件
     * @param desFilePathd  pad 输出文件目录
     */
    public static void excel2pdf(String sourceFilePath, String desFilePathd ){
        // 验证License 若不验证则转化出的pdf文档会有水印产生
        if (!getLicense()) {
            return;
        }
        try {
            Workbook wb = new Workbook(sourceFilePath);// 原始excel路径
            FileOutputStream fileOS = new FileOutputStream(desFilePathd);
            PdfSaveOptions pdfSaveOptions = new PdfSaveOptions();
            pdfSaveOptions.setOnePagePerSheet(true);
            
            int[] autoDrawSheets={3};
            //当excel中对应的sheet页宽度太大时，在PDF中会拆断并分页。此处等比缩放。
//            autoDraw(wb,autoDrawSheets);
            int[] showSheets={0};
            //隐藏workbook中不需要的sheet页。
            printSheetPage(wb,showSheets);
            wb.save(fileOS, pdfSaveOptions);
            fileOS.flush();
            fileOS.close();
            System.out.println("完毕");
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
    
    /**
     * 设置打印的sheet 自动拉伸比例
     * @param wb
     * @param page 自动拉伸的页的sheet数组
     */
    public static void autoDraw(Workbook wb,int[] page){
        if(null!=page&&page.length>0){
            for (int i = 0; i < page.length; i++) {
                wb.getWorksheets().get(i).getHorizontalPageBreaks().clear();
                wb.getWorksheets().get(i).getVerticalPageBreaks().clear();
            }
        }
    }

    /**
     * 隐藏workbook中不需要的sheet页。
     * @param wb
     * @param page 显示页的sheet数组
     */
    public static void printSheetPage(Workbook wb,int[] page){
        for (int i= 1; i < wb.getWorksheets().getCount(); i++)  {
            wb.getWorksheets().get(i).setVisible(false);
        }
        if(null==page||page.length==0){
            wb.getWorksheets().get(0).setVisible(true);
        }else{
            for (int i = 0; i < page.length; i++) {
                wb.getWorksheets().get(i).setVisible(true);
            }
        }
    }
}
```
- 其中的许可文件：`license.xml` 内容如下：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<License>
<Data>
    <Products>
        <Product>Aspose.Total for Java</Product>
        <Product>Aspose.Excel for Java</Product>
    </Products>
    <EditionType>Enterprise</EditionType>
    <SubscriptionExpiry>20991231</SubscriptionExpiry>
    <LicenseExpiry>20991231</LicenseExpiry>
    <SerialNumber>8bfe198c-7f0c-4ef8-8ff0-acc3237bf0d7</SerialNumber>
</Data>
<Signature>sNLLKGMUdF0r8O1kKilWAGdgfs2BvJb/2Xp8p5iuDVfZXmhppo+d0Ran1P9TKdjV4ABwAgKXxJ3jcQTqE/2IRfqwnPf8itN8aFZlV3TJPYeD3yWE7IT55Gz6EijUpC7aKeoohTb4w2fpox58wWoF3SNp6sK6jDfiAUGEHYJ9pjU=</Signature>
</License>

```

####  2、读取PDF
- 其实读取PDF的需求也算常见吧。
- 读取PDF一般用到：`pdfbox` 或 `e-iceblue` 或 `Aspose.PDF for Java`

##### 第一种:pdfbox
- 导入pom

```
<dependency>
    <groupId>org.apache.pdfbox</groupId>
    <artifactId>pdfbox</artifactId>
    <version>2.0.26</version>
</dependency>
```

- 读取文本，代码如下:

```java
public static void main(String[] args) throws IOException {
    PDDocument pdDocument = PDDocument.load(new File("Demo.pdf"));
    PDFTextStripper textStripper = new PDFTextStripper();
    String text = textStripper.getText(pdDocument);
    System.out.println("内容="+text);
    pdDocument.close();
}
```
- 更多用法参考官方文档：[https://pdfbox.apache.org/index.html](https://pdfbox.apache.org/index.html)



##### 第二种:e-iceblue
- 引入POM

```xml
<dependency>
    <groupId>e-iceblue</groupId>
    <artifactId>spire.pdf</artifactId>
    <version>5.4.0</version>
</dependency>
```

- 使用文档比pdfbox详细很多
- 地址：[https://www.e-iceblue.cn/pdf_java_document_operation/create-pdf-in-java.html](https://www.e-iceblue.cn/pdf_java_document_operation/create-pdf-in-java.html)
- 简单的读取文本：

```java
import com.spire.pdf.PdfDocument;
import com.spire.pdf.PdfPageBase;
import java.io.*;

public class Extract_Text {

	public static void main(String[] args) {
		
		//创建PdfDocument实例
		PdfDocument doc = new PdfDocument();
		//加载PDF文件
        doc.loadFromFile("test.pdf");

        //创建StringBuilder实例                
        StringBuilder sb = new StringBuilder();   
 
        PdfPageBase page;                
        //遍历PDF页面，获取每个页面的文本并添加到StringBuilder对象
        for(int i= 0;i<doc.getPages().getCount();i++){
            page = doc.getPages().get(i);            
            sb.append(page.extractText(true));
        }
        FileWriter writer;
        try {
        	//将StringBuilder对象中的文本写入到文本文件
            writer = new FileWriter("ExtractText.txt");
            writer.write(sb.toString());
            writer.flush();
        } catch (IOException e) {
            e.printStackTrace();
        }

        doc.close();
	}
}
```

##### 第三种:Aspose.PDF for Java
- 下载地址：[https://repository.aspose.com/pdf/22-7-1/](https://repository.aspose.com/pdf/22-7-1/)
- 

- 有机会再补充

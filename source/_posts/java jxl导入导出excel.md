---
title: java jxl导入导出excel
date: 2017-11-24 14:59:08
tags: [Java]
categories: Java
---
#  jxl导入导出excel

## 一、导入依赖
```
<dependency>
	<groupId>com.hynnet</groupId>
	<artifactId>jxl</artifactId>
	<version>2.6.12.1</version>
</dependency>
```

### java 操作jxl 工具类
```java
import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import javax.servlet.http.HttpServletResponse;

import org.springframework.beans.factory.annotation.Autowired;

import jxl.Sheet;
import jxl.Workbook;
import jxl.read.biff.BiffException;
import jxl.write.Label;
import jxl.write.WritableImage;
import jxl.write.WritableSheet;
import jxl.write.WritableWorkbook;

/**
 * @since 2017-11-24
 * @author rstyro
 *
 */
public class ExcelUtils {
	
	
	/**
	 * list 导出到本地excel 
	 * @param arrayList 数据,key-value 形式
	 * @param filePath 生成excel的路径
	 */
	public static void excelOut(ArrayList<Map<String,String>> arrayList,String filePath){
		 WritableWorkbook bWorkbook = null;  
	        try {  
	            bWorkbook = Workbook.createWorkbook(new File(filePath));  
	            // 通过Excel对象创建一个选项卡对象  
	            WritableSheet sheet = bWorkbook.createSheet("sheet1", 0);  
	            //使用循环将数据读出  
	            for (int i = 0; i < arrayList.size(); i++) {  
	            	Map<String, String> data = arrayList.get(i);  
	            	int index = 0;
	            	for (Map.Entry<String, String> entry : data.entrySet()) {
		                Label label=new Label(index,i,String.valueOf(entry.getValue()));  
		                sheet.addCell(label);  
		                ++index;
	            	}
	            }  
	            bWorkbook.write();  
	            System.out.println("导出成功：路径>"+filePath);
	        } catch (Exception e) {  
	            e.printStackTrace();  
	        } finally {  
	            try {  
	                bWorkbook.close();  
	            } catch (Exception e) {  
	                e.printStackTrace();  
	            }  
	        }  
	}
	
	/**
	 * list 导出到 浏览器 excel 
	 * @param arrayList 数据,key-value 形式
	 * @param filePath 生成excel的路径
	 */
	public static void excelOut(ArrayList<Map<String,String>> arrayList,HttpServletResponse response){
		WritableWorkbook bWorkbook = null;  
		try {  
			bWorkbook = Workbook.createWorkbook(response.getOutputStream());  
			// 通过Excel对象创建一个选项卡对象  
			WritableSheet sheet = bWorkbook.createSheet("sheet1", 0);  
			//使用循环将数据读出  
			for (int i = 0; i < arrayList.size(); i++) {  
				Map<String, String> data = arrayList.get(i);  
				int index = 0;
				for (Map.Entry<String, String> entry : data.entrySet()) {
					Label label=new Label(index,i,String.valueOf(entry.getValue()));  
					sheet.addCell(label);  
					++index;
				}
			}  
			bWorkbook.write();  
			String fileName="下载的文件名";
			response.setCharacterEncoding("utf-8");
			response.reset();
			response.setContentType("application/OCTET-STREAM;charset=utf-8");
			response.setHeader("pragma", "no-cache");
			response.addHeader("Content-Disposition", "attachment;filename=\""+ fileName + ".xls\"");// 点击导出excle按钮时候页面显示的默认名称
		} catch (Exception e) {  
			e.printStackTrace();  
		} finally {  
			try {  
				bWorkbook.close();  
			} catch (Exception e) {  
				e.printStackTrace();  
			}  
		}  
	}
	
	
	/**
	 * 图片 导出到本地excel
	 * @param filePath 生成excel的路径
	 * @param imgPath 图片路径
	 */
	public static void excelOut(String filePath,String imgPath){
		WritableWorkbook bWorkbook = null;  
		try {  
			bWorkbook = Workbook.createWorkbook(new File(filePath));  
			// 通过Excel对象创建一个选项卡对象  
			WritableSheet sheet = bWorkbook.createSheet("sheet1", 0);  
            File imgFile = new File(imgPath); 
            WritableImage image = new WritableImage(0,0,5,5,imgFile); //前两位是起始格，后两位是图片占多少个格，并非是位置。
            sheet.addImage(image); 
			bWorkbook.write();  
			System.out.println("导出成功：路径>"+filePath);
		} catch (Exception e) {  
			e.printStackTrace();  
		} finally {  
			try {  
				bWorkbook.close();  
			} catch (Exception e) {  
				e.printStackTrace();  
			}  
		}  
	}
	
	/**
	 * 导出到 浏览器  excel
	 * @param filePath 生成excel的路径
	 * @param imgPath 图片路径
	 */
	public static void excelOut(HttpServletResponse response,String imgPath){
		WritableWorkbook bWorkbook = null;  
		try {  
			bWorkbook = Workbook.createWorkbook(response.getOutputStream());  
			// 通过Excel对象创建一个选项卡对象  
			WritableSheet sheet = bWorkbook.createSheet("sheet1", 0);  
			File imgFile = new File(imgPath); 
			WritableImage image = new WritableImage(0,0,5,5,imgFile); //前两位是起始格，后两位是图片占多少个格，并非是位置。
			sheet.addImage(image); 
			bWorkbook.write(); 
			String fileName="下载的文件名";
			response.setCharacterEncoding("utf-8");
			response.reset();
			response.setContentType("application/OCTET-STREAM;charset=utf-8");
			response.setHeader("pragma", "no-cache");
			response.addHeader("Content-Disposition", "attachment;filename=\""+ fileName + ".xls\"");// 点击导出excle按钮时候页面显示的默认名称
		} catch (Exception e) {  
			e.printStackTrace();  
		} finally {  
			try {  
				bWorkbook.close();  
			} catch (Exception e) {  
				e.printStackTrace();  
			}  
		}  
	}
      
    /**
     * 将Excel中的数据导入  
     * @param filePath 文件路径
     * @return
     */
    public static ArrayList<Map<String,String>> ExcelIn(String filePath){  
    	ArrayList<Map<String,String>>arrayList=new ArrayList<Map<String,String>>();  
    	Workbook bWorkbook=null;  
    	try {  
    		bWorkbook=Workbook.getWorkbook(new File(filePath));  
    		Sheet sheet=bWorkbook.getSheet(0);  
    		for (int i = 0; i < sheet.getRows(); i++) {  
    			Map<String,String> map = new HashMap<String, String>();
    			//获取单元格的值  
    			map.put("name", sheet.getCell(0,i).getContents());
    			map.put("age", sheet.getCell(1,i).getContents());
    			map.put("sex", sheet.getCell(2,i).getContents());
    			arrayList.add(map);  
    		}  
			
			//查询图片个数
    		for(int i=0;i<sheet.getNumberOfImages();i++) {
    			//获取图片流
    			InputStream input = new ByteArrayInputStream(sheet.getDrawing(i).getImageData());
    			//....之后保存省略
    		}
    		
    	} catch (BiffException e) {  
    		// TODO Auto-generated catch block  
    		e.printStackTrace();  
    	} catch (IOException e) {  
    		// TODO Auto-generated catch block  
    		e.printStackTrace();  
    	}finally {  
    		bWorkbook.close();  
    	}  
    	return arrayList;  
    } 
    
    @Autowired
	public static void main(String[] args) {
		Map<String, String> map1 = new HashMap<String, String>();
		map1.put("name", "名称");
		map1.put("age", "年龄");
		map1.put("sex", "性别");
		Map<String, String> map2 = new HashMap<String, String>();
		map2.put("name", "靓女");
		map2.put("age", "20");
		map2.put("sex", "女人");
		Map<String, String> map3 = new HashMap<String, String>();
		map3.put("name", "帅哥");
		map3.put("age", "30");
		map3.put("sex", "男人");
		ArrayList<Map<String,String>> arrayList = new ArrayList<Map<String,String>>();
		arrayList.add(map1);
		arrayList.add(map2);
		arrayList.add(map3);
		ExcelUtils.excelOut(arrayList, "F://map.xls");
    	
//    	ArrayList<Map<String,String>> array = ExcelUtils.ExcelIn("F://map.xls");
//    	for(Map<String, String> obj:array){
//    		for(Map.Entry<String, String> ent: obj.entrySet()){
//    			System.out.println(ent.getKey()+":"+ent.getValue());
//    		}
//    		System.out.println("=============================");
//    	}
	}
}

```
## 二、其他

### 1、设置字体
```java
WritableFont font1= new WritableFont(WritableFont.TIMES, 16, WritableFont.BOLD); //设置字体格式为excel支持的格式 WritableFont font3=new WritableFont(WritableFont.createFont("楷体 _GB2312"), 12, WritableFont.NO_BOLD);
WritableCellFormat format1=new WritableCellFormat(font1);
Label label=new Label(0, 0, "data 4 test", format1);
```
### 2、对齐方式
```java
//把水平对齐方式指定为居中
format1.setAlignment(jxl.format.Alignment.CENTRE);
//把垂直对齐方式指定为居中
format1.setVerticalAlignment(jxl.format.VerticalAlignment.CENTRE);
//设置自动换行
format1.setWrap(true);
```

### 3、合并单元格
```java
WritableSheet sheet = book.createSheet("sheet1", 0);  
//合并第一列第一行到第六列第一行的所有单元格
//合并既可以是横向的，也可以是纵向的。合并后的单元格不能再次进行合并，否则会触发异常。
sheet.mergeCells(0, 0, 5, 0);
```

### 4、指定单元格 行高与列宽
```java
//作用是指定第i+1行的高度
WritableSheet.setRowView(int i, int height);
//比如：将第一行的高度设为200
sheet.setRowView(0, 200);

//作用是指定第i+1列的宽度，
WritableSheet.setColumnView(int i,int width);
//比如：将第一列的宽度设为30
sheet.setColumnView(0, 30);
```
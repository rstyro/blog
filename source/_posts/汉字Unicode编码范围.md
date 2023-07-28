---
title: 汉字Unicode编码范围
date: 2023-07-28 14:50:29
updated: 2023-07-28 14:50:29
tags: [Unicode]
categories: Java
---

### 一、汉字Unicode编码范围


|字符集	|字数	|Unicode 编码|
|--|--|:--|
|基本汉字	|20902字	 |4E00-9FA5|
|基本汉字补充	 |90字	 |9FA6-9FFF|
|扩展A	|6592字	 |3400-4DBF|
|扩展B	|42720字	 |20000-2A6DF|
|扩展C	|4154字	 |2A700-2B739|
|扩展D	|222字	 |2B740-2B81D|
|扩展E	|5762字	 |2B820-2CEA1|
|扩展F	|7473字	 |2CEB0-2EBE0|
|扩展G	|4939字	 |30000-3134A|
|扩展H	|4192字	 |31350-323AF|
|康熙部首	|214字	 |2F00-2FD5|
|部首扩展	|115字①	 |2E80-2EF3|
|兼容汉字	|472字②	 |F900-FAD9|
|兼容扩展	|542字	 |2F800-2FA1D|
|汉字笔画	|36字	  |31C0-31E3|
|汉字结构	|12字 	 |2FF0-2FFB|
|汉语注音	|43字 	 |3105-312F|
|注音扩展	|32字 	 |31A0-31BF|
|〇	|1字	|3007|



#### 1、代码遍历
- 代码打印unicode汉字

```java
public class ChineseCharUtil {
    public static void main(String[] args) {
        StringBuilder sb = new StringBuilder();
        // 基本汉字
        getRangeChar("4E00", "9FA5",sb);
        // 基本汉字补充
        getRangeChar("9FA6", "9FFF",sb);
        // 扩展A
        getRangeChar("3400", "4DBF",sb);
        // 扩展B
        getRangeChar("20000", "2A6DF",sb);
        // 扩展C
        getRangeChar("2A700", "2B739",sb);
        // 扩展D
        getRangeChar("2B740", "2B81D",sb);
        // 扩展E
        getRangeChar("2B820", "2CEA1",sb);
        // 扩展F
        getRangeChar("2CEB0", "2EBE0",sb);
        // 扩展G
        getRangeChar("30000", "3134A",sb);
        // 扩展H
        getRangeChar("31350", "323AF",sb);
        // 康熙部首
        getRangeChar("2F00", "2FD5",sb);
        // 部首扩展
        getRangeChar("2E80", "2EF3",sb);
        // 兼容汉字
        getRangeChar("F900", "FAD9",sb);
        // 兼容扩展
        getRangeChar("2F800", "2FA1D",sb);
        // 汉字笔画
        getRangeChar("31C0", "31E3",sb);
        // 汉字结构
        getRangeChar("2FF0", "2FFB",sb);
        // 汉字拼音
        getRangeChar("3105", "312F",sb);
        // 拼音扩展
        getRangeChar("31A0", "31BF",sb);
        System.out.println(sb.toString());
    }

    public static String getRangeChar(String start,String end,StringBuilder contentBuilder){
        if(null==contentBuilder){
            contentBuilder = new StringBuilder();
        }
        for (int i = Integer.parseInt(start,16); i < Integer.parseInt(end,16); i++) {
            contentBuilder.append((char) i).append(",");
        }
        contentBuilder.append("\n");
        return contentBuilder.toString();
    }
}
```
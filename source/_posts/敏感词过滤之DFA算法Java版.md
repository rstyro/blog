---
title: 敏感词过滤之DFA算法Java版
date: 2020-10-17 11:22:11
updated: 2020-10-17 11:22:11
tags: [算法]
categories: Java
---


### 一、前言

在工作中需要做敏感词过滤，如何高效的过滤敏感词，然后通过科普知道了DFA算法。


### 二、DFA概述

在计算理论中，**确定有限状态自动机(DFA)** 是一个能实现状态转移的自动机。对于一个给定的输入，DFA会根据当前状态和输入符号，确定地转移到下一个状态。与之类似还有`非确定有限自动机(NFA)`。



简单的说就是：DFA消耗输入符号的字符串。对每个输入符号它变换到一个新状态直到所有输入符号到被耗尽。下一个状态是唯一确定的。



> 个人粗俗的理解：就像树的结构，从根开始到枝叶子结束,沿着字符路径走到叶子节点，就完成了一个敏感词的匹配


本篇不讲它的函数公式这些，直接代码走起！！！



### 三、Java代码实现



我们知道敏感词都是一个词语，我们把词语拆成一个字然后再关联组合，这样是不是就像DFA的状态转移。在Java中可以使用HashMap来实现这样的结构。
```tex
// 比如，现在的敏感词有：代开发票、代购、代购商
// 转为DFA 状态就会变成如下这样：

代 → 开 → 发 → 票
  ↘
    购 → 商
	
```



#### 1、构建DFA 模型结构

我们要知道什么时候结束，所以在代码里加一个结束标识(`isEnd`)。

```java
/**
 * 敏感词集合
 */
public static Map<String,Object> sensitiveWordMap;

/**
 * 初始化敏感词库，构建DFA算法模型
 * @param sensitiveWordSet 需要加载的敏感词集合
 */
private static void load(Set<String> sensitiveWordSet) {
    //初始化敏感词容器，减少扩容操作
    sensitiveWordMap = new HashMap<>(sensitiveWordSet.size());
    String key;
	// 总词库的指针
    Map<String,Object> nowMap;
    Iterator<String> iterator = sensitiveWordSet.iterator();
    while (iterator.hasNext()) {
        key = iterator.next();
		// 加载下一个词重新指向总词库，因为addKey里面指针被改变了
        nowMap = sensitiveWordMap;
        addKey(key, nowMap);
    }
}

/**
 * 添加敏感词
 *
 * @param key    要添加的敏感词
 * @param nowMap 已加载的敏感词库
 */
public static void addKey(String key, Map<String,Object> nowMap) {
    if (StrUtil.isBlank(key)) {
        return;
    }
	// 把关键字拆成一个一个字
    for (int i = 0; i < key.length(); i++) {
        //转换成char型
        char keyChar = key.charAt(i);
        //库中获取关键字
        Object wordMap = nowMap.get(String.valueOf(keyChar));
        //如果存在该key，直接赋值，用于下一个循环获取
        if (wordMap != null) {
			// 这里的情况就相当与上面的例子：代购 和 代购商
            nowMap = (Map<String,Object>) wordMap;
        } else {
            //不存在则，则构建一个map，同时将isEnd设置为0，因为他不是最后一个
            Map<String,Object> newWorMap = new HashMap<>();
            //不是最后一个
            newWorMap.put("isEnd", "0");
			// 这里注意一点，这个put 的是一个对象指针，如果对象改变，put进行的对象也就改变了
			// 然后nowMap 最开始是总词库的指针，所以这里虽然没有出现总词库，但是总词库最终还是会添加到新的key
            nowMap.put(String.valueOf(keyChar), newWorMap);
            nowMap = newWorMap;
        }
        if (i == key.length() - 1) {
            //最后一个
            nowMap.put("isEnd", "1");
        }
    }
}
```



上面已经构建好了DFA 词库模型。长如下：

```
{
    "代": {
        "开": {
            "发": {
                "票": {
                    "isEnd": "1"
                },
                "isEnd": "0"
            },
            "isEnd": "0"
        },
        "isEnd": "0",
        "购": {
            "商": {
                "isEnd": "1"
            },
            "isEnd": "1"
        }
    }
}
```

发现 `购` 和 `商` 的标识都是 `1` 也就是结束，这是正常的。





#### 2、如何查找

我们查找是否包含敏感词的时候也是一个一个去找，代码如下：

```java
/**
 * 判断文字是否包含敏感字符
 *
 * @param txt       文字
 * @param matchType 匹配规则 1：最小匹配规则，2：最大匹配规则
 * @return 若包含返回true，否则返回false
 */
public static boolean contains(String txt, int matchType) {
    // 总词库的指针
    Map<String,Object> sensitiveMap = sensitiveWordMap;
    for (int i = 0; i < txt.length(); i++) {
        //判断是否包含敏感字符
        int matchFlag = checkWord(txt, i, matchType, sensitiveMap);
        if (matchFlag > 0) {
            //大于0存在，返回true
            return true;
        }
    }
    return false;
}

/**
 * 校验文字是否包含敏感词
 * @param txt          文字
 * @param beginIndex   开始索引
 * @param matchType    匹配规则
 * @param wordStoreMap 敏感词库
 * @return 返回找到敏感词字符的长度
 */
private static int checkWord(String txt, int beginIndex, int matchType, Map<String,Object> wordStoreMap) {
    //敏感词结束标识位：用于敏感词只有1位的情况
    boolean flag = false;
    //匹配标识数默认为0
    int matchFlag = 0;
    char word;
    Map<String,Object> nowMap = wordStoreMap;
    for (int i = beginIndex; i < txt.length(); i++) {
        word = txt.charAt(i);
        //获取指定key
        nowMap = (Map<String,Object>) nowMap.get(String.valueOf(word));
        //存在，则判断是否为最后一个
        if (nowMap != null) {
            //找到相应key，匹配标识+1
            matchFlag++;
            //如果为最后一个匹配规则,结束循环，返回匹配标识数
            if ("1".equals(nowMap.get("isEnd"))) {
                //结束标志位为true
                flag = true;
                //最小规则，直接返回,最大规则还需继续查找
                if (MIN_MATCHTYPE == matchType) {
                    break;
                }
            }
        } else {
            //不存在，直接返回
            break;
        }
    }
    return flag ? matchFlag : 0;
}
```

其实代码不一定非得和我上面写得一样，我只是拆得比较细，后面再组装，只要看懂思路之后随便改成你想要的方法。



完整版的：
```java
import lombok.extern.slf4j.Slf4j;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.*;
import java.util.regex.Pattern;

/**
 * DFA算法
 *
 * @author lrs
 * @since 2020-10-16
 */
@Slf4j
public class SensitiveWordUtils {
    /**
     * 敏感词匹配规则
     * 最小匹配规则，如：敏感词库["代购","代购商"]，语句："我是代购商"，匹配结果：我是[代购]商
     */
    public static final int MIN_MATCHTYPE = 1;

    /**
     * 最大匹配规则，如：敏感词库["代购","代购商"]，语句："我是代购商"，匹配结果：我是[代购商]
     */
    public static final int MAX_MATCHTYPE = 2;

    /**
     * 敏感词集合
     */
    public static Map<String,Object> sensitiveWordMap;

    /**
     * 加载敏感词库
     * @param sensitiveWordSet 敏感词库
     */
    public static synchronized void load(Set<String> sensitiveWordSet) {
        initWords(sensitiveWordSet);
        log.info("==加载敏感词库={}个==", sensitiveWordSet.size());
    }

    /**
     * 初始化敏感词库，构建DFA算法模型
     * @param sensitiveWordSet 敏感词库
     */
    private static void initWords(Set<String> sensitiveWordSet) {
        //初始化敏感词容器，减少扩容操作
        sensitiveWordMap = new HashMap<>(sensitiveWordSet.size());
        String word;
        Map<String,Object> nowMap;
        Iterator<String> iterator = sensitiveWordSet.iterator();
        while (iterator.hasNext()) {
            word = iterator.next();
            nowMap = sensitiveWordMap;
            addWord(word, nowMap);
        }
    }
    /**
     * 添加敏感词
     *
     * @param word    要添加的敏感词
     * @param nowMap 已加载的敏感词库
     */
    public static void addWord(String word, Map<String, Object> nowMap) {
        if (StrUtil.isBlank(word)) {
            return;
        }
        for (int i = 0; i < word.length(); i++) {
            //转换成char型
            char keyChar = word.charAt(i);
            //库中获取关键字
            Object wordMap = nowMap.get(String.valueOf(keyChar));
            //如果存在该key，直接赋值，用于下一个循环获取
            if (wordMap != null) {
                nowMap = (Map<String, Object>) wordMap;
            } else {
                //不存在则，则构建一个map，同时将isEnd设置为0，因为他不是最后一个
                Map<String, Object> newWorMap = new HashMap<>();
                //不是最后一个
                newWorMap.put("isEnd", "0");
                nowMap.put(String.valueOf(keyChar), newWorMap);
                nowMap = newWorMap;
            }
            if (i == word.length() - 1) {
                //最后一个
                nowMap.put("isEnd", "1");
            }
        }
    }
	
	/**
     * 移除敏感词
     * @param word 敏感词
     * @param nowMap 总词库
     * @return boolean
     */
    public static boolean removeWord(String word, Map<String, Object> nowMap) {
        if (StrUtil.isBlank(word)) {
            return false;
        }
        boolean canRemove=false;
        String oneLeveKey = String.valueOf(word.charAt(0));
        // 最外层的map
        Map<String,Object>  tempMap = (Map<String, Object>) nowMap.get(oneLeveKey);
        for (int i = 1; i < word.length(); i++) {
            //转换成char型
            char keyChar = word.charAt(i);
            //库中获取关键字
            Object wordMap = tempMap.get(String.valueOf(keyChar));
            if(wordMap==null){
                canRemove=false;
                break;
            }
            tempMap= (Map<String, Object>) wordMap;
            canRemove=true;
        }
        if(canRemove && tempMap!=null){
            if(tempMap.size()==1){
                nowMap.remove(oneLeveKey);
                log.info("敏感词库已移除：{} 关键词",word);
            }else {
                tempMap.put("isEnd","0");
                log.info("敏感词库已更新：{} 状态",word);
            }
        }
        return canRemove;
    }

    /**
     * 获取词库的方法，本地或redis
     * @return 返回本地敏感词库，可改为redis
     */
    public static Map<String,Object> getSensitiveMap() {
        return sensitiveWordMap;
    }

    /**
     * 判断文字是否包含敏感字符
     *
     * @param txt       文字
     * @param matchType 匹配规则 1：最小匹配规则，2：最大匹配规则
     * @return 若包含返回true，否则返回false
     */
    public static boolean contains(String txt, int matchType) {
        Map<String,Object> sensitiveMap = getSensitiveMap();
        for (int i = 0; i < txt.length(); i++) {
            //判断是否包含敏感字符
            int matchFlag = checkWord(txt, i, matchType, sensitiveMap);
            if (matchFlag > 0) {
                //大于0存在，返回true
                return true;
            }
        }
        return false;
    }

    /**
     * 判断文字是否包含敏感字符
     *
     * @param txt 文字
     * @return 若包含返回true，否则返回false
     */
    public static boolean contains(String txt) {
        return contains(txt, MIN_MATCHTYPE);
    }

    /**
     * 获取文字中的敏感词
     *
     * @param txt       文字
     * @param matchType 匹配规则 1：最小匹配规则，2：最大匹配规则
     * @return 返回匹配的敏感词
     */
    public static Set<String> getSensitiveWord(String txt, int matchType) {
        Map<String,Object> sensitiveMap = getSensitiveMap();
        Set<String> resultSet = new HashSet<>();
        for (int i = 0; i < txt.length(); i++) {
            //判断是否包含敏感字符
            int length = checkWord(txt, i, matchType, sensitiveMap);
            //存在,加入list中
            if (length > 0) {
                resultSet.add(txt.substring(i, i + length));
                //减1的原因，是因为for会自增
                i = i + length - 1;
            }
        }
        return resultSet;
    }

    /**
     * 获取文字中的敏感词
     * @param txt 文字
     * @return 返回敏感词
     */
    public static Set<String> getSensitiveWord(String txt) {
        return getSensitiveWord(txt, MIN_MATCHTYPE);
    }

    /**
     * 替换敏感字字符
     * @param txt 文本
     * @param replaceValue 替换的字符，替换单个字
     * @return 返回替换后的字符串
     */
    public static String replaceWordByOne(String txt, String replaceValue) {
        return replaceWord(txt, replaceValue, MAX_MATCHTYPE,false);
    }

    /**
     * 替换敏感字字符
     * @param txt 文本
     * @param replaceStr 替换的字符串，替换整个词
     * @return 返回替换后的字符串
     */
    public static String replaceWordByAll(String txt, String replaceStr) {
        return replaceWord(txt, replaceStr, MAX_MATCHTYPE,true);
    }

    /**
     * 替换敏感字字符
     * @param txt 文本
     * @param replaceValue 替换的字符
     * @param matchType   敏感词匹配规则
     * @param isReplaceAll replaceValue 替换所有还是替换 敏感词的一个字，true-所有。false- 一个
     * @return 返回替换后的字符串
     */
    public static String replaceWord(String txt, String replaceValue, int matchType,boolean isReplaceAll) {
        String resultTxt = txt;
        //获取所有的敏感词
        Set<String> set = getSensitiveWord(txt, matchType);
        Iterator<String> iterator = set.iterator();
        String word;
        String replaceString;
        while (iterator.hasNext()) {
            word = iterator.next();
            replaceString = isReplaceAll?replaceValue:getReplaceChars(replaceValue, word.length());
            resultTxt = resultTxt.replaceAll(word, replaceString);
        }
        return resultTxt;
    }

    /**
     * 获取替换字符串
     * @param replaceChar 替换的字符
     * @param length 长度
     * @return 返回 length 个 replaceChar
     */
    private static String getReplaceChars(Object replaceChar, int length) {
        StringBuilder sb = new StringBuilder();
        sb.append(replaceChar);
        for (int i = 1; i < length; i++) {
            sb.append(replaceChar);
        }
        return sb.toString();
    }

    /**
     * 校验文字是否包含敏感词
     * @param txt          文字
     * @param beginIndex   开始索引
     * @param matchType    匹配规则
     * @param wordStoreMap 敏感词库
     * @return 返回找到敏感词字符的长度
     */
    private static int checkWord(String txt, int beginIndex, int matchType, Map<String,Object> wordStoreMap) {
        //敏感词结束标识位：用于敏感词只有1位的情况
        boolean flag = false;
        //匹配标识数默认为0
        int matchFlag = 0;
        char word;
        Map<String,Object> nowMap = wordStoreMap;
        for (int i = beginIndex; i < txt.length(); i++) {
            word = txt.charAt(i);
            //获取指定key
            nowMap = (Map<String,Object>) nowMap.get(String.valueOf(word));
            //存在，则判断是否为最后一个
            if (nowMap != null) {
                //找到相应key，匹配标识+1
                matchFlag++;
                //如果为最后一个匹配规则,结束循环，返回匹配标识数
                if ("1".equals(nowMap.get("isEnd"))) {
                    //结束标志位为true
                    flag = true;
                    //最小规则，直接返回,最大规则还需继续查找
                    if (MIN_MATCHTYPE == matchType) {
                        break;
                    }
                }
            } else {
                //不存在，直接返回
                break;
            }
        }
        return flag ? matchFlag : 0;
    }

    /**
     * 过滤常见特殊字符与空格
     * @param str
     * @return
     */
    public static String filterSpecialStr(String str) {
        String regEx = "[`~!@#$%^&*()+=|{}:;\\\\[\\\\].<>/?~！@#￥%……&*（）——+|{}【】‘；：”“’。，、？']";
        Pattern pattern = Pattern.compile(regEx);
        return pattern.matcher(str).replaceAll("").replaceAll(" ","").trim();
    }

    /**
     * 读取敏感词文件
     * @param filePaths 文件绝对路径，支持多个文件
     * @return 返回敏感词词库
     */
    public static Set<String> readFile(List<String> filePaths) {
        Set<String> result = new HashSet<>();
        InputStreamReader read = null;
        BufferedReader bufferedReader = null;
        try {
            if (filePaths != null && filePaths.size() > 0) {
                for (String filePath : filePaths) {
                    File file = new File(filePath);
                    int count = 0;
                    //判断文件是否存在
                    if (file.isFile() && file.exists()) {
                        read = new InputStreamReader(new FileInputStream(file), StandardCharsets.UTF_8);
                        bufferedReader = new BufferedReader(read);
                        String lineTxt ;
                        while ((lineTxt = bufferedReader.readLine()) != null) {
                            if (StrUtil.isNotBlank(lineTxt)) {
                                result.add(lineTxt);
                                count++;
                            }
                        }
                    } else {
                        log.info("找不到指定的文件={}", filePath);
                    }
                    log.info("加载文件：{}，个数={}", filePath, count);
                }
            }
            if (bufferedReader != null) {
                bufferedReader.close();
            }
            if (read != null) {
                read.close();
            }
        } catch (Exception e) {
            log.error("加载敏感词文件出错", e);
        }
        return result;
    }


    public static void main(String[] args) {
        test();
    }


    public static void test() {
        List<String> fileList = new ArrayList<>();
//        fileList.add("D:\\敏感词\\广告.txt");

        Set<String> sensitiveWordSet = readFile(fileList);
        sensitiveWordSet.add("代开发票");
        sensitiveWordSet.add("代购");
        sensitiveWordSet.add("代购商");
        
        System.out.println("加载敏感词个数：" + sensitiveWordSet.size());
        //初始化敏感词库
        SensitiveWordUtils.load(sensitiveWordSet);
        String content = "结束标志位结束代购商标职业志位结束标志敏感位结束标志位代购结束标志位结束苹果标";
        long beginTime = System.currentTimeMillis();
        boolean isContains = contains(content);
        Set<String> sensitiveWord = getSensitiveWord(content);
        System.out.println("敏感词=" + sensitiveWord);
        System.out.println("耗时：" + (System.currentTimeMillis() - beginTime) + "ms");
        System.out.println(replaceWordByOne(content, "*"));
        System.out.println(replaceWordByAll(content, "替换整个词"));
    }
}

```

不需要的方法自行去掉，自己改一些就行。



#### 3、优化版

上面是我好多年前写的，最近重构了一版。

```java
import cn.hutool.core.util.StrUtil;
import com.alibaba.fastjson2.JSON;
import lombok.extern.slf4j.Slf4j;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.*;
import java.util.regex.Pattern;

/**
 * DFA算法实现的敏感词过滤工具类
 * @author rstyro
 * @since 2025-11-03
 */
@Slf4j
public class SensitiveWordUtil {

    /**
     * 敏感词匹配规则
     * 最小匹配规则，如：敏感词库["代购","代购商"]，语句："我是代购商"，匹配结果：我是[代购]商
     */
    public static final int MIN_MATCH_TYPE = 1;
    /**
     * 最大匹配规则，如：敏感词库["代购","代购商"]，语句："我是代购商"，匹配结果：我是[代购商]
     */
    public static final int MAX_MATCH_TYPE = 2;

    /**
     * 敏感词集合
     */
    private static volatile Map<Character, SensitiveNode> sensitiveWordMap;

    /**
     * 特殊字符过滤正则
     * 匹配常见特殊字符和空格
     */
    private static final Pattern SPECIAL_CHAR_PATTERN =
            Pattern.compile("[`~!@#$%^&*()+=|{}:;\\[\\].<>/?~！@#￥%……&*（）——+|{}【】'；：\"。，、？\\s]");

    /**
     * 敏感词节点内部类
     */
    private static class SensitiveNode {
        // 标记当前节点是否为一个敏感词的结尾
        private boolean isEnd;
        // 子节点映射Map，Key为字符，Value为对应的子节点
        private final Map<Character, SensitiveNode> children;

        public SensitiveNode() {
            this.children = new HashMap<>();
            this.isEnd = false;
        }

        public boolean isEnd() {
            return isEnd;
        }

        public void setEnd(boolean end) {
            isEnd = end;
        }

        public Map<Character, SensitiveNode> getChildren() {
            return children;
        }

        public SensitiveNode getChild(Character key) {
            return children.get(key);
        }

        public SensitiveNode putChild(Character key, SensitiveNode node) {
            return children.put(key, node);
        }

        public SensitiveNode removeChild(Character key) {
            return children.remove(key);
        }

        public boolean hasChildren() {
            return !children.isEmpty();
        }
    }


    /**
     * 加载敏感词库
     * @param sensitiveWordSet 敏感词集合
     */
    public static synchronized void load(Set<String> sensitiveWordSet) {
        if (sensitiveWordSet == null || sensitiveWordSet.isEmpty()) {
            sensitiveWordMap = Collections.emptyMap();
            log.warn("==加载敏感词库: 词库为空==");
            return;
        }

        initWords(sensitiveWordSet);
        log.info("==加载敏感词库完成，共{}个敏感词==", sensitiveWordSet.size());
    }

    /**
     * 初始化敏感词库，构建DFA算法模型
     * 将平面结构的敏感词集合转换为树形结构，便于快速查找
     */
    private static void initWords(Set<String> sensitiveWordSet) {
        Map<Character, SensitiveNode> newWordMap = new HashMap<>(sensitiveWordSet.size());

        for (String word : sensitiveWordSet) {
            if (StrUtil.isNotBlank(word)) {
                addWord(word, newWordMap);
            }
        }

        sensitiveWordMap = newWordMap;
    }

    /**
     * 添加敏感词
     * @param word 要添加的敏感词，如果为空则忽略
     * @param wordMap 目标词库映射表
     */
    public static void addWord(String word, Map<Character, SensitiveNode> wordMap) {
        if (StrUtil.isBlank(word)) {
            return;
        }
        // 每个敏感词，都从根节点开始查找
        Map<Character, SensitiveNode> currentMap = wordMap;

        for (int i = 0; i < word.length(); i++) {
            char keyChar = word.charAt(i);
            SensitiveNode node = currentMap.get(keyChar);

            if (node == null) {
                node = new SensitiveNode();
                currentMap.put(keyChar, node);
            }

            if (i == word.length() - 1) {
                node.setEnd(true);
            }
            // 移动到下一层节点
            currentMap = node.getChildren();
        }
    }

    /**
     * 移除敏感词
     */
    public static boolean removeWord(String word) {
        return removeWord(word, sensitiveWordMap);
    }

    public static boolean removeWord(String word, Map<Character, SensitiveNode> wordMap) {
        if (StrUtil.isBlank(word) || wordMap == null) {
            return false;
        }
        // 使用递归方法移除敏感词
        return removeWordRecursive(word, 0, wordMap, new ArrayList<>());
    }

    private static boolean removeWordRecursive(String word, int index,
                                               Map<Character, SensitiveNode> currentMap,
                                               List<Map<Character, SensitiveNode>> parentMaps) {
        if (index == word.length()) {
            return false;
        }

        char currentChar = word.charAt(index);
        SensitiveNode currentNode = currentMap.get(currentChar);

        if (currentNode == null) {
            return false;
        }

        parentMaps.add(currentMap);

        if (index == word.length() - 1) {
            if (currentNode.isEnd()) {
                if (!currentNode.hasChildren()) {
                    // 如果没有子节点，直接移除
                    Map<Character, SensitiveNode> parentMap = parentMaps.get(parentMaps.size() - 1);
                    parentMap.remove(currentChar);
                } else {
                    // 如果有子节点，只标记为非结束节点
                    currentNode.setEnd(false);
                }
                log.info("敏感词库已移除/更新：{} 关键词", word);
                return true;
            }
            return false;
        }

        return removeWordRecursive(word, index + 1, currentNode.getChildren(), parentMaps);
    }

    /**
     * 判断文字是否包含敏感字符，默认：使用最小匹配规则
     */
    public static boolean contains(String txt) {
        return contains(txt, MIN_MATCH_TYPE);
    }

    /**
     * 判断文本是否包含敏感词（可指定匹配规则）
     * @param txt 待检测的文本
     * @param matchType 匹配规则：MIN_MATCH_TYPE 或 MAX_MATCH_TYPE
     * @return 如果包含敏感词返回true，否则返回false
     */
    public static boolean contains(String txt, int matchType) {
        if (StrUtil.isBlank(txt) || sensitiveWordMap == null || sensitiveWordMap.isEmpty()) {
            return false;
        }

        // 可选：先过滤特殊字符再检查
        String filteredTxt = filterSpecialStr(txt);
        for (int i = 0; i < filteredTxt.length(); i++) {
            if (checkWord(filteredTxt, i, matchType) > 0) {
                return true;
            }
        }
        return false;
    }

    /**
     * 获取文本中包含的所有敏感词
     */
    public static Set<String> getSensitiveWord(String txt) {
        return getSensitiveWord(txt, MIN_MATCH_TYPE);
    }

    public static Set<String> getSensitiveWord(String txt, int matchType) {
        Set<String> resultSet = new LinkedHashSet<>();

        if (StrUtil.isBlank(txt) || sensitiveWordMap == null || sensitiveWordMap.isEmpty()) {
            return resultSet;
        }

        // 可选：先过滤特殊字符再检测
        String filteredTxt = filterSpecialStr(txt);
        for (int i = 0; i < filteredTxt.length(); i++) {
            int length = checkWord(filteredTxt, i, matchType);
            if (length > 0) {
                resultSet.add(filteredTxt.substring(i, i + length));
                i += length - 1;
            }
        }
        return resultSet;
    }

    /**
     * 替换敏感字字符 - 按单个字符替换
     */
    public static String replaceWordByOne(String txt, String replaceValue) {
        return replaceWord(txt, replaceValue, MAX_MATCH_TYPE, false);
    }

    /**
     * 替换敏感字字符 - 按整个词替换
     */
    public static String replaceWordByAll(String txt, String replaceStr) {
        return replaceWord(txt, replaceStr, MAX_MATCH_TYPE, true);
    }

    /**
     * 替换敏感字字符
     */
    public static String replaceWord(String txt, String replaceValue, int matchType, boolean isReplaceAll) {
        if (StrUtil.isBlank(txt) || sensitiveWordMap == null || sensitiveWordMap.isEmpty()) {
            return txt;
        }

        StringBuilder resultBuilder = new StringBuilder(txt);
        Set<String> sensitiveWords = getSensitiveWord(txt, matchType);

        for (String word : sensitiveWords) {
            String replacement = isReplaceAll ? replaceValue :
                    String.valueOf(replaceValue).repeat(word.length());
            int startIndex;
            while ((startIndex = resultBuilder.indexOf(word)) != -1) {
                resultBuilder.replace(startIndex, startIndex + word.length(), replacement);
            }
        }

        return resultBuilder.toString();
    }

    /**
     * 替换敏感字字符（先过滤特殊字符）
     */
    public static String replaceWordWithFilter(String txt, String replaceValue, int matchType, boolean isReplaceAll) {
        if (StrUtil.isBlank(txt)) {
            return txt;
        }

        // 先过滤特殊字符
        String filteredTxt = filterSpecialStr(txt);
        return replaceWord(filteredTxt, replaceValue, matchType, isReplaceAll);
    }

    /**
     * 校验文字是否包含敏感词
     */
    private static int checkWord(String txt, int beginIndex, int matchType) {
        if (sensitiveWordMap == null) {
            return 0;
        }

        int matchFlag = 0;
        boolean foundEnd = false;
        Map<Character, SensitiveNode> currentMap = sensitiveWordMap;

        for (int i = beginIndex; i < txt.length(); i++) {
            char currentChar = txt.charAt(i);
            SensitiveNode node = currentMap.get(currentChar);

            if (node == null) {
                break;
            }

            matchFlag++;
            if (node.isEnd()) {
                foundEnd = true;
                if (matchType == MIN_MATCH_TYPE) {
                    break;
                }
            }
            currentMap = node.getChildren();
        }

        return foundEnd ? matchFlag : 0;
    }

    /**
     * 过滤特殊字符与空格
     * 修正后的方法，现在在 contains 和 getSensitiveWord 中被使用
     */
    public static String filterSpecialStr(String str) {
        if (StrUtil.isBlank(str)) {
            return str;
        }
        return SPECIAL_CHAR_PATTERN.matcher(str).replaceAll("");
    }

    /**
     * 读取敏感词文件
     */
    public static Set<String> readFile(List<String> filePaths) {
        Set<String> result = new LinkedHashSet<>();

        if (filePaths == null || filePaths.isEmpty()) {
            return result;
        }

        for (String filePath : filePaths) {
            readSingleFile(filePath, result);
        }

        return result;
    }

    private static void readSingleFile(String filePath, Set<String> result) {
        File file = new File(filePath);
        if (!file.exists() || !file.isFile()) {
            log.warn("找不到指定的文件: {}", filePath);
            return;
        }

        int count = 0;
        try (FileInputStream fis = new FileInputStream(file);
             InputStreamReader reader = new InputStreamReader(fis, StandardCharsets.UTF_8);
             BufferedReader bufferedReader = new BufferedReader(reader)) {

            String line;
            while ((line = bufferedReader.readLine()) != null) {
                if (StrUtil.isNotBlank(line)) {
                    String trimmedLine = line.trim();
                    result.add(trimmedLine);
                    count++;
                }
            }

            log.info("加载文件：{}，成功加载 {} 个敏感词", filePath, count);

        } catch (Exception e) {
            log.error("加载敏感词文件出错: {}", filePath, e);
        }
    }

    /**
     * 获取当前敏感词数量（估算）
     */
    public static int getSensitiveWordCount() {
        if (sensitiveWordMap == null) {
            return 0;
        }
        return countWords(sensitiveWordMap);
    }

    private static int countWords(Map<Character, SensitiveNode> nodeMap) {
        int count = 0;
        for (SensitiveNode node : nodeMap.values()) {
            if (node.isEnd()) {
                count++;
            }
            count += countWords(node.getChildren());
        }
        return count;
    }


    /**
     * 测试方法
     */
    public static void main(String[] args) {
        testSensitiveWord();
        System.out.println(JSON.toJSONString(sensitiveWordMap));
    }

    private static void testSensitiveWord() {
        // 加载敏感词库
        Set<String> sensitiveWordSet = new HashSet<>();
        sensitiveWordSet.add("代开发票");
        sensitiveWordSet.add("代购");
        sensitiveWordSet.add("代购商");
        sensitiveWordSet.add("敏感词");

        SensitiveWordUtil.load(sensitiveWordSet);

        String content = "结束标志位结束代购商！标职业志位结束#标$敏感%位结束标志代开$发票位代购结束标志位结束苹果标";

        // 测试过滤特殊字符
        System.out.println("原始文本: " + content);
        System.out.println("过滤后文本: " + filterSpecialStr(content));

        // 检测敏感词
        boolean isContains = contains(content);
        Set<String> sensitiveWords = getSensitiveWord(content);
        System.out.println("文本包含敏感词: " + isContains);
        System.out.println("发现的敏感词: " + sensitiveWords);

        // 替换敏感词
        System.out.println("按字符替换: " + replaceWordByOne(content, "*"));
        System.out.println("按词替换: " + replaceWordByAll(content, "***"));

        // 测试带过滤的替换
        System.out.println("带过滤的替换: " + replaceWordWithFilter(content, "*", MAX_MATCH_TYPE, false));

        System.out.println("当前敏感词数量: " + getSensitiveWordCount());
    }
}
```



- 子节点新建一个内部类`SensitiveNode`，新增特殊符号过滤后，再匹配



### 四、总结

在日常开发中，敏感词过滤是一个常见的需求。无论是社交平台、论坛还是电商系统，都需要对用户输入的内容进行敏感词检测。

DFA算法通过树形结构和状态转移的理念，将敏感词过滤的时间复杂度大幅降低，特别适合处理大规模敏感词库的场景。


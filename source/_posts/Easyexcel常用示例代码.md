---
title: Easyexcel常用示例代码
date: 2021-05-28 18:19:04
updated: 2021-05-28 18:19:04
tags: [easyexcel]
categories: Java
---

### 前言
+ 记录阿里的`easyexcel`工具的相关使用:
+ 导入、导出、下拉、级联下拉

### 一、快速开始

#### 1、导入依赖
+ 导入pom

```
<dependency>
	<groupId>com.alibaba</groupId>
	<artifactId>easyexcel</artifactId>
	<version>2.2.6</version>
</dependency>
```
+ 通过pom依赖，我们知道它是基于poi再次封装的。

<!--more-->

#### 2、开始使用
+ `easyexcel`封装了一个工厂类：`EasyExcelFactory`，我们直接调用即可。
+ 一般在项目中会用到：`EasyExcel`它其实就是`EasyExcelFactory`的子类且没有自己的功能。

#### 3、写Excel
+ EasyExcel 封装了很多方法，可以自己点进去看
+ 导出模板

```
public class Demo {
    public static void main(String[] args) {
        EasyExcel.write("D:/demo.xlsx", ExcelDataDto.class).sheet("模板").doWrite(data());
    }

    public static List<ExcelDataDto> data(){
        List<ExcelDataDto> list = new ArrayList<>();
        for (int i = 0; i < 10; i++) {
            ExcelDataDto data = new ExcelDataDto();
            data.setString("字符串" + i);
            data.setDate(new Date());
            data.setDoubleData(0.56);
            list.add(data);
        }
        return list;
    }
}

@Data
public class ExcelDataDto {
	// @ExcelProperty 是excel的标题名称注解
    @ExcelProperty("字符串标题")
    private String string;
    @ExcelProperty("日期标题")
    private Date date;
    @ExcelProperty("数字标题")
    private Double doubleData;
}

@Slf4j
public class ExcelDataListener extends AnalysisEventListener<ExcelDataDto> {

    public ExcelDataListener(){}

//    private Service todoService;
//    public ExcelDataListener(Service todoService){
//        this.todoService = todoService;
//    }

    @Override
    public void invoke(ExcelDataDto excelDataDto, AnalysisContext analysisContext) {
        log.info("解析到一条数据:{}", JSON.toJSONString(excelDataDto));
        // todo 保存数据库
        // todoService.save();
    }

    @Override
    public void doAfterAllAnalysed(AnalysisContext analysisContext) {
        log.info("所有数据解析完成！");
    }
}
```

#### 4、读Excel
+ 读取excel

```java

public class Demo {
    public static void main(String[] args) {
		// 这里读取D盘下的dmeo.xlsx 文件
       // 这里 需要指定读用哪个class去读，然后读取第一个sheet 文件流会自动关闭
		EasyExcel.read("D://demo.xlsx", ExcelDataDto.class, new ExcelDataListener()).sheet().doRead();
    }
}
```

### 二、上传下载
+ 上次下载，需要用到servlet,这边直接使用springboot
+ dmeo如下：

```
@Controller
@RequestMapping("/test")
public class WebTestController {

    /**
     * 文件上传
     */
    @PostMapping("/upload")
    @ResponseBody
    public String upload(MultipartFile file) throws IOException {
        EasyExcel.read(file.getInputStream(), ExcelDataDto.class, new ExcelDataListener()).sheet().doRead();
        return "success";
    }

    /**
     * 文件下载（失败了会返回一个有部分数据的Excel）
     */
    @GetMapping("download")
    public void download(HttpServletResponse response) throws IOException {
        // 这里注意 有同学反应使用swagger 会导致各种问题，请直接用浏览器或者用postman
        response.setContentType("application/vnd.ms-excel");
        response.setCharacterEncoding("utf-8");
        // 这里URLEncoder.encode可以防止中文乱码 当然和easyexcel没有关系
        String fileName = URLEncoder.encode("测试", "UTF-8").replaceAll("\\+", "%20");
        response.setHeader("Content-disposition", "attachment;filename*=utf-8''" + fileName + ".xlsx");
        EasyExcel.write(response.getOutputStream(), ExcelDataDto.class).sheet("模板").doWrite(new ArrayList());
    }
}
```

### 三、图片导出
+ 为啥只有导出呢，因为目前(`  (ง •_•)ง 2021-05-28 `) easyexcel暂不支持图片的导入。

```
@Controller
@RequestMapping("/images")
public class ImagesController {

    /**
     * 导出图片类型
     * @param response
     * @throws Exception
     */
    @GetMapping("/export")
    public void export(HttpServletResponse response) throws Exception {
        ClassPathResource classPathResource = new ClassPathResource("images/avatar.jpg");
        InputStream inputStream =classPathResource.getInputStream();
//        InputStream resourceAsStream = this.getClass().getResourceAsStream("/images/avatar.jpg");

        String fileName = URLEncoder.encode("图片excel", "UTF-8").replaceAll("\\+", "%20");
        try {
            List<ImageDto> list = new ArrayList<ImageDto>();
            ImageDto imageDto = new ImageDto();
            list.add(imageDto);
            File file = ResourceUtils.getFile("classpath:images/avatar.jpg");
            // 放入五种类型的图片 实际使用只要选一种即可
            imageDto.setByteArray(FileUtils.readFileToByteArray(file));
            imageDto.setFile(file);
            imageDto.setString(file.getAbsolutePath());
            imageDto.setInputStream(inputStream);
            imageDto.setUrl(new URL("http://portrait.gitee.com/uploads/avatars/user/286/858520_rstyro_1578934054.png!avatar30"));

            response.setContentType("application/vnd.ms-excel");
            response.setCharacterEncoding("utf-8");
            response.setHeader("Content-disposition", "attachment;filename*=utf-8''" + fileName + ".xlsx");
            EasyExcel.write(response.getOutputStream(), ImageDto.class).sheet().doWrite(list);
        } finally {
            if (inputStream != null) {
                inputStream.close();
            }
        }
    }

}
```

### 四、自定义格式转换
+ 格式转换，一般用的最多的就是时间格式
+ 时间类型一般有：Date 和 LocalDateTime
+ 如果使用的是Date可以用注解格式化，如果使用LocalDateTime需要自己写转换器

```
/**
 * ColumnWidth 定义列宽
 */
/**
 * ColumnWidth 定义列宽
 */
@ColumnWidth(25)
@Data
@Accessors(chain = true)
public class UserDto {

    @ExcelProperty("用户名称")
    private String username;

    @ExcelProperty("年龄")
    private Integer age;

    @ExcelProperty("部门")
    @DropDownFields(source = {"财务部","人事部","研发部","商务部"})
    private String department;

    @ExcelProperty("职业")
    private String occupation;

    /**
     * 自定义日期转换器 LocalDateTimeConverter
     */
    @ColumnWidth(50)
    @ExcelProperty(value = "注册时间",converter = LocalDateTimeConverter.class)
    private LocalDateTime createTime;

    /**
     * 使用注解 @DateTimeFormat
     */
    @ExcelProperty(value = "发财时间")
    @DateTimeFormat("yyyy-MM-dd HH:mm:ss")
    @ColumnWidth(50)
    private Date startTime;
}



/**
 * 自定义 LocalDateTime 日期转换器
 */
public class LocalDateTimeConverter implements Converter<LocalDateTime> {

    @Override
    public Class<LocalDateTime> supportJavaTypeKey() {
        return LocalDateTime.class;
    }

    @Override
    public CellDataTypeEnum supportExcelTypeKey() {
        return CellDataTypeEnum.STRING;
    }

    @Override
    public LocalDateTime convertToJavaData(CellData cellData, ExcelContentProperty contentProperty,
                                           GlobalConfiguration globalConfiguration) {
        return LocalDateTime.parse(cellData.getStringValue(), DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
    }

    @Override
    public CellData<String> convertToExcelData(LocalDateTime value, ExcelContentProperty contentProperty,
                                               GlobalConfiguration globalConfiguration) {
        return new CellData<>(value.format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")));
    }

}
```

+ 如果是其他需要用到转换，只需实现`Converter<T>` 接口即可。
+ `convertToJavaData()` 这个方法是从Excel转到Java类型，反之`convertToExcelData()`是Java到Excel。
+ 自定义转换器，只需重写上面两个方法即可。


### 五、实现下拉框
+ 实现动态下拉框导入功能
+ 为了方便复用，这边使用自定义注解的方式

#### 1、自定义注解
+ 我们自定义一个放在字段上的注解

```
@Documented
@Target(ElementType.FIELD)
@Retention(RetentionPolicy.RUNTIME)
public @interface DropDownFields {
    /**
     * 固定下拉
     * @return
     */
    String[] source() default {};

    /**
     * 动态下拉内容，可查数据库返回等，其他操作
     * @return
     */
    Class[] sourceClass() default {};

    /**
     * 下拉类型枚举，可能动态查询的时候需要用到
     * @return
     */
    DropDownType type() default DropDownType.NONE;

}
```

#### 2、自定义Handler
+ 自定义一个Handler,给Excel设置下拉框数据约束

```
/**
 * excel 下拉框 handler
 */
public class DropDownWriteHandler implements SheetWriteHandler {

    private final Map<Integer, String[]> map;

    /**
     * 设置阈值，避免生成的导入模板下拉值获取不到
     */
    private static final Integer LIMIT_NUMBER = 100;

    public DropDownWriteHandler(Map<Integer, String[]> map) {
        this.map = map;
    }

    @Override
    public void beforeSheetCreate(WriteWorkbookHolder writeWorkbookHolder, WriteSheetHolder writeSheetHolder) {

    }

    @Override
    public void afterSheetCreate(WriteWorkbookHolder writeWorkbookHolder, WriteSheetHolder writeSheetHolder) {

        // 这里可以对cell进行任何操作
        Sheet sheet = writeSheetHolder.getSheet();
        DataValidationHelper helper = sheet.getDataValidationHelper();

        // k 为存在下拉数据集的单元格下标 v为下拉数据集
        map.forEach((k, v) -> {
            // 设置下拉单元格的首行 末行 首列 末列
            CellRangeAddressList rangeList = new CellRangeAddressList(1, 65536, k, k);
            // 如果下拉值总数大于100，则使用一个新sheet存储，避免生成的导入模板下拉值获取不到
            if (v.length > LIMIT_NUMBER) {
                //定义sheet的名称
                //1.创建一个隐藏的sheet 名称为 hidden + k
                String sheetName = "hidden" + k;
                Workbook workbook = writeWorkbookHolder.getWorkbook();
                Sheet hiddenSheet = workbook.createSheet(sheetName);
                for (int i = 0, length = v.length; i < length; i++) {
                    // 开始的行数i，列数k
                    hiddenSheet.createRow(i).createCell(k).setCellValue(v[i]);
                }
                Name category1Name = workbook.createName();
                category1Name.setNameName(sheetName);
                String excelLine = EasyExcelUtils.getColNum(k);
                // =hidden!$H:$1:$H$50 sheet为hidden的 H1列开始H50行数据获取下拉数组
                String refers = "=" + sheetName + "!$" + excelLine + "$1:$" + excelLine + "$" + (v.length + 1);
                // 将刚才设置的sheet引用到你的下拉列表中
                DataValidationConstraint constraint = helper.createFormulaListConstraint(refers);
                DataValidation dataValidation = helper.createValidation(constraint, rangeList);
                writeSheetHolder.getSheet().addValidationData(dataValidation);
                // 设置存储下拉列值得sheet为隐藏
                int hiddenIndex = workbook.getSheetIndex(sheetName);
                if (!workbook.isSheetHidden(hiddenIndex)) {
                    workbook.setSheetHidden(hiddenIndex, true);
                }
            }
            // v 就是下拉列表的具体数据，下拉列表约束数据
            DataValidationConstraint constraint = helper.createExplicitListConstraint(v);
            // 设置下拉约束
            DataValidation validation = helper.createValidation(constraint, rangeList);
            // 阻止输入非下拉选项的值
            validation.setErrorStyle(DataValidation.ErrorStyle.STOP);
            validation.setShowErrorBox(true);
            validation.setSuppressDropDownArrow(true);
            validation.createErrorBox("提示", "此值与单元格定义格式不一致");
            sheet.addValidationData(validation);
        });
    }

}
```

#### 3、导出的实体类
+ 固定下拉使用：`source`，动态下拉使用：`sourceClass`

```
@Data
// 内容行高度
@ContentRowHeight(20)
// 头部行高度
@HeadRowHeight(25)
// 列宽，可在类或属性中使用
@ColumnWidth(25)
public class UserTemplate {

    @ExcelProperty("用户名称")
    private String username;

    @ExcelProperty("年龄")
    private Integer age;

    /**
     * 固定下拉
     */
    @ExcelProperty("部门")
    @DropDownFields(source = {"财务部","人事部","研发部","商务部"})
    private String department;

    /**
     * 动态下拉
     */
    @ExcelProperty("职业")
    @DropDownFields(sourceClass = OccupationDropDownService.class,type = DropDownType.OCCUPATION)
    private String occupation;

    @ColumnWidth(50)
    @ExcelProperty(value = "注册时间",converter = LocalDateTimeConverter.class)
    private LocalDateTime createTime=LocalDateTime.now();
}
```

#### 4、动态下拉实现类
+ 只需要实现`getSource()`方法，返回下拉的集合即可
+ 这边模拟了下数据库查询，因为这里不能直接使用注解自动注入
+ 所有通过上下文工具类获取示例。

```
/**
 * 职业的下拉 实现类
 */
public class OccupationDropDownService implements IDropDownService{

    @Override
    public String[] getSource(String typeValue) {
        // 没法用 @Autowired 注入，所以用ApplicationContext
        IDictValueService dictValueService = ApplicationContextUtils.getBean(IDictValueService.class);
        List<DictValue> list = dictValueService.list(new LambdaQueryWrapper<DictValue>().eq(DictValue::getType, typeValue));
        if(ObjectUtils.isEmpty(list)){
            return null;
        }
        Set<String> collect = list.stream().map(DictValue::getValue).collect(Collectors.toSet());
        return collect.toArray(new String[collect.size()]);
    }
}
```

#### 5、导出模板
+ 这边演示导出到浏览器
+ 因为很多内容可以复用，随意封装了下工具类：`EasyExcelUtils`

**EasyExcelUtils**

```
/**
 * easyExcel 工具类
 * @author rstyro
 */
@Slf4j
public class EasyExcelUtils {

    /**
     * 浏览器导出excel文件
     * 官网文档地址：https://www.yuque.com/easyexcel/doc/easyexcel
     * @param data 数据
     * @param templateClass 模板对象class
     * @param pageSize 每页多少条
     * @param fileName 文件名称
     * @param response 输出流
     * @throws Exception err
     */
    public static void exportBrowser(List data, Class templateClass, Integer pageSize, String fileName, HttpServletResponse response) throws Exception {
        pageSize = Optional.ofNullable(pageSize).orElse(50000);
        fileName = fileName + System.currentTimeMillis();
        // 这里URLEncoder.encode可以防止中文乱码 当然和easyexcel没有关系
        fileName = URLEncoder.encode(fileName, "UTF-8").replaceAll("\\+", "%20");
        response.setContentType("application/vnd.ms-excel");
        response.setCharacterEncoding("utf-8");
        response.setHeader("Content-disposition", "attachment;filename*=utf-8''" + fileName + ".xlsx");

        // 获取改类声明的所有字段
        Field[] fields = templateClass.getDeclaredFields();
        // 响应字段对应的下拉集合
        Map<Integer, String[]> map = processDropDown(fields);
		// 解析级联下拉字段
        Map<Integer, ChainDropDown> integerChainDropDownMap = processChainDropDown(fields);
        ExcelWriter excelWriter = null;
        OutputStream out = null;
        try {
            out = response.getOutputStream();
            excelWriter = EasyExcel.write(out, templateClass).registerWriteHandler(new DropDownWriteHandler(map))
                    .registerWriteHandler(new ChainDropDownWriteHandler(integerChainDropDownMap)).build();
            // 分页写入
            pageWrite(excelWriter,data,pageSize);
        } catch (Throwable e) {
            response.setHeader("Content-Disposition", "attachment;filename=下载失败");
            e.printStackTrace();
            log.error("文档下载失败:" + e.getMessage());
        } finally {
            data.clear();
            if (excelWriter != null) {
                excelWriter.finish();
            }
            assert out != null;
            out.flush();
            out.close();
        }
    }

    /**
     * 分页写入
     * @param writer ExcelWriter
     * @param data 数据
     * @param pageSize 分页大小
     */
    public static void pageWrite(ExcelWriter writer,List<Object> data,Integer pageSize){
        List<List<Object>> lt = Lists.partition(data, pageSize);
        for (int i = 0; i < lt.size(); i++) {
            int j = i + 1;
            WriteSheet writeSheet = EasyExcel.writerSheet(i, "第" + j + "页").build();
            writer.write(lt.get(i), writeSheet);
        }
    }


    /**
     * 读取excel 并解析
     * @param file 文件
     * @param clazz 解析成哪个dto
     * @param <T> t
     * @return list
     * @throws IOException error
     */
    public static <T> List<T> read(MultipartFile file,Class<T> clazz) throws IOException {
        BaseExcelDataListener<T> baseExcelDataListener = new BaseExcelDataListener();
        EasyExcel.read(file.getInputStream(), clazz, baseExcelDataListener).sheet().doRead();
        return baseExcelDataListener.getResult();
    }

    /**
     * 处理有下拉框注解的属性
     * @param fields 字段属性集合
     * @return map
     */
    public static Map<Integer, String[]> processDropDown(Field[] fields){
        // 响应字段对应的下拉集合
        Map<Integer, String[]> map = new HashMap<>();
        Field field = null;
        // 循环判断哪些字段有下拉数据集，并获取
        for (int i = 0; i < fields.length; i++) {
            field = fields[i];
            // 解析注解信息
            DropDownFields dropDownField = field.getAnnotation(DropDownFields.class);
            if (null != dropDownField) {
                String[] sources = ResolveAnnotation.resolve(dropDownField);
                if (null != sources && sources.length > 0) {
                    map.put(i, sources);
                }
            }
        }
        return map;
    }

    public static Map<Integer, ChainDropDown> processChainDropDown(Field[] fields){
        // 响应字段对应的下拉集合
        Map<Integer, ChainDropDown> map = new HashMap<>();
        Field field = null;
        int rowIndex=0;
        // 循环判断哪些字段有下拉数据集，并获取
        for (int i = 0; i < fields.length; i++) {
            field = fields[i];
            // 解析注解信息
            ChainDropDownFields chainDropDownFields = field.getAnnotation(ChainDropDownFields.class);
            if (null != chainDropDownFields) {
//                List<ChainDropDown> sources = ResolveAnnotation.resolve(chainDropDownFields);
                ChainDropDown resolve = ResolveAnnotation.resolve(chainDropDownFields);
                long collect = resolve.getDataMap().keySet().size();
                System.out.println("collect="+collect);
                if(resolve.isRootFlag()){
                    resolve.setRowIndex(rowIndex);
                    rowIndex+=1;
                }else {
                    resolve.setRowIndex(rowIndex);
                    rowIndex+=collect;
                }
                if (!ObjectUtils.isEmpty(resolve)) {
                    map.put(i, resolve);
                }
            }
        }
        return map;
    }

    /**
     * 获取Excel列的号码A-Z - AA-ZZ - AAA-ZZZ 。。。。
     * @param num
     * @return
     */
    public static String getColNum(int num) {
        int MAX_NUM = 26;
        char initChar = 'A';
        if(num == 0){
            return initChar+"";
        }else if(num > 0 && num < MAX_NUM){
            int result = num % MAX_NUM;
            return (char) (initChar + result) + "";
        }else if(num >= MAX_NUM){
            int result = num / MAX_NUM;
            int mod = num % MAX_NUM;
            String starNum = getColNum(result-1);
            String endNum = getColNum(mod);
            return starNum+endNum;
        }
        return "";
    }
}
```

+ 导出浏览器，主要看：`exportBrowser()`方法即可 
+ SpringBoot请求接口如下：

```
@Controller
@RequestMapping("/dropDown")
public class DropDownController {

    @Autowired
    private IUserService userService;

    /**
     * 下载下拉模板
     * @param response
     * @throws Exception
     */
    @GetMapping("/downloadTemplate")
    public void downloadTemplate(HttpServletResponse response) throws Exception {
        List<UserTemplate> export = new ArrayList<>(Arrays.asList(new UserTemplate()));
        EasyExcelUtils.exportBrowser(export, UserTemplate.class, export.size(), "模板", response);
    }
	
}
```

### 六、级联下拉框
+ 能导出下拉框，是不是也能做成级联下拉框呢
+ 答案是肯定的。但是就是比下拉框麻烦一点点
+ 因为不只要设置数据有效性，还有设置名称管理器，和级联有效性等。
+ 我们也定义一个自定义注解：`ChainDropDownFields`

#### 1、自定义注解
```
/**
 * excel的级联下拉框注解
 */
@Documented
@Target(ElementType.FIELD)
@Retention(RetentionPolicy.RUNTIME)
public @interface ChainDropDownFields {

    /**
     * 动态下拉内容，可查数据库返回等，其他操作
     * @return class[]
     */
    Class[] sourceClass() default {};

    /**
     * 是不是第一级下拉
     * @return
     */
    boolean isRoot() default false;

    /**
     * 获取下拉的参数,可以有1个到多个
     * @return string
     */
    String[] params() default {};

    /**
     * 级联下拉类型
     * @return type
     */
    ChainDropDownType type() default ChainDropDownType.NONE;

}
```

+ 上面字段都有注释解析

#### 2、定义实体类
+ 定义一个实体类，下拉和级联下拉，复合使用

```
@Data
// 内容行高度
@ContentRowHeight(20)
// 头部行高度
@HeadRowHeight(25)
// 列宽，可在类或属性中使用
@ColumnWidth(25)
@Data
// 内容行高度
@ContentRowHeight(20)
// 头部行高度
@HeadRowHeight(25)
// 列宽，可在类或属性中使用
@ColumnWidth(25)
public class ChainTestTemplate {

    @ExcelProperty("用户名称")
    private String name;

    @ExcelProperty("年龄")
    private Integer age;


    @ExcelProperty("国家")
    @ChainDropDownFields(isRoot = true,sourceClass = TestChainDropDownService.class,type = ChainDropDownType.TEST)
    private String country;

    @ExcelProperty("省份")
    @ChainDropDownFields(sourceClass = TestChainDropDownService.class,type = ChainDropDownType.TEST,params = {"2"})
    private String province;

    @ExcelProperty("城市")
    @ChainDropDownFields(sourceClass = TestChainDropDownService.class,type = ChainDropDownType.TEST,params = {"3"})
    private String city;

    @ExcelProperty("区域")
    @ChainDropDownFields(sourceClass = TestChainDropDownService.class,type = ChainDropDownType.TEST,params = {"4"})
    private String zone;
}
```

+ 上面可以看到有：国家 省 市 区 4个级联下拉，可以一直级联...

#### 3、定义注解实现类
+ 内容如下

```
/**
 * 区域级联下拉 实现类
 */
public class TestChainDropDownService implements IChainDropDownService{

    /**
     * 第一层，key=root,value=可选数组
     */
    @Override
    public List<String> getRoot(String... params){
        return Arrays.asList(new String[]{"中国", "美国"});
    }

    /**
     * 获取子类的Map
     */
    @Override
    public Map<String,List<String>> getParentBindSubMap(String... params){
        int level = Integer.parseInt(params[0]);
        // key 是父级，value 是父级的子类
        Map<String,List<String>> dataMap = new HashMap<>();
        if(level==2){
            dataMap.put("中国",Arrays.asList(new String[]{"北京2", "广东2"}));
            dataMap.put("美国",Arrays.asList(new String[]{"阿拉斯加州", "阿拉巴马州"}));
        }else if(level == 3){
            dataMap.put("北京2",Arrays.asList(new String[]{"北京市2"}));
            dataMap.put("广东2",Arrays.asList(new String[]{"广州2","深圳2"}));
            dataMap.put("阿拉斯加州",Arrays.asList(new String[]{"阿拉斯加","雅库塔特"}));
            dataMap.put("阿拉巴马州",Arrays.asList(new String[]{"马伦戈县"}));
        }else if(level == 4){
            dataMap.put("北京市2",Arrays.asList(new String[]{"朝阳区2","密云区2"}));
            dataMap.put("广州2",Arrays.asList(new String[]{"天河区2","白云区2"}));
            dataMap.put("深圳2",Arrays.asList(new String[]{"福田区2","南山区2"}));
            dataMap.put("阿拉斯加",Arrays.asList(new String[]{"瞎编区","编不下去了"}));
            dataMap.put("雅库塔特",Arrays.asList(new String[]{"瞎编区","编不下去了"}));
            dataMap.put("马伦戈县",Arrays.asList(new String[]{"马勒戈壁"}));
        }
        return dataMap;
    }
}
```

+ 这里的`getRoot()` 返回的是第一层下拉，因为没有父级，所以直接返回一个集合下拉列表即可。
+ `getParentBindSubMap()`这里返回的是第二级及之后的下拉列表，是一个Map,key是上一级的所有值，value是key的子集。
+ 我也不知道还有没有好一点的方法来搞这个级联下拉。

#### 4、级联下拉Handler
+ 这个才是重点,有些重要的地方都写了注释

```
/**
 * excel 级联下拉框 handler
 */
public class ChainDropDownWriteHandler implements SheetWriteHandler {

    private final Map<Integer, ChainDropDown> map;

    public ChainDropDownWriteHandler(Map<Integer, ChainDropDown> map) {
        this.map = map;
    }

    @Override
    public void beforeSheetCreate(WriteWorkbookHolder writeWorkbookHolder, WriteSheetHolder writeSheetHolder) {

    }

    @Override
    public void afterSheetCreate(WriteWorkbookHolder writeWorkbookHolder, WriteSheetHolder writeSheetHolder) {
        // 这里可以对cell进行任何操作
        Sheet sheet = writeSheetHolder.getSheet();
        DataValidationHelper helper = sheet.getDataValidationHelper();
        Workbook workbook = writeWorkbookHolder.getWorkbook();
        for(Map.Entry<Integer, ChainDropDown> e:map.entrySet()){
            // k 为存在下拉数据集的单元格下表 v为下拉数据集
            Integer k = e.getKey();
            ChainDropDown v = e.getValue();
            CellRangeAddressList rangeList = new CellRangeAddressList(1, 65536, k, k);
            Sheet hideSheet = getSheet(workbook, v.getTypeName());
            if(v.isRootFlag()){
                Row firstRow = hideSheet.createRow(v.getRowIndex());
                List<String> values = v.getDataMap().get(ChainDropDown.ROOT_KEY);
                for(int i = 0; i < values.size(); i ++){
                    Cell rowCell = firstRow.createCell(i);
                    rowCell.setCellValue(values.get(i));
                }

                // v 就是下拉列表的具体数据，下拉列表约束数据
                DataValidationConstraint constraint = helper.createExplicitListConstraint(values.toArray(new String[values.size()]));
                // 设置下拉约束
                DataValidation validation = helper.createValidation(constraint, rangeList);
                // 阻止输入非下拉选项的值
                validation.setErrorStyle(DataValidation.ErrorStyle.STOP);
                validation.setShowErrorBox(true);
                validation.setSuppressDropDownArrow(true);
                validation.createErrorBox("提示", "此值与单元格定义格式不一致");
                sheet.addValidationData(validation);

            }else {
                Integer rowIndex = v.getRowIndex();
                Map<String, List<String>> dataMap = v.getDataMap();

                for(Map.Entry<String, List<String>> entry:dataMap.entrySet()){
                    String parentValue = entry.getKey();
                    List<String> childValues = entry.getValue();
                    Row row = hideSheet.createRow(rowIndex++);
                    row.createCell(0).setCellValue(parentValue);
                    for(int j = 0; j < childValues.size(); j ++){
                        Cell cell = row.createCell(j + 1);
                        cell.setCellValue(childValues.get(j));
                    }
                    // 添加名称管理器
                    String range = getRange(1, rowIndex, childValues.size());
                    Name name = workbook.createName();
                    //key不可重复
                    name.setNameName(parentValue);
                    String formula = v.getTypeName()+"!" + range;
                    name.setRefersToFormula(formula);
                }

            }
            // 从第二行开始，第一行是标题
            int beginRow = 2;
            // 设置级联有效性
            String listFormula = "INDIRECT($" +  EasyExcelUtils.getColNum(k-1) + beginRow + ")";
            DataValidationConstraint formulaListConstraint = helper.createFormulaListConstraint(listFormula);
            // 设置下拉约束
            DataValidation validation =   helper.createValidation(formulaListConstraint, rangeList);
            validation.setEmptyCellAllowed(false);
            validation.setSuppressDropDownArrow(true);
            validation.setShowErrorBox(true);
            // 设置输入信息提示信息
            validation.createPromptBox("下拉选择提示", "请使用下拉方式选择合适的值！");
            sheet.addValidationData(validation);
        }
    }

    public Sheet getSheet(Workbook workbook,String sheetName){
        Sheet sheet = workbook.getSheet(sheetName);
        if(!ObjectUtils.isEmpty(sheet)) {
            return sheet;
        }
        return workbook.createSheet(sheetName);
    }

    /**
     *  计算formula
     * @param offset 偏移量，如果给0，表示从A列开始，1，就是从B列
     * @param rowNum 第几行
     * @param colCount 一共多少列
     * @return 如果给入参 1,1,10. 表示从B1-K1。最终返回 $B$1:$K$1
     *
     */
    public static String getRange(int offset, int rowNum, int colCount) {
        String start = EasyExcelUtils.getColNum(offset);
        String end = EasyExcelUtils.getColNum(colCount);
        String format= "$%s$%s:$%s$%s";
        return String.format(format, start,rowNum,end,rowNum);
    }

}
```
+ 这里其实复杂的就是设置名称管理器和它的级联关联有效性，我不知道还没有更好的方法。

#### 5、导出级联下拉模板
+ 也是使用springboot

```
@Controller
@RequestMapping("/chainDropDown")
public class ChainDropDownController {

    @GetMapping("/downloadTemplate")
    public void downloadTemplate2(HttpServletResponse response) throws Exception {
        List<ChainTestTemplate> export = new ArrayList<>(Arrays.asList(new ChainTestTemplate()));
        EasyExcelUtils.exportBrowser(export, ChainTestTemplate.class, export.size(), "测试级联模板", response);
    }
	
}
```

#### 6、本文完整代码
+ **Github:** [https://github.com/rstyro/easyexcel-demo](https://github.com/rstyro/easyexcel-demo)
+ **Gitee:** [https://gitee.com/rstyro/easyexcel-demo](https://gitee.com/rstyro/easyexcel-demo)

---
title: Springboot druid连接池数据库密码加密
date: 2017-11-01 10:10:55
tags: [Spring Boot]
categories: Java
---
# Springboot druid连接池数据库密码加密
突然发现，好久好久没有更新文章了，哎，最近好多事情要做。不说了，都是泪
## 一、导入依赖
```
<dependency>
	<groupId>com.github.ulisesbocchio</groupId>
	<artifactId>jasypt-spring-boot-starter</artifactId>
	<version>1.8</version>
</dependency>
```
## 二、加解密工具类
```java
import org.jasypt.encryption.pbe.StandardPBEStringEncryptor;
import org.jasypt.encryption.pbe.config.EnvironmentStringPBEConfig;

public class DBEncryptUtil {
	public static void main(String[] args) {
		String plaintext="lrshuai.top";
		String ciphertext="";
		ciphertext = encrypt(plaintext);
		System.out.println("ciphertext="+ciphertext);
		plaintext = decrypt(ciphertext);
		System.out.println("plaintext="+plaintext);
		
	}
	
	/**
	 * 加密，每次生成的密码都是不一样的，但是解密后的字符串是一样的
	 * @param plaintext 明文字符串
	 * @return
	 */
	public static String encrypt(String plaintext) {
	    // 创建加密器
	    StandardPBEStringEncryptor encryptor = new StandardPBEStringEncryptor();
	    // 配置
	    EnvironmentStringPBEConfig config = new EnvironmentStringPBEConfig();
	    config.setAlgorithm("PBEWithMD5AndDES");// 加密算法
	    config.setPassword("rstyro");// 系统属性值
	    encryptor.setConfig(config);
	    String ciphertext = encryptor.encrypt(plaintext); // 加密
	    return ciphertext;
	}
	
	/**
	 * 解密
	 * @param ciphertext 加密后的字符串
	 * @return
	 */
	public static String decrypt(String ciphertext) {
	    StandardPBEStringEncryptor encryptor = new StandardPBEStringEncryptor();
	    EnvironmentStringPBEConfig config = new EnvironmentStringPBEConfig();
	        config.setAlgorithm("PBEWithMD5AndDES");
	    config.setPassword("rstyro");
	    encryptor.setConfig(config);
	    //解密
	    String plaintext = encryptor.decrypt(ciphertext); // 解密
	    return plaintext;
	}
}
```

## 三、把加密后的字符串放在配置文件中
application.properties中的部分 配置
```
spring.datasource.driverClassName = com.mysql.jdbc.Driver
spring.datasource.url = jdbc:mysql://localhost:3306/demo?useUnicode=true&characterEncoding=utf-8&useSSL=false

# 下面就是加密后的密码，
# spring.datasource.username = root
# spring.datasource.password = lrshuai.top
spring.datasource.username = CdqQH9BDIQnKMdMjF+1bZg==
spring.datasource.password = 14tCBS6t6VuhVED5rGuoifNdEddlN6be


# druid pool config
spring.datasource.type = com.alibaba.druid.pool.DruidDataSource
#druid config 
spring.datasource.initialSize=5  
spring.datasource.minIdle=5  
spring.datasource.maxActive=20  
spring.datasource.maxWait=60000  
spring.datasource.timeBetweenEvictionRunsMillis=60000  
spring.datasource.minEvictableIdleTimeMillis=300000  
spring.datasource.validationQuery=SELECT 1 FROM DUAL  
spring.datasource.testWhileIdle=true  
spring.datasource.testOnBorrow=false  
spring.datasource.testOnReturn=false  
spring.datasource.poolPreparedStatements=true  
spring.datasource.maxPoolPreparedStatementPerConnectionSize=20  
spring.datasource.filters=stat,wall,log4j  
spring.datasource.connectionProperties=druid.stat.mergeSql=true;druid.stat.slowSqlMillis=5000
```

## 四、修改配置阿里连接池的配置文件
```java
@ConfigurationProperties(prefix = "spring.druid.datasource")
@Configuration
public class DruidDBConfig {  
    private Logger logger = Logger.getLogger(this.getClass());
      
    @Value("${spring.datasource.url}")  
    private String dbUrl;  
      
    @Value("${spring.datasource.username}")  
    private String username;  
      
    @Value("${spring.datasource.password}")  
    private String password;  
      
    @Value("${spring.datasource.driverClassName}")  
    private String driverClassName;  
      
    @Value("${spring.datasource.initialSize}")  
    private int initialSize;  
      
    @Value("${spring.datasource.minIdle}")  
    private int minIdle;  
      
    @Value("${spring.datasource.maxActive}")  
    private int maxActive;  
      
    @Value("${spring.datasource.maxWait}")  
    private long maxWait;  
      
    @Value("${spring.datasource.timeBetweenEvictionRunsMillis}")  
    private int timeBetweenEvictionRunsMillis;  
      
    @Value("${spring.datasource.minEvictableIdleTimeMillis}")  
    private int minEvictableIdleTimeMillis;  
      
    @Value("${spring.datasource.validationQuery}")  
    private String validationQuery;  
      
    @Value("${spring.datasource.testWhileIdle}")  
    private boolean testWhileIdle;  
      
    @Value("${spring.datasource.testOnBorrow}")  
    private boolean testOnBorrow;  
      
    @Value("${spring.datasource.testOnReturn}")  
    private boolean testOnReturn;  
      
    @Value("${spring.datasource.poolPreparedStatements}")  
    private boolean poolPreparedStatements;  
      
    @Value("${spring.datasource.maxPoolPreparedStatementPerConnectionSize}")  
    private int maxPoolPreparedStatementPerConnectionSize;  
      
    @Value("${spring.datasource.filters}")  
    private String filters;  
      
    @Value("{spring.datasource.connectionProperties}")  
    private String connectionProperties;  
      
    @Bean     //声明其为Bean实例  
    @Primary  //在同样的DataSource中，首先使用被标注的DataSource  
    public DataSource dataSource(){  
        DruidDataSource datasource = new DruidDataSource();  
        datasource.setUrl(this.dbUrl); 
		//就是这里了，解个密就行了
        username = DBEncryptUtil.decrypt(username);
        password = DBEncryptUtil.decrypt(password);
        datasource.setUsername(username);  
        datasource.setPassword(password);  
        datasource.setDriverClassName(driverClassName);  
          
        //configuration  
        datasource.setInitialSize(initialSize);  
        datasource.setMinIdle(minIdle);  
        datasource.setMaxActive(maxActive);  
        datasource.setMaxWait(maxWait);  
        datasource.setTimeBetweenEvictionRunsMillis(timeBetweenEvictionRunsMillis);  
        datasource.setMinEvictableIdleTimeMillis(minEvictableIdleTimeMillis);  
        datasource.setValidationQuery(validationQuery);  
        datasource.setTestWhileIdle(testWhileIdle);  
        datasource.setTestOnBorrow(testOnBorrow);  
        datasource.setTestOnReturn(testOnReturn);  
        datasource.setPoolPreparedStatements(poolPreparedStatements);  
        datasource.setMaxPoolPreparedStatementPerConnectionSize(maxPoolPreparedStatementPerConnectionSize);  
        try {  
            datasource.setFilters(filters);  
        } catch (SQLException e) {  
            logger.error("druid configuration initialization filter", e);  
        }  
        datasource.setConnectionProperties(connectionProperties);  
          
        return datasource;  
    }  
}
```

## 五、这样就ok了
#### 但我总感觉方法有点LOW ，如果各位大佬有更好的方式，欢迎留言，非常感谢，
#### 如果文章有写错的地方，非常欢迎指出
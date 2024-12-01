---
title: Spring-security与JWT前后端分离
date: 2021-07-23 18:59:00
updated: 2021-07-23 18:59:00
tags: [Spring Boot,JWT,SpringSecurity]
categories: Java
---

### 一、Spring Security概述

+ Spring Security是一个能够为基于Spring的企业应用系统提供声明式的安全访问控制解决方案的安全框架。它提供了一组可以在Spring应用上下文中配置的Bean，充分利用了Spring IoC，DI（控制反转Inversion of Control ,DI:Dependency Injection 依赖注入）和AOP（面向切面编程）功能，为应用系统提供声明式的安全访问控制功能，减少了为企业系统安全控制编写大量重复代码的工作。

<!--more-->

+ Java 主流权限框架：`shiro`、`Spring Security`

### 二、快速开始
+ 本文的SpringSecurity版本:`5.4.6`，需要 Java 8 或更高版本的运行时环境。
+ 本文不想讲底层，直接适合实战使用
+ 反正我只知道它是用来做权限控制的，本文是以Springboot整合作为例子

#### 1、导入依赖
+ 我现在使用的是Springboot 2.4.5 算目前挺新的版本

```
<dependency>
	<groupId>org.springframework.boot</groupId>
	<artifactId>spring-boot-starter-security</artifactId>
</dependency>
```

#### 2、编写一个测试接口
```
@RestController
public class TestController {

    @GetMapping("/test")
    public Object test(){
        return "ok,可以访问";
    }
}
```

+ 然后启动访问`/test`,发现会自动跳转到spring security 的默认登录页面

![](login.png)

+ 那账号去哪取呢？
+ 默认的用户是：`user`,然后密码是UUID随机字符串在项目启动的时候在控制台打印

![](pwd.png)

+ 怎么知道的呢？可查看：`UserDetailsServiceAutoConfiguration.inMemoryUserDetailsManager()`
+ 发现是从：`SecurityProperties`这个类取的。然后发现该类上使用：`@ConfigurationProperties(prefix = "spring.security")` 注解
+ 那也就是可以配置的，往下拉看到一个内部静态User类

![](user.png)

#### 3、配置用户密码
+ 既然知道是读取SecurityProperties中的user,那就可以配置了
+ 在 application.yml 配置如下：

```
spring:
  security:
    user:
      name: rstyro
      password: rstyro
```

#### 4、基本原理
+ 其底层就是经过一系列的过滤器实现权限验证的，如下，官网给出的完整过滤链（`5.4.6版本`）
+ SpringSecurity 的过滤链排序：
+ **ChannelProcessingFilter**
+ **WebAsyncManagerIntegrationFilter**
+ **SecurityContextPersistenceFilter**
+ **HeaderWriterFilter**
+ **CorsFilter**
+ **CsrfFilter**
+ **LogoutFilter**
+ **OAuth2AuthorizationRequestRedirectFilter**
+ **Saml2WebSsoAuthenticationRequestFilter**
+ **X509AuthenticationFilter**
+ **AbstractPreAuthenticatedProcessingFilter**
+ **CasAuthenticationFilter**
+ **OAuth2LoginAuthenticationFilter**
+ **Saml2WebSsoAuthenticationFilter**
+ **UsernamePasswordAuthenticationFilter(表单认证)**
+ **OpenIDAuthenticationFilter**
+ **DefaultLoginPageGeneratingFilter**
+ **DefaultLogoutPageGeneratingFilter**
+ **ConcurrentSessionFilter**
+ **DigestAuthenticationFilter(摘要认证)**
+ **BearerTokenAuthenticationFilter**
+ **BasicAuthenticationFilter(基本认证)**
+ **RequestCacheAwareFilter**
+ **SecurityContextHolderAwareRequestFilter**
+ **JaasApiIntegrationFilter**
+ **RememberMeAuthenticationFilter**
+ **AnonymousAuthenticationFilter**
+ **OAuth2AuthorizationCodeGrantFilter**
+ **SessionManagementFilter**
+ **ExceptionTranslationFilter(自定义异常处理器)**
+ **FilterSecurityInterceptor(授权接口是否需要拦截)**
+ **SwitchUserFilter**

### 三、实战前后端分离
+ 前面的例子，算hello world 入门，好像现在学啥东西都有个hello world。咱不能少
+ 废话不多说，实战开始，现在2021年项目基本都是前后端分离了。

#### 1、依赖引入
+ 和hello world 一样意思引入依赖

```
<dependency>
	<groupId>org.springframework.boot</groupId>
	<artifactId>spring-boot-starter-security</artifactId>
</dependency>
```

+ 里面包含了：`spring-security-config`、`spring-security-web`、这两个里面又包含了很多核心组件
+ 我们只需引入Springboot帮我们封装好的：`spring-boot-starter-security`即可。

#### 2、实现自己的用户体系
+ Spring-security 提供了UserDetailsService接口,我们重新实现`loadUserByUsername()`即可
+ 这个方法里面返回的`UserDetails`用户信息有：用户名称、密码、权限信息，还有一些状态如：是否过期，是否可用等等
+ 从 UserDetailsService 可以知道最终交给Spring Security的是 UserDetails
+ 我们实现：`UserDetails`构建我们自己的用户实体类。

```java
@Data
@Accessors(chain = true)
@NoArgsConstructor
public class SecurityUser implements UserDetails {
    /**
     * 密码
     */
    private String password;
    /**
     * 用户名
     */
    private String username;

    /**
     * 权限
     */
    private Set<GrantedAuthority> authorities;

    /**
     * 自定义字段
     */
    private String nickName;

    public SecurityUser(String password, String username, Set<GrantedAuthority> authorities) {
        this.password = password;
        this.username = username;
        this.authorities = authorities;
    }

    public SecurityUser(String password, String username, Set<GrantedAuthority> authorities, String nickName) {
        this.password = password;
        this.username = username;
        this.authorities = authorities;
        this.nickName = nickName;
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return authorities;
    }

    @Override
    public String getPassword() {
        return password;
    }

    @Override
    public String getUsername() {
        return username;
    }

    /**
     * 账号是否失效
     * @return
     */
    @Override
    public boolean isAccountNonExpired() {
        return true;
    }

    /**
     * 账号是否锁定
     * @return
     */
    @Override
    public boolean isAccountNonLocked() {
        return true;
    }

    /**
     * 密码是否失效
     * @return
     */
    @Override
    public boolean isCredentialsNonExpired() {
        return true;
    }

    /**
     * 是否可用
     * @return
     */
    @Override
    public boolean isEnabled() {
        return true;
    }
}
```
+ 其实就多了一个nickName，可以自定义其他的。
+ 简单的设计了下用户表与权限表，大概如下：

![](table.png)


+ 然后重写`loadUserByUsername()`方法，实现我们的用户与权限

```java
@Service
public class SecurityUserService implements UserDetailsService {

    /**
     * 自己系统的用户体系
     */
    private IUserService userService;
    private IUserRoleService userRoleService;
    private ISysRoleMenuService sysRoleMenuService;
    private ISysRoleService sysRoleService;
    /**
     * spring security 加密方式
     */
    private PasswordEncoder passwordEncoder;

    @Autowired
    public void setUserRoleService(IUserRoleService userRoleService) {
        this.userRoleService = userRoleService;
    }
    @Autowired
    public void setSysRoleMenuService(ISysRoleMenuService sysRoleMenuService) {
        this.sysRoleMenuService = sysRoleMenuService;
    }
    @Autowired
    public void setSysRoleService(ISysRoleService sysRoleService) {
        this.sysRoleService = sysRoleService;
    }

    @Autowired
    public void setPasswordEncoder(PasswordEncoder passwordEncoder) {
        this.passwordEncoder = passwordEncoder;
    }

    @Autowired
    public void setUserService(IUserService userService) {
        this.userService = userService;
    }

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        User user = userService.getOne(new LambdaQueryWrapper<User>().eq(User::getUsername, username));
        if(user==null){
            throw new UsernameNotFoundException("用户名或密码错误！！");
        }
        //获取用户权限，并把其添加到GrantedAuthority中
        Set<GrantedAuthority> grantedAuthorities=new HashSet<>();
        List<UserRole> userRoles = userRoleService.list(new LambdaQueryWrapper<UserRole>().eq(UserRole::getUserId, user.getId()));
        if(!ObjectUtils.isEmpty(userRoles)){
            // 用户的所有角色ID
            Set<Long> roleIds = userRoles.stream().map(UserRole::getRoleId).collect(Collectors.toSet());
            // 角色详情列表
            List<SysRole> sysRoles = sysRoleService.listByIds(roleIds);
            // 所有角色下的资源权限
            Set<String> permissionsByRoleIds = sysRoleMenuService.getPermissionsByRoleIds(roleIds);

            // 添加 角色权限
            sysRoles.forEach(r->{
                // spring security 角色权限默认前缀有：ROLE_
                GrantedAuthority grantedAuthority=new SimpleGrantedAuthority("ROLE_"+r.getRoleName().trim());
                grantedAuthorities.add(grantedAuthority);
            });

            //添加资源权限
            permissionsByRoleIds.forEach(permission->{
//                GrantedAuthority grantedAuthority=new SimpleGrantedAuthority("ROLE_"+permission.trim());
                // 这里不加前缀，可以使用 hasAuthority() 方法
                GrantedAuthority grantedAuthority=new SimpleGrantedAuthority(permission.trim());
                grantedAuthorities.add(grantedAuthority);
            });
        }

        SecurityUser securityUser = new SecurityUser();
        securityUser.setUsername(user.getUsername())
                .setNickName(user.getNickName())
                .setPassword(passwordEncoder.encode(user.getPassword()))
                .setAuthorities(grantedAuthorities);
        return securityUser;
    }
}
```

#### 3、自定义登录接口
+ 默认登录接口是表单登录的，我们改造一下，改成JSON格式post请求
+ 自定义一个登录过滤器，在UsernamePasswordAuthenticationFilter表单登录过滤器之前执行

```java
**
 * 自定义登录过滤器
 */
public class JWTLoginFilter extends AbstractAuthenticationProcessingFilter {

    /**
     * 父类的构造方法
     * @param defaultFilterProcessesUrl 默认需要过滤的 url
     * @param authenticationManager 权限管理器
     */
    public JWTLoginFilter(String defaultFilterProcessesUrl, AuthenticationManager authenticationManager) {
        super(new AntPathRequestMatcher(defaultFilterProcessesUrl));
        setAuthenticationManager(authenticationManager);
    }


    /**
    /**
     * 自定义处理 登录认证，这里使用的json body 登录
     * @param request
     * @param response
     * @return
     * @throws IOException
     */
    @SneakyThrows
    public Authentication attemptAuthentication(HttpServletRequest request, HttpServletResponse response) throws IOException {
        LoginDto user = new ObjectMapper().readValue(request.getInputStream(), LoginDto.class);
        // 前端提交上来的是明文，数据库保存的密码是简单的 md5 加密，所以这边要和数据库保存的密码算法一致
        String encryptPwd = MDUtil.bcMD5(user.getPassword());
        UsernamePasswordAuthenticationToken authenticationToken = new UsernamePasswordAuthenticationToken(
                user.getUsername(),
                encryptPwd);
        return getAuthenticationManager().authenticate(authenticationToken);
    }


    /**
     * 登录成功返回 token
     */
    @Override
    protected void successfulAuthentication(HttpServletRequest request, HttpServletResponse response, FilterChain chain, Authentication auth){
        SecurityUser principal = (SecurityUser)auth.getPrincipal();
        System.out.println("authorite="+principal.getAuthorities().toString());
        String token = JwtUtils.generateKey(new SecurityUser()
                .setUsername(principal.getUsername())
                .setAuthorities(new HashSet<>(principal.getAuthorities())));
        try {
            //登录成功時，返回json格式进行提示
            ServletUtils.render(request,response,R.ok(token));
        } catch (Exception e1) {
            e1.printStackTrace();
        }
    }

    /**
     * 失败返回
     */
    @Override
    protected void unsuccessfulAuthentication(HttpServletRequest request, HttpServletResponse response, AuthenticationException failed) throws IOException, ServletException {
        String result="";
        // 账号过期
        if (failed instanceof AccountExpiredException) {
            result="账号过期";
        }
        // 密码错误
        else if (failed instanceof BadCredentialsException) {
            result="密码错误";
        }
        // 密码过期
        else if (failed instanceof CredentialsExpiredException) {
            result="密码过期";
        }
        // 账号不可用
        else if (failed instanceof DisabledException) {
            result="账号不可用";
        }
        //账号锁定
        else if (failed instanceof LockedException) {
            result="账号锁定";
        }
        // 用户不存在
        else if (failed instanceof InternalAuthenticationServiceException) {
            result="用户不存在";
        }
        // 其他错误
        else{
            result="未知异常";
        }
        ServletUtils.render(request,response,R.error(result));
    }
}
```

+ `attemptAuthentication()`方法接收参数，密码和数据库保存的一致
+ 然后包装成一个UsernamePasswordAuthenticationToken，进行认证，
+ 之后就会调用我们实现的`loadUserByUsername(String username)`方法
+ 验证通过之后，就会调用过滤器的：`successfulAuthentication()`返回token
+ 我们在配置一个解析JWT的过滤器，如果JWT是正常的，且没过期，我们就通过SecurityContextHolder给它授权，如下

```java
/**
 * 这个进行token的认证拦截
 */
public class SecurityAuthTokenFilter extends BasicAuthenticationFilter {

    public SecurityAuthTokenFilter(AuthenticationManager authenticationManager) {
        super(authenticationManager);
    }
    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain) throws ServletException, IOException {
        String token = getToken(request);
        if(StringUtils.hasLength(token)){
            SecurityUser userInfo = JwtUtils.getUserInfoByToken(token);
            if(userInfo==null){
                ServletUtils.render(request,response, R.error("Token过期或无效"));
                return;
            }
            if (StringUtils.hasLength(userInfo.getUsername()) &&  SecurityContextHolder.getContext().getAuthentication() == null){
                // 如果没过期，保持登录状态
                if (!JwtUtils.isExpiration(token)){
                    // 将用户信息存入 authentication，方便后续校验
                    UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(userInfo.getUsername(), null,userInfo.getAuthorities());
                    // SecurityContextHolder 权限验证上下文
                    SecurityContext context = SecurityContextHolder.getContext();
                    // 指示用户已通过身份验证
                    context.setAuthentication(authentication);
                    System.out.println("authorite="+authentication.getAuthorities().toString());
                }
            }
        }
        // 继续下一个过滤器
        filterChain.doFilter(request, response);
    }

    /**
     * 从header或者参数中获取token
     * @return token
     */
    public String getToken(HttpServletRequest request){
        String token = request.getHeader(ConfigConstValue.TOKEN);
        if(!StringUtils.hasLength(token)){
            token=request.getParameter(ConfigConstValue.TOKEN);
        }
        return token;
    }
}
```
+ 这个拦截器，大致的流程是先从header或参数中获取前端传上来的token
+ 解析token,得到用户与权限，通过SecurityContextHolder 给它验证通过，执行下一个过滤器

#### 4、配置自定义过滤器
+ 我们随便自定义了过滤器，但是还需要配置一下才能生效
+ 我们需要继承：`WebSecurityConfigurerAdapter`适配器

```java
@EnableWebSecurity
//开启权限注解,默认是关闭的
@EnableGlobalMethodSecurity(securedEnabled = true,prePostEnabled = true)
public class SpringSecurityConfig extends WebSecurityConfigurerAdapter {

    //自定义未登录返回
    private AnonymousAuthenticationEntryPoint anonymousAuthenticationEntryPoint;
    //自定义注销返回
    private AuthenticationLogout authenticationLogout;
    //自定义无权访问返回
    private AccessDeny accessDeny;
    // 自定义用户认证service
    private SecurityUserService securityUserService;

    @Autowired
    public void setAnonymousAuthenticationEntryPoint(AnonymousAuthenticationEntryPoint anonymousAuthenticationEntryPoint) {
        this.anonymousAuthenticationEntryPoint = anonymousAuthenticationEntryPoint;
    }

    @Autowired
    public void setAuthenticationLogout(AuthenticationLogout authenticationLogout) {
        this.authenticationLogout = authenticationLogout;
    }
    @Autowired
    public void setAccessDeny(AccessDeny accessDeny) {
        this.accessDeny = accessDeny;
    }
    @Autowired
    public void setSecurityUserService(SecurityUserService securityUserService) {
        this.securityUserService = securityUserService;
    }

    //加密方式
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    //认证
    @Override
    protected void configure(AuthenticationManagerBuilder auth) throws Exception {
        // 自定义认证逻辑
        auth.userDetailsService(securityUserService).passwordEncoder(passwordEncoder());
    }

    @Override
    public void configure(WebSecurity web) {
        // 放行 swagger 相关路径
        String[] authWhiteList = {
                "/swagger-ui.html",
                "/webjars/**",
                "/swagger-resources/**",
                "/v2/**",
                "/csrf",

                // other
                "/css/**",
                "/js/**",
                "/html/**",
                "/instances",
                "/favicon.ico"
        };
        //对于在header里面增加token等类似情况，放行所有OPTIONS请求。
        web.ignoring()
                .antMatchers(HttpMethod.OPTIONS, "/**")
                // 可以直接访问的静态数据或接口
                .antMatchers(authWhiteList);
    }


    //授权
    @Override
    protected void configure(HttpSecurity http) throws Exception {
            http
                .authorizeRequests()// 授权
                .antMatchers("/index/**").anonymous()// 匿名用户权限
                .antMatchers("/api/**").hasRole("USER")//普通用户权限
                .antMatchers("/login").permitAll()
                //其他的需要授权后访问
                .anyRequest().authenticated()
                .and()// 异常
                .exceptionHandling()
                .accessDeniedHandler(accessDeny)//授权异常处理
                .authenticationEntryPoint(anonymousAuthenticationEntryPoint)// 认证异常处理
                .and()
                .logout()
                .logoutSuccessHandler(authenticationLogout)
                .and()
                .addFilterBefore(new JWTLoginFilter("/login",authenticationManager()),UsernamePasswordAuthenticationFilter.class)
                .addFilterBefore(new SecurityAuthTokenFilter(authenticationManager()),UsernamePasswordAuthenticationFilter.class)
                .sessionManagement()
                // 设置Session的创建策略为：Spring Security不创建HttpSession
                .sessionCreationPolicy(SessionCreationPolicy.STATELESS)
                .and()
                .csrf().disable();// 关闭 csrf
    }

    @Bean
    @Override
    public AuthenticationManager authenticationManager() throws Exception {
        return super.authenticationManager();
    }

}
```

+ `JWTLoginFilter` 只有当我们调用：`/login`接口的时候才会生效
+ `SecurityAuthTokenFilter` 每次接口调用都会走
+ `@EnableWebSecurity`这个注解使security生效
+ `@EnableGlobalMethodSecurity`这个是使权限注解生效，可选项有：
    + ***prePostEnabled=true*** 会解锁 @PreAuthorize 和 @PostAuthorize 两个注解,可以使用EL表达式
    + ***securedEnabled=true*** 解锁 @Secured注解，不支持Spring EL表达式，指定的角色必须以`ROLE_`开头
    + ***jsr250Enabled=true*** 解锁：`@DenyAll`全部拒绝，`@RolesAllowed({“USER”, “ADMIN”})`任意权限，`@PermitAll`都可访问
+ PasswordEncoder 使用的是`BCryptPasswordEncoder`
+ 在`config(HttpSecurity http)`方法里，调用`addFilterBefore()`方法添加我们的过滤器
+ 剩下的就是配置自定义的报错handler，代码都有注释就不解释了
+ handler 代码就不粘贴出来了，后面给出完整的代码地址。

#### 5、接口测试
+ 核心方法与代码都讲了，接下来就是测试了
+ 调用：`http://localhost:8081/login` 接口，得到token,然后通过token去请求其他的接口

![](json_login.png)

+ 登录的用户名/密码：rstyro/123456

![](test.png)

![](test2.png)

#### 6、完整代码地址
+ **Github:**  [https://github.com/rstyro/Springboot/tree/master/springboot-security](https://github.com/rstyro/Springboot/tree/master/springboot-security)
+ **Gitee:**  [https://gitee.com/rstyro/spring-boot/tree/master/springboot-security](https://gitee.com/rstyro/spring-boot/tree/master/springboot-security)

+ **参考链接：**
	+ [https://docs.spring.io/spring-security/site/docs/5.4.6/reference/html5/#introduction](https://docs.spring.io/spring-security/site/docs/5.4.6/reference/html5/#introduction)
	+ [https://zszxz.com/category/springsecurity/article/65](https://zszxz.com/category/springsecurity/article/65)


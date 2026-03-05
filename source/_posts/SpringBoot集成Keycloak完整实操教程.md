---
title: SpringBoot集成Keycloak完整实操教程
tags: [Java,Spring Boot]
categories: Java
date: 2026-03-05 15:13:24
---


本文将全面讲解Keycloak的核心概念、服务器搭建配置，以及Spring Boot与Keycloak的完整集成流程，同时覆盖OAuth2.0、OIDC协议原理、多租户多客户端实现、常见问题排查等内容，打造一份可直接落地的实操指南，适用于微服务、企业应用、SaaS平台的身份认证与授权场景。



## 一、Keycloak 是什么

Keycloak 是一个开源的身份和访问管理（IAM）解决方案，专为现代应用程序和服务设计。它由 Red Hat 开发和维护，提供了完整的身份管理功能，使开发者能够轻松实现安全的用户认证和授权。

<!-- more -->

### 1.1 Keycloak 的核心功能

- **单点登录（SSO）**：用户只需登录一次即可访问所有集成的应用，无需在每个应用中重复登录
- **身份代理和社交登录**：支持与 Google、Facebook、Twitter 等第三方身份提供商集成，用户可以使用现有社交账号登录
- **用户联盟**：可以连接到现有的用户存储，如 LDAP、Active Directory 等
- **客户端适配器**：提供与各种应用框架的集成，包括 Spring Boot、Node.js、Angular 等
- **管理控制台**：直观的管理界面，用于配置和管理用户、角色、客户端等
- **账户管理**：用户可以管理自己的个人资料、密码和授权
- **细粒度授权**：基于角色的访问控制（RBAC）和基于资源的权限管理
- **多因素认证**：支持短信、电子邮件、TOTP 等多因素认证方式
- **会话管理**：管理员可以查看和管理用户会话
- **事件记录和审计**：记录用户登录、登出等事件，便于审计和监控

### 1.2 Keycloak 的应用场景

Keycloak 适用于以下场景：

1. **企业应用集成**：在企业内部，多个应用系统需要统一的身份认证和授权管理
2. **SaaS 应用**：为 SaaS 应用提供多租户的身份管理解决方案
3. **微服务架构**：在微服务架构中，为各个服务提供统一的身份验证和授权
4. **移动应用**：为移动应用提供安全的身份认证机制
5. **API 安全**：保护 API 接口，确保只有授权用户才能访问
6. **B2B 集成**：实现企业间的安全身份验证和授权
7. **客户门户**：为客户提供安全的自助服务门户
8. **合规要求**：满足 GDPR、HIPAA 等合规要求的身份管理解决方案

### 1.3 Keycloak 的优势

- **开源免费**：基于 Apache 2.0 许可证，完全免费使用
- **功能完整**：提供了企业级身份管理所需的所有核心功能
- **易于集成**：提供了丰富的客户端适配器和 API
- **可扩展性**：支持集群部署，可处理高并发场景
- **安全性**：内置多种安全特性，如多因素认证、密码策略等
- **标准化**：实现了 OAuth 2.0、OpenID Connect 等标准协议

本文使用 Keycloak 的管理控制台，通过 Spring Security OAuth2.0 与 Spring Boot 应用集成。

## 二、设置 Keycloak 服务器

### 2.1、下载和安装 Keycloak

1. 从Keycloak 官方网站：[https://www.keycloak.org/downloads](https://www.keycloak.org/downloads) 下载最新版本的 Keycloak
2. 下载完成后，解压压缩包至本地指定目录
3. 进入解压根目录，执行对应命令启动服务（开发模式）：



```bash
# Linux/Mac系统启动命令
bin/kc.sh start-dev

# Windows系统默认启动命令
bin\kc.bat start-dev

# Windows系统指定8880端口启动
bin\kc.bat start-dev --http-port=8880
```


启动成功后，Keycloak默认访问地址：**http://localhost:8080**，自定义端口则替换对应端口即可

**注意**：`start-dev`为开发模式，仅适用于本地测试；生产环境需改用生产模式启动，配置HTTPS、数据库持久化等参数。

### 2.2、创建 Realm（领域）

1. 打开浏览器，访问 http://localhost:8080
2. 首次访问会提示创建管理员账户，按照提示设置用户名和密码
3. 登录管理控制台后，点击左侧菜单栏**Realm**下拉菜单
4. 点击**Create Realm**按钮
5. 输入Realm名称：`my-realm`，点击Create完成创建


![首次访问需要配置管理员用户](init.png)





![新建一个Realm为my-realm名称](my-realm.png)


### 2.3、创建客户端

1. 左侧菜单栏点击**Clients**，选择**Create client**
2. 填写基础配置信息：
    - Client type：`OpenID Connect`
    - Client ID：`my-java-app`
    - Name：`My Java Application`
3. 点击Next进入下一步
4. Access settings页面核心配置：
    - Root URL：`http://localhost:8081`（Spring Boot应用地址）
    - Valid redirect URIs：`http://localhost:8081/login/oauth2/code/keycloak`（授权回调地址，必须精准配置）
    - Web origins：`http://localhost:8081`（跨域白名单）
5. 点击Save保存配置
6. 进入客户端详情页，切换到**Credentials**选项卡，复制生成的**Client secret**，后续Spring Boot配置需用到



![新建客户端步骤1](client1.png)

![开启客户端验证](client2.png)

![配置客户端重定向白名单](client3.png)

- 配置客户端的重定向白名单地址
- 还有跨越的地址



![查看客户端秘钥](client4.png)



- 查看客户端的秘钥，或者重新生成秘钥




### 2.4、创建角色和用户

1. 创建角色：左侧菜单栏点击**Roles** → **Create role**，输入角色名（如`user`），点击Save保存
2. 创建用户：左侧菜单栏点击**Users** → **Add user**，输入用户名（如`test`），点击Create
3. 设置用户密码：进入用户详情页，切换到**Credentials**选项卡，设置密码并关闭**Temporary**（临时密码）选项，点击Set password确认
4. 分配角色：切换到**Role mapping**选项卡，将刚才创建的`user`角色分配给该用户


![创建用户并设置密码](client5.png)



## 三、Spring Boot 应用配置

### 3.1、项目依赖

在 `pom.xml` 文件中添加以下依赖：

```xml
<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
     <!-- Spring Security（安全认证核心） -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-security</artifactId>
    </dependency>
    <!-- OAuth2资源服务器依赖，用于API接口鉴权-->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-oauth2-resource-server</artifactId>
    </dependency>
    <!-- OAuth2客户端依赖，用于对接Keycloak完成登录认证 -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-oauth2-client</artifactId>
    </dependency>
</dependencies>
```

### 3.2、应用配置

在`application.yml`中配置Keycloak相关参数，替换为自己的客户端密钥和Realm地址，端口需与Keycloak客户端配置一致：

```yaml
server:
  port: 8081  # 应用端口，与Keycloak客户端回调地址保持一致
spring:
  application:
    name: keycloak-demo
  security:
    oauth2:
      client:
        registration:
          keycloak:
            client-id: my-java-app  # Keycloak中创建的客户端ID
            client-secret: {your-client-secret}  # 替换为复制的客户端密钥
            authorization-grant-type: authorization_code  # 授权码模式
            redirect-uri: "{baseUrl}/login/oauth2/code/keycloak"  # 回调地址
        provider:
          keycloak:
            issuer-uri: http://localhost:8080/realms/my-realm  # Keycloak Realm地址
            user-name-attribute: preferred_username  # 用户名属性
      resourceserver:
        jwt:
          issuer-uri: http://localhost:8080/realms/my-realm  # JWT签发地址
```

#### 配置核心原理说明

- Spring Security 的 OAuth2 客户端模块（`spring-boot-starter-oauth2-client`）在启动时会自动注册一系列默认的组件，其中最关键的是一个 **过滤器（Filter）**——`OAuth2LoginAuthenticationFilter`。
- 这个过滤器默认拦截的请求路径正是 `/login/oauth2/code/*`。我们配置的 `redirect-uri` 以这个路径结尾时，授权服务器完成用户授权后，会将用户重定向回我们应用的这个地址。
- **自动处理回调**
  当请求到达 `/login/oauth2/code/keycloak` 时，过滤器会自动：
  - 从请求中提取 **授权码（authorization code）**。
  - 根据配置的 `provider` 信息（如 `issuer-uri`）发现 Keycloak 的令牌端点。
  - 携带 `client-id`、`client-secret` 和授权码，向 Keycloak 的令牌端点发起请求，换取 **访问令牌（access token）** 和 **ID 令牌（id token）**。
  - 解析 ID 令牌中的用户信息（如我们指定的 `user-name-attribute: preferred_username`），创建 Spring Security 的 `Authentication` 对象，完成用户登录。







### 3.3、安全配置

创建 `SecurityConfig.java` 文件，配置 Spring Security：

```java
package top.lrshuai.keycloak.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity  // 开启方法级权限控制
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            // 接口权限配置
            .authorizeRequests(authorize -> authorize
                .requestMatchers("/public/**").permitAll()  // 公开接口，无需登录
                .anyRequest().authenticated()  // 其余接口均需登录认证
            )
            // OAuth2登录配置
            .oauth2Login(oauth2 -> oauth2
                .defaultSuccessUrl("/home", true)  // 登录成功跳转地址
            )
            // 资源服务器JWT配置
            .oauth2ResourceServer(oauth2 -> oauth2
                .jwt(jwt -> jwt
                    .issuerUri("http://localhost:8080/realms/my-realm")
                )
            )
            // 登出配置
            .logout(logout -> logout
                .logoutSuccessUrl("/public/logout-success")  # 登出成功跳转地址
            );
        return http.build();
    }
}
```

### 3.4、控制器实现

创建 `HomeController.java` 文件，实现基本的端点：

```java
package top.lrshuai.keycloak.controller;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.core.oidc.user.OidcUser;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
public class HomeController {

    @GetMapping("/public/hello")
    public String publicHello() {
        return "Hello from public endpoint!";
    }

    @GetMapping("/home")
    public Map<String, Object> home(@AuthenticationPrincipal OidcUser user) {
        return Map.of(
            "message", "Hello from secured endpoint!",
            "userName", user.getPreferredUsername(),
            "name", user.getFullName(),
            "email", user.getEmail(),
            "claims", user.getClaims()
        );
    }

    @GetMapping("/public/logout-success")
    public String logoutSuccess() {
        return "Logout successful!";
    }
}
```



![当请求/home接口时返回](home.png)



- 当请求/home接口时会判断，用户是否登录
  - 如果没有登录会跳转keycloak登录页面进行登录验证
  - 如果登录了就直接返回用户信息
  - Spring MVC 调用 `HomeController.home(...)`。
  - `AuthenticationPrincipalArgumentResolver` 从 `SecurityContext` 获取 `Authentication`，取出 `principal`（即 `OidcUser`），注入方法参数。




```tex
浏览器回调 → OAuth2LoginAuthenticationFilter
                 │
                 ├─ 提取 code, state
                 ├─ 从 session 获取 authorizationRequest
                 ├─ 验证 state
                 └─ 创建 OAuth2LoginAuthenticationToken
                      ↓
               AuthenticationManager (ProviderManager)
                      ↓
        OidcAuthorizationCodeAuthenticationProvider
                      ├─ 用 code 换取 token（OAuth2AccessTokenResponseClient）
                      ├─ 验证 ID Token（OidcIdTokenDecoderFactory）
                      ├─ 加载用户信息（OidcUserService）
                      └─ 构建 OidcAuthenticationToken
                      ↓
       返回认证后的 OidcAuthenticationToken 给过滤器
                      ↓
         SecurityContextHolder.getContext().setAuthentication(...)
                      ↓
         认证成功处理器 → 重定向回原请求
```



### 3.5、测试步骤

1. **启动 Keycloak 服务器**：确保 Keycloak 在 http://localhost:8080 上运行
2. **启动 Spring Boot 应用**：运行 `mvn spring-boot:run` 命令
3. **访问公开端点**：打开浏览器，访问 http://localhost:8081/public/hello，应该直接返回 "Hello from public endpoint!"
4. **访问受保护端点**：访问 http://localhost:8081/home，会跳转到 Keycloak 登录页面
5. **登录**：使用之前创建的用户凭据登录
6. **验证**：登录成功后，会跳转到 /home 端点，显示用户信息
7. **退出登录**：访问 http://localhost:8081/logout，然后访问 /public/logout-success 查看退出成功信息

### 3.6、常见问题及解决方案

#### 1、客户端配置错误

**问题**：登录时出现 "Invalid redirect URI" 错误
**解决方案**：确保 Keycloak 客户端配置中的 "Valid redirect URIs" 包含 `http://localhost:8081/login/oauth2/code/keycloak`

#### 2、客户端密钥错误

**问题**：登录时出现 "Bad credentials" 错误
**解决方案**：确保 `application.yml` 文件中的 `client-secret` 与 Keycloak 客户端详情页面中的 "Client secret" 一致

#### 3、令牌验证失败

**问题**：访问受保护端点时出现 "Invalid token" 错误
**解决方案**：确保 `application.yml` 文件中的 `issuer-uri` 正确，格式为 `http://localhost:8080/realms/my-realm`








## 四、Keycloak与OAuth2.0、OIDC协议详解

### 4.1、OAuth2.0 简介

OAuth 2.0 是一个授权框架，允许应用程序在用户授权的情况下访问用户的资源。它定义了以下角色：

- **资源所有者**：用户，拥有受保护的资源
- **客户端**：需要访问资源的应用程序
- **资源服务器**：存储受保护资源的服务器
- **授权服务器**：验证用户身份并颁发访问令牌

### 4.2、Keycloak 作为 OAuth2.0 授权服务器

Keycloak 实现了 OAuth 2.0 规范，可以作为授权服务器使用。它提供了以下 OAuth 2.0 流程：

- **授权码流程**：最常用的流程，适用于有服务器端的应用
- **隐式流程**：适用于纯前端应用
- **客户端凭证流程**：适用于服务器间通信
- **密码流程**：适用于受信任的应用

在本示例中，我们使用的是授权码流程。

### 4.3、OpenID Connect (OIDC) 协议详解

#### 4.3.1、OIDC 简介

OpenID Connect (OIDC) 是建立在 OAuth 2.0 协议之上的身份认证层，它扩展了 OAuth 2.0，添加了身份认证功能。OIDC 允许客户端验证用户的身份，并获取用户的基本配置信息。

OIDC 定义了以下核心概念：

- **ID Token**：包含用户身份信息的 JWT (JSON Web Token)，由授权服务器签名
- **UserInfo Endpoint**：客户端可以通过此端点获取用户的详细信息
- **Discovery Endpoint**：提供 OIDC 提供商的配置信息
- **Client Registration**：客户端注册机制

#### 4.3.2、OIDC 与 OAuth 2.0 的关系

OIDC 是 OAuth 2.0 的超集，它在 OAuth 2.0 的基础上添加了身份认证功能。OAuth 2.0 主要解决授权问题，而 OIDC 主要解决身份认证问题。

- **OAuth 2.0**：关注"用户是否允许客户端访问其资源"
- **OIDC**：关注"用户是谁"以及"用户是否已认证"

#### 4.3.3、OIDC 的工作流程

OIDC 的工作流程基于 OAuth 2.0 的授权码流程，主要步骤如下：

1. **客户端重定向**：客户端将用户重定向到 OIDC 提供商的授权端点
2. **用户认证**：用户在 OIDC 提供商处进行认证
3. **授权同意**：用户同意客户端请求的权限
4. **颁发授权码**：OIDC 提供商向客户端颁发授权码
5. **交换令牌**：客户端使用授权码向 OIDC 提供商请求令牌（包括 ID Token 和 Access Token）
6. **验证 ID Token**：客户端验证 ID Token 的签名和内容
7. **获取用户信息**：客户端可以使用 Access Token 从 UserInfo 端点获取用户详细信息

#### 4.3.4、OIDC 的应用场景

OIDC 适用于以下场景：

1. **单点登录（SSO）**：用户只需登录一次，即可访问多个应用
2. **跨域身份认证**：在不同域名的应用之间实现统一的身份认证
3. **移动应用和原生应用**：为移动应用和原生应用提供安全的身份认证机制
4. **API 网关认证**：在 API 网关中使用 OIDC 进行身份验证和授权
5. **微服务架构**：在微服务架构中，使用 OIDC 实现服务间的安全通信
6. **联合身份**：实现不同组织之间的身份联合

#### 4.3.5、OIDC 的优势

- **标准化**：基于开放标准，由 IETF 标准化
- **简单易用**：使用 JSON 和 RESTful API，易于实现和集成
- **安全可靠**：使用 JWT 进行身份令牌的传输和验证
- **灵活可扩展**：支持多种认证方式和扩展声明
- **广泛支持**：被众多身份提供商和客户端框架支持

#### 4.3.6、Keycloak 与 OIDC

Keycloak 是一个功能完整的 OIDC 提供商，它实现了 OIDC 1.0 规范，提供了以下 OIDC 功能：

- **ID Token 颁发**：生成和签名 ID Token
- **UserInfo 端点**：提供用户信息
- **Discovery 端点**：提供 OIDC 配置信息
- **客户端注册**：支持动态客户端注册
- **多因素认证**：支持基于 OIDC 的多因素认证
- **会话管理**：基于 OIDC 的会话管理

在本示例中，我们使用 Keycloak 作为 OIDC 提供商，通过 Spring Security OAuth2 客户端集成，实现了基于 OIDC 的身份认证。



## 五、多租户多客户端实现

### 1、多租户概念

多租户是指一个应用系统可以同时为多个独立的组织（租户）提供服务，每个租户的数据和配置相互隔离。在 Keycloak 中，多租户通常通过以下方式实现：

- **使用多个 Realm**：每个租户使用一个独立的 Realm，完全隔离租户数据
- **使用单一 Realm + 客户端隔离**：在一个 Realm 中创建多个客户端，通过客户端权限控制实现隔离
- **使用单一 Realm + 组织/群组**：在一个 Realm 中使用组织或群组来管理不同租户的用户

### 2、多客户端配置

在 Keycloak 中，每个应用都应该创建一个独立的客户端。以下是多客户端配置的步骤：

1. **创建多个客户端**：
   - 在 Keycloak 管理控制台中，为每个应用创建一个独立的客户端
   - 为每个客户端设置不同的 Client ID 和配置

2. **客户端配置示例**：
   - 客户端 1：`app-client-1`，用于应用 1
   - 客户端 2：`app-client-2`，用于应用 2

3. **设置客户端权限**：
   - 为每个客户端设置独立的角色和权限
   - 配置客户端之间的访问控制

### 3、Spring Boot 应用中的多租户多客户端实现

#### 3.1、配置多个 OAuth2 客户端

在 `application.yml` 文件中配置多个 OAuth2 客户端：

```yaml
spring:
  security:
    oauth2:
      client:
        registration:
          keycloak-app1:
            client-id: app-client-1
            client-secret: {client-secret-1}
            authorization-grant-type: authorization_code
            redirect-uri: "{baseUrl}/login/oauth2/code/keycloak-app1"
            scope: openid,profile,email
          keycloak-app2:
            client-id: app-client-2
            client-secret: {client-secret-2}
            authorization-grant-type: authorization_code
            redirect-uri: "{baseUrl}/login/oauth2/code/keycloak-app2"
            scope: openid,profile,email
        provider:
          keycloak-app1:
            issuer-uri: http://localhost:8080/realms/my-realm
            user-name-attribute: preferred_username
          keycloak-app2:
            issuer-uri: http://localhost:8080/realms/my-realm
            user-name-attribute: preferred_username
```

#### 3.2、多租户安全配置

创建 `SecurityConfig.java` 文件，配置多个客户端的安全规则：

```java
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .authorizeRequests(authorize -> authorize
                .requestMatchers("/public/**").permitAll()
                .requestMatchers("/app1/**").authenticated()
                .requestMatchers("/app2/**").authenticated()
                .anyRequest().authenticated()
            )
            .oauth2Login(oauth2 -> oauth2
                .loginPage("/login")
                .defaultSuccessUrl("/home", true)
            )
            .oauth2ResourceServer(oauth2 -> oauth2
                .jwt(jwt -> jwt
                    .issuerUri("http://localhost:8080/realms/my-realm")
                )
            )
            .logout(logout -> logout
                .logoutSuccessUrl("/public/logout-success")
            );
        return http.build();
    }
}
```

#### 3.3、多租户控制器实现

创建 `MultiTenantController.java` 文件，实现多租户支持：

```java
package top.lrshuai.keycloak.controller;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.core.oidc.user.OidcUser;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
public class MultiTenantController {

    @GetMapping("/app1/home")
    public Map<String, Object> app1Home(@AuthenticationPrincipal OidcUser user) {
        return Map.of(
            "message", "Hello from App 1 secured endpoint!",
            "userName", user.getPreferredUsername(),
            "name", user.getFullName(),
            "email", user.getEmail(),
            "claims", user.getClaims()
        );
    }

    @GetMapping("/app2/home")
    public Map<String, Object> app2Home(@AuthenticationPrincipal OidcUser user) {
        return Map.of(
            "message", "Hello from App 2 secured endpoint!",
            "userName", user.getPreferredUsername(),
            "name", user.getFullName(),
            "email", user.getEmail(),
            "claims", user.getClaims()
        );
    }
}
```

### 4、多 Realm 实现（高级多租户）

对于需要完全隔离的多租户场景，可以使用多个 Realm：

1. **创建多个 Realm**：
   - 在 Keycloak 管理控制台中创建多个 Realm，每个租户一个
   - 例如：`tenant1-realm`、`tenant2-realm`

2. **配置多个 Realm 的客户端**：
   - 在每个 Realm 中创建相应的客户端
   - 为每个 Realm 配置独立的用户和角色

3. **Spring Boot 应用配置**：

#### 4.1、application.yml 配置

```yaml
keycloak:
  base-uri: http://localhost:8080
  # 多租户多客户端配置
  realms:
    my-realm:
      - clientId: my-java-app
        clientSecret: hmzuyDYTEaQOZQgdwHnc14TGiqR1GBHL
      - clientId: test-app
        clientSecret: aHyjJICU1MgYWz2BgKiRFBnn9ExAfkPA
    app:
      - client-id: app
        client-secret: QNie8ATbJoUwaP35bkXRQNfuTQYmYf7Q
```

#### 4.2、DynamicRealmsController配置

```java
/**
 * 多租户多客户端
 */
@RestController
@RequestMapping("/realms")
public class DynamicRealmsController {

    @Resource
    private KeyCloakProperties keyCloakProperties;

    @Resource
    private RestTemplate restTemplate;

    private final ObjectMapper objectMapper = new ObjectMapper();

    /**
     * 发起认证请求
     *
     * @param realm        Keycloak realm
     * @param clientId     客户端ID
     * @param redirect_uri 前端回调地址（必须与Keycloak客户端配置一致）
     * @param scope        权限范围：openid profile email
     * @param state        防CSRF状态值（前端生成并保存）
     * @param nonce        随机数
     * @param access_type  访问类型（online/offline）
     * @param response     HttpServletResponse
     */
    @GetMapping("/{realm}/protocol/openid-connect/auth")
    public void auth(
            @PathVariable String realm,
            @RequestParam String clientId,
            @RequestParam String redirect_uri,
            @RequestParam String scope,
            @RequestParam(required = false) String state,
            @RequestParam(required = false) String nonce,
            @RequestParam(required = false) String access_type,
            HttpServletResponse response) throws IOException {

        // 验证 clientId 是否存在
        boolean clientValid = keyCloakProperties.getRealms()
                .getOrDefault(realm,new ArrayList<>())
                .stream()
                .anyMatch(k -> k.getClientId().equals(clientId));

        if (!clientValid) {
            log.warn("Invalid client_id: {}", clientId);
            sendErrorRedirect(response, redirect_uri, "unauthorized_client", "Invalid client_id", state);
            return;
        }

        if (state == null) {
            state = UUID.randomUUID().toString(); // 建议前端生成，此处仅为后备
        }

        String issuer = keyCloakProperties.getBaseUri() + "/realms/" + realm;
        String keycloakAuthUrl = UriComponentsBuilder
                .fromHttpUrl(issuer + "/protocol/openid-connect/auth")
                .queryParam("response_type", "code")
                .queryParam("client_id", clientId)
                .queryParam("redirect_uri", redirect_uri)
                .queryParam("scope", scope)
                .queryParam("state", state)
                .queryParam("nonce", nonce != null ? nonce : UUID.randomUUID().toString())
                .queryParam("access_type", access_type != null ? access_type : "online")
                .build()
                .toUriString();

        log.debug("Redirecting to Keycloak auth URL: {}", keycloakAuthUrl);
        response.sendRedirect(keycloakAuthUrl);
    }



    /**
     * 令牌获取
     * @param realm Keycloak realm
     * @param grant_type 授权类型：authorization_code=授权码模式
     * @param code 授权码
     * @param redirect_uri 回调地址
     * @param clientId 客户端ID
     * @param code_verifier 授权码 校验
     * @return
     */
    @PostMapping(value = "/{realm}/protocol/openid-connect/token", consumes = MediaType.APPLICATION_FORM_URLENCODED_VALUE)
    public R<?> token(
            @PathVariable String realm,
            @RequestParam String grant_type,
            @RequestParam String code,
            @RequestParam String redirect_uri,
            @RequestParam String clientId,
            @RequestParam(required = false) String code_verifier) {

        if (!"authorization_code".equals(grant_type)) {
            return buildError("unsupported_grant_type", "Only authorization_code is supported");
        }
        KeyCloakProperties.AppKey appKey = keyCloakProperties.getRealms()
                .getOrDefault(realm,new ArrayList<>())
                .stream()
                .filter(k -> k.getClientId().equals(clientId))
                .findFirst()
                .orElse(null);

        if (appKey == null) {
            return buildError("invalid_client", "Client not found");
        }

        MultiValueMap<String, String> params = new LinkedMultiValueMap<>();
        params.add("grant_type", "authorization_code");
        params.add("client_id", clientId);
        params.add("client_secret", appKey.getClientSecret());
        params.add("code", code);
        params.add("redirect_uri", redirect_uri);
        if (code_verifier != null) {
            params.add("code_verifier", code_verifier);
        }

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);
        HttpEntity<MultiValueMap<String, String>> request = new HttpEntity<>(params, headers);

        String issuer = keyCloakProperties.getBaseUri() + "/realms/" + realm;
        String keycloakTokenUri = issuer + "/protocol/openid-connect/token";

        try {
            ResponseEntity<Map> response = restTemplate.exchange(
                    keycloakTokenUri,
                    HttpMethod.POST,
                    request,
                    Map.class
            );
            return R.ok(response.getBody());
        }catch (Exception e) {
            log.error("Unexpected error during token exchange", e);
            return buildError("server_error", e.getMessage());
        }
    }


    /**
     * 用户信息获取
     */
    @GetMapping("/{realm}/protocol/openid-connect/userinfo")
    public R<?> userinfo(@AuthenticationPrincipal Jwt user,
                         @RequestHeader("Authorization") String authHeader,@PathVariable String realm) {
        log.info("Authorization header: {}",authHeader);
         if (user != null) {
            System.out.println("===JwtAuthenticationToken===");
            return R.ok(user);
        }
        System.out.println("===Keycloak-API===");
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            return R.fail(401, "Access token missing or invalid");
        }
        // 提取 access token
        String accessToken = authHeader.substring(7);

        // 调用 Keycloak 的 userinfo 端点
        String issuer = keyCloakProperties.getBaseUri() + "/realms/" + realm;
        String userinfoUri = issuer + "/protocol/openid-connect/userinfo";

        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", authHeader);
        HttpEntity<?> request = new HttpEntity<>(headers);
        try {
            ResponseEntity<Map> response = restTemplate.exchange(
                    userinfoUri,
                    HttpMethod.GET,
                    request,
                    Map.class
            );
            return R.ok(response.getBody());
        } catch (HttpClientErrorException e) {
            log.error("Userinfo request failed: {}", e.getResponseBodyAsString(), e);
            Map<String, Object> errorBody = extractErrorBody(e);
            return R.fail(errorBody);
        } catch (Exception e) {
            log.error("Unexpected error during userinfo request", e);
            return buildError("server_error", e.getMessage());
        }
    }
    // 可以扩展OIDC协议的其他接口.....

}
```



## 六、总结

通过本示例，我们实现了：

1. Keycloak 服务器的搭建和配置
2. Spring Boot 应用与 Keycloak 的集成
3. 使用 Spring Security OAuth2 实现身份验证和授权
4. 理解了 Keycloak 与 OAuth2.0 的关系
5. 了解了 OpenID Connect (OIDC) 协议的工作原理和应用场景
6. 实现了用户身份验证、令牌获取、用户信息获取和退出等接口
7. 实现了多租户多客户端支持

这种集成方式提供了一种安全、标准的身份管理解决方案，适用于各种企业应用场景，特别是需要多租户支持的 SaaS 应用。




#### 资源获取：

本文完整代码已上传至 GitHub，欢迎 Star ⭐ 和 Fork

- Github地址：https://github.com/rstyro/Springboot/tree/master/springboot-keycloak

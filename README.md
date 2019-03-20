# nginx-cdn
CentOS一键安装Nginx

### 环境要求
* CentOS 6/7

### 当前版本
* nginx/1.14.2

#### 已编译模块
* --with-stream
* --with-http_stub_status_module
* --with-http_v2_module
* --with-http_ssl_module
* --with-http_gzip_static_module
* --with-http_realip_module
* --with-pcre-jit
* pcre-8.39
* zlib-1.2.11
* openssl-1.1.1
* ngx_http_substitutions_filter_module
* ngx_cache_purge
* ngx_brotli

### 安装
```
wget https://raw.githubusercontent.com/helloxz/nginx-cdn/master/nginx.sh && bash nginx.sh
```

* 如果是CentOS 6的系统，请选择编译安装。
* CentOS 7可选择编译安装或二进制安装。
* 编译安装通常10分钟左右，二进制安装通常2分钟左右。

### 常用命令
安装完成后执行命令 `source /etc/profile` 让环境变量立即生效，或重新打开终端。
* 启动nginx：`nginx`
* 停止nginx：`nginx -s stop`
* 重载nginx：`nginx -s reload`
* 语法检测：`nginx -t`

### 联系我
* Blog: [https://www.xiaoz.me/](https://www.xiaoz.me/)
* QQ: 337003006
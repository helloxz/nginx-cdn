#!/bin/bash
############### CentOS一键安装Nginx脚本 ###############
#Author:xiaoz.me
#Update:2019-03-20
####################### END #######################

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/bin:/sbin
export PATH

dir='/usr/local/'
#定义nginx版本
nginx_version='1.18'
#定义openssl版本
openssl_version='1.1.1g'
#定义pcre版本
pcre_version='8.43'
#对系统进行判断
function check_os(){
	#CentOS
	if test -e "/etc/redhat-release"
		then
		yum -y install gcc gcc-c++ perl unzip
	#Debian
	elif test -e "/etc/debian_version"
		then
		apt-get -y install perl unzip
		apt-get -y install build-essential
	else
		echo "当前系统不支持！"
	fi
}
#获取服务器公网IP
function get_ip(){
	osip=$(curl -4s https://api.ip.sb/ip)
	echo $osip
}
#防火墙放行端口
function chk_firewall(){
	if [ -e "/etc/sysconfig/iptables" ]
	then
		iptables -I INPUT -p tcp --dport 80 -j ACCEPT
		iptables -I INPUT -p tcp --dport 443 -j ACCEPT
		service iptables save
		service iptables restart
	else
		firewall-cmd --zone=public --add-port=80/tcp --permanent 
		firewall-cmd --zone=public --add-port=443/tcp --permanent 
		firewall-cmd --reload
	fi
}
#防火墙删除端口
function DelPort(){
	if [ -e "/etc/sysconfig/iptables" ]
	then
		sed -i '/^.*80/d' /etc/sysconfig/iptables
		sed -i '/^.*443/d' /etc/sysconfig/iptables
		service iptables save
		service iptables restart
	else
		firewall-cmd --zone=public --remove-port=80/tcp --permanent
		firewall-cmd --zone=public --remove-port=443/tcp --permanent
		firewall-cmd --reload
	fi
}
#安装jemalloc优化内存管理
function jemalloc(){
	wget http://soft.xiaoz.org/linux/jemalloc-5.2.0.tgz
	tar -zxvf jemalloc-5.2.0.tgz
	cd jemalloc-5.2.0
	./configure
	make && make install
	echo '/usr/local/lib' > /etc/ld.so.conf.d/local.conf
	ldconfig
}
#安装依赖环境
function depend(){
	#安装pcre
	cd ${dir}
	wget --no-check-certificate https://ftp.pcre.org/pub/pcre/pcre-${pcre_version}.tar.gz
	tar -zxvf pcre-${pcre_version}.tar.gz
	cd pcre-${pcre_version}
	./configure
	make -j4 && make -j4 install
	#安装zlib
	cd ${dir}
	wget http://soft.xiaoz.org/linux/zlib-1.2.11.tar.gz
	tar -zxvf zlib-1.2.11.tar.gz
	cd zlib-1.2.11
	./configure
	make -j4 && make -j4 install
	#安装openssl
	cd ${dir}
	wget --no-check-certificate -O openssl.tar.gz https://www.openssl.org/source/openssl-${openssl_version}.tar.gz
	tar -zxvf openssl.tar.gz
	cd openssl-${openssl_version}
	./config
	make -j4 && make -j4 install
}

#安装服务
function install_service(){
	if [ -d "/etc/systemd/system" ]
	then
		wget -P /etc/systemd/system https://raw.githubusercontent.com/helloxz/nginx-cdn/master/nginx.service
		systemctl daemon-reload
		systemctl enable nginx
	fi
}

#编译安装Nginx
function CompileInstall(){
	#创建用户和用户组
	groupadd www
	useradd -M -g www www -s /sbin/nologin
	
	#rm -rf /usr/local/pcre-8.39.tar.gz
	#rm -rf /usr/local/zlib-1.2.11.tar.gz
	#rm -rf /usr/local/openssl-1.1.0h.tar.gz

	#下载stub_status_module模块
	cd /usr/local

	### 2020/11/09 此模块暂不使用
	#wget http://soft.xiaoz.org/nginx/ngx_http_substitutions_filter_module.zip
	#unzip ngx_http_substitutions_filter_module.zip

	#下载purecache模块
	cd /usr/local && wget http://soft.xiaoz.org/nginx/ngx_cache_purge-2.3.tar.gz
	tar -zxvf ngx_cache_purge-2.3.tar.gz
	mv ngx_cache_purge-2.3 ngx_cache_purge

	#下载brotli
	wget http://soft.xiaoz.org/nginx/ngx_brotli.tar.gz
	tar -zxvf ngx_brotli.tar.gz

	#安装Nginx
	cd /usr/local
	wget https://wget.ovh/nginx/xcdn-${nginx_version}.tar.gz
	tar -zxvf xcdn-${nginx_version}.tar.gz
	cd xcdn-${nginx_version}
	./configure --prefix=/usr/local/nginx --user=www --group=www \
	--with-stream \
	--with-http_stub_status_module \
	--with-http_v2_module \
	--with-http_ssl_module \
	--with-http_gzip_static_module \
	--with-http_realip_module \
	--with-http_slice_module \
	--with-http_image_filter_module \
	--with-pcre=../pcre-${pcre_version} \
	--with-pcre-jit \
	--with-zlib=../zlib-1.2.11 \
	--with-openssl=../openssl-${openssl_version} \
	--add-module=../ngx_cache_purge \
	--add-module=../ngx_brotli
	make -j4 && make -j4 install

	#一点点清理工作
	rm -rf ${dir}xcdn-1.*
	rm -rf ${dir}zlib-1.*
	rm -rf ${dir}pcre-8.*
	rm -rf ${dir}openssl*
	#rm -rf ${dir}ngx_http_substitutions_filter_module*
	rm -rf ${dir}ngx_cache_purge*
	rm -rf ${dir}ngx_brotli*
	rm -rf nginx.tar.gz
	rm -rf nginx.1
	cd
	rm -rf jemalloc*

	#复制配置文件
	mv /usr/local/nginx/conf/nginx.conf /usr/local/nginx/conf/nginx.conf.bak
	wget --no-check-certificate https://raw.githubusercontent.com/helloxz/nginx-cdn/master/nginx.conf -P /usr/local/nginx/conf/
	#日志分割
	wget --no-check-certificate https://raw.githubusercontent.com/helloxz/nginx-cdn/master/etc/logrotate.d/nginx -P /etc/logrotate.d/
	mkdir -p /usr/local/nginx/conf/vhost
	mkdir -p /usr/local/nginx/conf/cdn
	/usr/local/nginx/sbin/nginx

	#环境变量与服务
	echo "export PATH=$PATH:/usr/local/nginx/sbin" >> /etc/profile
	export PATH=$PATH:'/usr/local/nginx/sbin'

	#安装服务
	install_service
	#echo "/usr/local/nginx/sbin/nginx" >> /etc/rc.d/rc.local
	#chmod +x /etc/rc.d/rc.local
	echo "------------------------------------------------"
	echo "XCDN installed successfully. Please visit the http://${osip}"
}

#二进制安装Nginx
function BinaryInstall(){
	#创建用户和用户组
	groupadd www
	useradd -M -g www www -s /sbin/nologin

	#下载到指定目录
	wget http://soft.xiaoz.org/nginx/xcdn-binary-${nginx_version}.tar.gz -O /usr/local/nginx.tar.gz

	#解压
	cd /usr/local && tar -zxvf nginx.tar.gz

	#日志自动分割
	wget --no-check-certificate https://raw.githubusercontent.com/helloxz/nginx-cdn/master/etc/logrotate.d/nginx -P /etc/logrotate.d/

	#环境变量
	echo "export PATH=$PATH:/usr/local/nginx/sbin" >> /etc/profile
	export PATH=$PATH:'/usr/local/nginx/sbin'

	#启动
	/usr/local/nginx/sbin/nginx
	#安装服务
	install_service
	#开机自启
	#echo "/usr/local/nginx/sbin/nginx" >> /etc/rc.d/rc.local
	#chmod +x /etc/rc.d/rc.local

	echo "------------------------------------------------"
	echo "XCDN installed successfully. Please visit the http://${osip}"
}

#卸载Nginx
function uninstall(){
	# 杀掉nginx进程
	pkill nginx
	#删除www用户
	userdel www && groupdel www 
	#备份一下配置
	cp -a /usr/local/nginx/conf/vhost /home/vhost_bak
	#删除目录
	rm -rf /usr/local/nginx
	sed -i "s%:/usr/local/nginx/sbin%%g" /etc/profile
	#删除自启
    sed -i '/^.*nginx/d' /etc/rc.d/rc.local
    #删除日志分割
    rm -rf /etc/logrotate.d/nginx
}

#选择安装方式
echo "------------------------------------------------"
echo "欢迎使用Nginx一键安装脚本^_^，请先选择安装方式："
echo "1) 编译安装，支持CentOS 6/7"
echo "2) 二进制安装，支持CentOS 7"
echo "3) 卸载Nginx"
echo "q) 退出！"
read -p ":" istype

case $istype in
    1) 
    	check_os
    	get_ip
    	chk_firewall
    	#安装jemalloc
    	#jemalloc,2020/11/09暂时去掉jemalloc
    	#安装依赖
    	depend
    	#安装nginx
    	CompileInstall
    ;;
    2) 
    	check_os
    	get_ip
    	chk_firewall
    	#安装jemalloc
    	#jemalloc，2020/11/09暂时去掉jemalloc
    	BinaryInstall
    ;;
    3) 
    	#执行卸载函数
    	uninstall
    	#删除端口
    	DelPort
    	echo 'Uninstall complete.'
    ;;
    q) 
    	exit
    ;;
    *) echo '参数错误！'
esac
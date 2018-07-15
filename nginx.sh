#!/bin/bash
############### CentOS一键安装Nginx脚本 ###############
#Author:xiaoz.me
#Update:2018-07-14
####################### END #######################

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin
export PATH

dir='/usr/local/'

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
	osip=$(curl https://ip.awk.sh/api.php?data=ip)
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

#编译安装Nginx
function CompileInstall(){
	#创建用户和用户组
	groupadd www
	useradd -M -g www www -s /sbin/nologin
	#安装pcre
	#$setupf -y install gcc gcc-c++ perl unzip
	cd /usr/local
	wget http://soft.xiaoz.org/linux/pcre-8.39.tar.gz
	tar -zxvf pcre-8.39.tar.gz
	cd pcre-8.39
	./configure
	make -j4 && make -j4 install
	rm -rf /usr/local/pcre-8.39.tar.gz

	#安装zlib
	cd /usr/local
	wget http://soft.xiaoz.org/linux/zlib-1.2.11.tar.gz
	tar -zxvf zlib-1.2.11.tar.gz
	cd zlib-1.2.11
	./configure
	make -j4 && make -j4 install
	rm -rf /usr/local/zlib-1.2.11.tar.gz

	#安装openssl
	cd /usr/local
	wget http://soft.xiaoz.org/linux/openssl-1.1.0h.tar.gz
	tar -zxvf openssl-1.1.0h.tar.gz
	cd openssl-1.1.0h
	./config
	make -j4 && make -j4 install
	rm -rf /usr/local/openssl-1.1.0h.tar.gz

	#下载stub_status_module
	cd /usr/local
	wget http://soft.xiaoz.org/nginx/ngx_http_substitutions_filter_module.zip
	unzip ngx_http_substitutions_filter_module.zip
	rm -rf /usr/local/ngx_http_substitutions_filter_module.zip

	#下载purecache模块
	cd /usr/local && wget http://soft.xiaoz.org/nginx/ngx_cache_purge-2.3.tar.gz
	tar -zxvf ngx_cache_purge-2.3.tar.gz
	mv ngx_cache_purge-2.3 ngx_cache_purge
	rm -rf ngx_cache_purge-2.3.tar.gz

	#安装Nginx
	cd /usr/local
	wget http://nginx.org/download/nginx-1.14.0.tar.gz
	tar -zxvf nginx-1.14.0.tar.gz
	cd nginx-1.14.0
	./configure --prefix=/usr/local/nginx --user=www --group=www --with-stream --with-http_stub_status_module --with-http_v2_module --with-http_ssl_module --with-http_gzip_static_module --with-http_realip_module --with-pcre=/usr/local/pcre-8.39 --with-pcre-jit --with-zlib=/usr/local/zlib-1.2.11 --with-openssl=/usr/local/openssl-1.1.0h --add-module=/usr/local/ngx_http_substitutions_filter_module --add-module=/usr/local/ngx_cache_purge
	make -j4 && make -j4 install

	#一点点清理工作
	rm -rf ${dir}nginx-1.14.0*
	rm -rf ${dir}zlib-1.2.11
	rm -rf ${dir}pcre-8.39
	rm -rf ${dir}openssl-1.1.0h
	rm -rf ${dir}ngx_http_substitutions_filter_module
	rm -rf ${dir}ngx_cache_purge

	#复制配置文件
	mv /usr/local/nginx/conf/nginx.conf /usr/local/nginx/conf/nginx.conf.bak
	wget https://raw.githubusercontent.com/helloxz/nginx-cdn/master/nginx.conf -P /usr/local/nginx/conf/
	mkdir -p /usr/local/nginx/conf/vhost
	/usr/local/nginx/sbin/nginx

	#环境变量与服务
	echo "export PATH=$PATH:/usr/local/nginx/sbin" >> /etc/profile
	export PATH=$PATH:'/usr/local/nginx/sbin'

	#开机自启
	echo "/usr/local/nginx/sbin/nginx" >> /etc/rc.d/rc.local

	echo "Nginx installed successfully. Please visit the http://${osip}"
}

#二进制安装Nginx
function BinaryInstall(){
	#创建用户和用户组
	groupadd www
	useradd -M -g www www -s /sbin/nologin

	#下载到指定目录
	wget http://soft.xiaoz.org/nginx/nginx-binary-1.14.0.tar.gz -P /usr/local

	#解压
	cd /usr/local && tar -zxvf nginx-binary-1.14.0.tar.gz

	#环境变量
	echo "export PATH=$PATH:/usr/local/nginx/sbin" >> /etc/profile
	export PATH=$PATH:'/usr/local/nginx/sbin'

	#启动
	/usr/local/nginx/sbin/nginx
	#开机自启
	echo "/usr/local/nginx/sbin/nginx" >> /etc/rc.d/rc.local

	echo "------------------------------------------------"
	echo "Nginx installed successfully. Please visit the http://${osip}"
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
    	CompileInstall
    ;;
    2) 
    	check_os
    	get_ip
    	chk_firewall
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
#!/bin/bash
############### 一键安装Nginx脚本 ###############
#Author:xiaoz.me
#Update:2017-04-07
####################### END #######################

#对系统进行判断
function check_os(){
	#CentOS
	if test -e "/etc/redhat-release"
		then
		yum -y install gcc gcc-c++ perl unzip
	#Ubuntu
	#elif test -e "/etc/lsb-release"
	#	then
	#	apt-get -y install perl unzip
	#	apt-get -y install build-essential
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
	osip=$(curl http://https.tn/ip/myip.php?type=onlyip)
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

check_os
get_ip
chk_firewall

#创建用户和用户组
groupadd www
useradd -g www www
#安装pcre
#$setupf -y install gcc gcc-c++ perl unzip
cd /usr/local
wget http://soft.hixz.org/linux/pcre-8.39.tar.gz
tar -zxvf pcre-8.39.tar.gz
cd pcre-8.39
./configure
make 
make install
rm -rf /usr/local/pcre-8.39.tar.gz

#安装zlib
cd /usr/local
wget https://soft.hixz.org/linux/zlib-1.2.11.tar.gz
tar -zxvf zlib-1.2.11.tar.gz
cd zlib-1.2.11
./configure
make
make install
rm -rf /usr/local/zlib-1.2.11.tar.gz

#安装openssl
cd /usr/local
wget https://soft.hixz.org/linux/openssl-1.1.0e.tar.gz
tar -zxvf openssl-1.1.0e.tar.gz
cd openssl-1.1.0e
./config
make 
make install
rm -rf /usr/local/openssl-1.1.0e.tar.gz

#下载stub_status_module
cd /usr/local
wget https://soft.hixz.org/nginx/ngx_http_substitutions_filter_module.zip
tar -zxvf ngx_http_substitutions_filter_module.zip
#安装unzip
unzip ngx_http_substitutions_filter_module.zip
rm -rf /usr/local/ngx_http_substitutions_filter_module.zip

#安装Nginx
cd /usr/local
wget https://soft.hixz.org/linux/nginx-1.10.3.tar.gz
tar -zxvf nginx-1.10.3.tar.gz
cd nginx-1.10.3
./configure --prefix=/usr/local/nginx --user=www --group=www --with-http_stub_status_module --with-http_v2_module --with-http_ssl_module --with-http_gzip_static_module --with-http_realip_module --with-pcre=/usr/local/pcre-8.39 --with-pcre-jit --with-zlib=/usr/local/zlib-1.2.11 --with-openssl=/usr/local/openssl-1.1.0e --add-module=/usr/local/ngx_http_substitutions_filter_module
make
make install

#复制配置文件
mv /usr/local/nginx/conf/nginx.conf /usr/local/nginx/conf/nginx.conf.bak
wget http://soft.hixz.org/nginx/nginx.conf -P /usr/local/nginx/conf/
mkdir -p /usr/local/nginx/conf/vhost
/usr/local/nginx/sbin/nginx

#环境变量与服务
echo "export PATH=$PATH:/usr/local/nginx/sbin" >> /etc/profile
export PATH=$PATH:'/usr/local/nginx/sbin'
wget http://soft.hixz.org/nginx/nginx -P /etc/init.d
chmod u+x /etc/init.d/nginx

echo "Nginx installed successfully. Please visit the http://${osip}"
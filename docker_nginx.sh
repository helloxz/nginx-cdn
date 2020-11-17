#!/bin/bash
############### Debian一键安装Nginx脚本 ###############
#Author:xiaoz.me
#Update:2020-11-15
#Github:https://github.com/helloxz/nginx-cdn
####################### END #######################

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/bin:/sbin
export PATH

#安装依赖
function depend(){
	apt-get -y update
	apt-get -y install curl wget libmaxminddb-dev libgd-dev cron
}


#二进制安装Nginx
function BinaryInstall(){
	#创建用户和用户组
	groupadd www
	useradd -M -g www www -s /sbin/nologin
	#创建数据目录，用于存储站点数据、缓存目录、ssl证书
	mkdir -p /data
	chown -R www:www /data

	#下载到指定目录
	wget http://soft.xiaoz.org/nginx/xcdn-binary-1.18-debian.tar.gz -O /usr/local/nginx.tar.gz

	#解压
	cd /usr/local && tar -zxvf nginx.tar.gz

	#日志自动分割
	wget --no-check-certificate https://raw.githubusercontent.com/helloxz/nginx-cdn/master/etc/logrotate.d/nginx -P /etc/logrotate.d/
	#替换日志分割路径
	sed -i 's%/data/wwwlogs/*nginx.log%/usr/local/nginx/logs/*.log%g' /etc/logrotate.d/nginx

	#环境变量
	echo "export PATH=$PATH:/usr/local/nginx/sbin" >> /etc/profile
	export PATH=$PATH:'/usr/local/nginx/sbin'

	#启动
	#/usr/local/nginx/sbin/nginx
	#给docker启动脚本添加执行权限
	chmod +x /usr/sbin/run.sh
	#计划任务
	echo '*/1 * * * * /usr/sbin/run.sh autoreload >> /dev/null' >> /var/spool/cron/crontabs/root
	#开机自启
	#echo "/usr/local/nginx/sbin/nginx" >> /etc/rc.d/rc.local
	#chmod +x /etc/rc.d/rc.local

	echo "------------------------------------------------"
	echo "XCDN installed successfully."
	echo "------------------------------------------------"
}
#收尾工作
function finishing(){
	#清理nginx二进制文件
	rm -rf /usr/local/nginx.tar.gz
}
#安装依赖
depend
#执行安装
BinaryInstall
finishing
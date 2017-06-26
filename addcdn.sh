#!/bin/bash


function http_cdn{
	read -p "请输入域名(www.xiaoz.me):" domain
	read -p "请填写回源IP(192.168.0.1):" sourceip
	read -p "设置全局缓存时间(0-60min):" cache_time
	cache_name=${domain%%\.%%_}
}

read -p "请选择" mysite
echo "1.HTTP"
echo "2.HTTPS"
echo "3.退出"

case $mysite in
	1) 
	http_cdn
	echo "输入的域名:${domain}"
	echo "回源ip:${sourceip}"
	echo "缓存时间:${cache_time}"
	echo "缓存目录:/data/wwwroot/caches/${domain}"
	echo "缓存名字:${cache_name}"
	::
	2) echo ''
	::
	*) echo '只能选择1-4'
	::
esac
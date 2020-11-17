#!/bin/bash


#自动重载
if [ ${1}x == 'autoreload'x ]
	then
		find /usr/local/nginx/conf/cdn -mmin 1 -exec "/usr/local/nginx/sbin/nginx -t && /usr/local/nginx/sbin/nginx" -s reload {} \;
		find /usr/local/nginx/conf/vhost -mmin 1 -exec "/usr/local/nginx/sbin/nginx -t && /usr/local/nginx/sbin/nginx" -s reload {} \;
	elif [ ${1}x == 'reload'x ]
	then
		/usr/local/nginx/sbin/nginx -t && /usr/local/nginx/sbin/nginx -s reload
	elif [ ${1}x == 'stop'x ]
	then
		/usr/local/nginx/sbin/nginx -t && /usr/local/nginx/sbin/nginx -s stop
	elif [ ${1}x == 'start'x ]
	then
		/usr/local/nginx/sbin/nginx
	elif [ -z $1 ]
	then
		#启动nginx
		/usr/local/nginx/sbin/nginx
		#启动cron
		cron -n
		tail -f /usr/local/nginx/logs/error.log
fi
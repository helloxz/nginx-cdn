#!/bin/bash


#自动重载
if [ $1 == 'autoreload' ]
	then
		find /usr/local/nginx/conf/cdn -mmin 1 -exec /usr/local/nginx/sbin/nginx -t && /usr/local/nginx/sbin/nginx -s reload {} \;
		find /usr/local/nginx/conf/vhost -mmin 1 -exec /usr/local/nginx/sbin/nginx -t && /usr/local/nginx/sbin/nginx -s reload {} \;
	elif [ $1 == 'reload' ]
		/usr/local/nginx/sbin/nginx -t && /usr/local/nginx/sbin/nginx -s reload
	elif [ $1 == 'stop' ]
		/usr/local/nginx/sbin/nginx -t && /usr/local/nginx/sbin/nginx -s stop
	elif [ $1 == 'start' ]
		/usr/local/nginx/sbin/nginx
	else
		#启动nginx
		/usr/local/nginx/sbin/nginx
		#启动cron
		cron -n
		tail -f /usr/local/nginx/logs/error.log
fi
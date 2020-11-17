#基于哪个镜像制作
FROM debian:stable-slim
#设置时区
ENV TZ=Asia/Shanghai
#工作目录
WORKDIR /root
#复制安装脚本
COPY ./docker_nginx.sh /root
#复制启动脚本
COPY ./run.sh /usr/sbin
#执行安装脚本
RUN bash docker_nginx.sh
#暴露站点文件夹
VOLUME /data
#暴露配置文件
VOLUME /usr/local/nginx/conf/vhost
VOLUME /usr/local/nginx/conf/cdn
#暴露日志文件夹
VOLUME /usr/local/nginx/logs
#暴露配置文件
#VOLUME /usr/local/nginx/conf/nginx.conf
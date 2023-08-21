FROM debian:buster

LABEL Maintainer="Wangzd <wangzhoudong@liweijia.com>" \
      Description="Nginx 1.16 & PHP-FPM 7.4 based on debian Linux .  "

ENV LANG=C.UTF-8
ENV TIMEZONE Asia/Shanghai
ENV PHP_MEMORY_LIMIT 256M
ENV MAX_UPLOAD 50M
ENV PHP_MAX_FILE_UPLOAD 200
ENV PHP_MAX_POST 100M
ENV DD_AGENT_HOST 127.0.0.1
ENV DD_TRACE_AGENT_PORT 9529
ENV DD_SERVICE lwj-php-api
ENV DD_ENV prod
ENV DD_VERSION 1.0.0
ENV PHP_CONF /etc/php/7.4/fpm/php.ini
ENV FPM_CONF /etc/php/7.4/fpm/pool.d/www.conf

RUN cp /etc/apt/sources.list /etc/apt/sources.listbak
RUN rm -f /etc/apt/sources.list
RUN echo "deb http://mirrors.aliyun.com/debian/ buster main non-free contrib \n \
deb-src http://mirrors.aliyun.com/debian/ buster main non-free contrib \n \
deb http://mirrors.aliyun.com/debian-security buster/updates main \n \
deb-src http://mirrors.aliyun.com/debian-security buster/updates main \n \
deb http://mirrors.aliyun.com/debian/ buster-updates main non-free contrib \n \
deb-src http://mirrors.aliyun.com/debian/ buster-updates main non-free contrib \n \
deb http://mirrors.aliyun.com/debian/ buster-backports main non-free contrib \n \
deb-src http://mirrors.aliyun.com/debian/ buster-backports main non-free contrib" > /etc/apt/sources.list

# Install Basic Requirements
RUN buildDeps='curl gcc make autoconf libc-dev zlib1g-dev pkg-config' \
    && set -x \
    && apt-get update \
    && apt-get install --no-install-recommends $buildDeps --no-install-suggests -q -y gnupg2 dirmngr wget apt-transport-https lsb-release ca-certificates \
    && wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg \
    && echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list \
    && apt-get update \
    && apt-get install --no-install-recommends --no-install-suggests -q -y \
            apt-utils \
            cron \
            nginx \
            vim \
            zip \
            unzip \
            python-pip \
            python-setuptools \
            libmemcached-dev \
            libmemcached11 \
            libmagickwand-dev \
            php7.4-fpm \
            php7.4-cli \
            php7.4-bcmath \
            php7.4-dev \
            php7.4-common \
            php7.4-json \
            php7.4-opcache \
            php7.4-readline \
            php7.4-mbstring \
            php7.4-curl \
            php7.4-gd \
            php7.4-imagick \
            php7.4-mysql \
            php7.4-zip \
            php7.4-pgsql \
            php7.4-intl \
            php7.4-xml \
            php7.4-xmlwriter \
            php-pear \
    && pecl -d php_suffix=7.4 install -o -f redis memcached \
    && mkdir -p /run/php \
    && pip install wheel \
    && pip install supervisor supervisor-stdout \
    && echo "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d \
    && rm -rf /etc/nginx/conf.d/default.conf \
    && echo "extension=redis.so" > /etc/php/7.4/mods-available/redis.ini \
    && echo "extension=memcached.so" > /etc/php/7.4/mods-available/memcached.ini \
    && ln -sf /etc/php/7.4/mods-available/redis.ini /etc/php/7.4/fpm/conf.d/20-redis.ini \
    && ln -sf /etc/php/7.4/mods-available/redis.ini /etc/php/7.4/cli/conf.d/20-redis.ini \
    && ln -sf /etc/php/7.4/mods-available/memcached.ini /etc/php/7.4/fpm/conf.d/20-memcached.ini \
    && ln -sf /etc/php/7.4/mods-available/memcached.ini /etc/php/7.4/cli/conf.d/20-memcached.ini \
    # Clean up
    && rm -rf /tmp/pear \
    && apt-get purge -y --auto-remove $buildDeps \
    && apt-get clean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/*


#vim 中文乱码问题
RUN echo ":set encoding=utf-8" >> /root/.vimrc && \
    echo ":set fileencodings=utf-8" >> /root/.vimrc && \
    echo ":set termencoding=utf-8" >> /root/.vimrc
#system config
COPY config/00-sysctl.conf  /etc/sysctl.d/00-sysctl.conf
RUN cat /etc/sysctl.d/00-sysctl.conf >> /etc/sysctl.conf


# Supervisor config
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY config/supervisord.conf /etc/supervisord.conf

# Configure PHP-FPM
RUN rm -rf ${FPM_CONF}
COPY config/php-fpm.d/default.conf ${FPM_CONF}
COPY config/php-fpm.d /usr/local/etc/php-fpm.d.defualt

RUN sed -i "s|;date.timezone =.*|date.timezone = ${TIMEZONE}|" ${PHP_CONF} && \
    sed -i "s|memory_limit =.*|memory_limit = ${PHP_MEMORY_LIMIT}|" ${PHP_CONF} && \
    sed -i "s|upload_max_filesize =.*|upload_max_filesize = ${MAX_UPLOAD}|" ${PHP_CONF} && \
    sed -i "s|max_file_uploads =.*|max_file_uploads = ${PHP_MAX_FILE_UPLOAD}|" ${PHP_CONF} && \
    sed -i "s|post_max_size =.*|post_max_size = ${PHP_MAX_POST}|" ${PHP_CONF} && \
    sed -i "s|expose_php =.*|expose_php = Off|" ${PHP_CONF} && \
    sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" ${PHP_CONF} && \
    sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" ${PHP_CONF}

# Configure nginx
RUN rm -rf /etc/nginx/conf.d/default.conf
COPY config/nginx.conf /etc/nginx/nginx.conf
COPY config/site-default.conf /etc/nginx/conf.d/default.conf

#兼容之前单独安装的环境
RUN ln -s /usr/bin/php7.4 /usr/local/bin/php  \
    && ln -s /usr/sbin/php-fpm7.4 /usr/local/sbin/php-fpm  \
    && mkdir -p /usr/local/etc/php/  \
    && ln -s /etc/php/7.4/fpm/php.ini /usr/local/etc/php/php.ini  \
    && mkdir -p /usr/local/etc/php-fpm.d/  \
    && ln -s /etc/php/7.4/fpm/pool.d/www.conf /usr/local/etc/php-fpm.d/www.conf


# Add application
RUN mkdir -p /run/nginx  \
    && mkdir -p /var/www/html  \
    && rm -rf /var/www/html/* && \
    echo "<?php phpinfo();" > /var/www/html/index.php

ADD scripts/fpm-conf.sh /fpm-conf
RUN chmod 755 /fpm-conf
# Add user group and user devops
RUN groupadd -g 1000 devops \
    && useradd -m -d /var/www/html -u 1000 -g devops devops \
    &&chown -R devops:devops /var/www \
    && chown -R devops:devops /run \
    && chown -R devops:devops /var/lib/nginx \
    && chown -R devops:devops /var/log/nginx

WORKDIR /var/www/html

#USER devops
EXPOSE 80 443
CMD ["/usr/local/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

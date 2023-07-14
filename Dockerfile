FROM php:7.4-fpm

LABEL Maintainer="Wangzd <wangzhoudong@liweijia.com>" \
      Description="Nginx 1.16 & PHP-FPM 7.4 based on debian Linux .  "

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

RUN cp /etc/apt/sources.list /etc/apt/sources.listbak
RUN rm -f /etc/apt/sources.list
RUN echo "deb https://mirrors.aliyun.com/debian/ bullseye main non-free contrib \n \
deb-src https://mirrors.aliyun.com/debian/ bullseye main non-free contrib \n \
deb https://mirrors.aliyun.com/debian-security/ bullseye-security main \n \
deb-src https://mirrors.aliyun.com/debian-security/ bullseye-security main \n \
deb https://mirrors.aliyun.com/debian/ bullseye-updates main non-free contrib \n \
deb-src https://mirrors.aliyun.com/debian/ bullseye-updates main non-free contrib \n \
deb https://mirrors.aliyun.com/debian/ bullseye-backports main non-free contrib \n \
deb-src https://mirrors.aliyun.com/debian/ bullseye-backports main non-free contrib" > /etc/apt/sources.list


#RUN echo deb http://ftp.cn.debian.org/debian/ buster main > /etc/apt/sources.list
#RUN echo deb http://ftp.cn.debian.org/debian/ buster-updates main >> /etc/apt/sources.list
#RUN echo deb http://ftp.cn.debian.org/debian-security buster/updates main >> /etc/apt/sources.list

RUN apt-get update -y
RUN apt-get -y install gcc make autoconf libc-dev pkg-config libzip-dev

RUN apt-get install -y --no-install-recommends \
	git wget supervisor nginx  \
	libmemcached-dev \
	libz-dev \
	libpq-dev \
	libssl-dev libssl-doc libsasl2-dev \
	libmcrypt-dev \
	libxml2-dev \
	zlib1g-dev libicu-dev g++ \
	libldap2-dev libbz2-dev \
	curl libcurl4-openssl-dev \
	libenchant-2-dev libgmp-dev firebird-dev libib-util \
	re2c libpng++-dev \
	libwebp-dev libjpeg-dev libjpeg62-turbo-dev libpng-dev libvpx-dev libfreetype6-dev \
	libmagick++-dev \
	libmagickwand-dev \
	zlib1g-dev libgd-dev \
	libtidy-dev libxslt1-dev libmagic-dev libexif-dev file \
	sqlite3 libsqlite3-dev libxslt-dev \
	libmhash2 libmhash-dev libc-client-dev libkrb5-dev libssh2-1-dev \
	unzip libpcre3 libpcre3-dev \
	poppler-utils ghostscript libmagickwand-6.q16-dev libsnmp-dev libedit-dev libreadline6-dev libsodium-dev \
	freetds-bin freetds-dev freetds-common libct4 libsybdb5 tdsodbc libreadline-dev librecode-dev libpspell-dev libonig-dev

# fix for docker-php-ext-install pdo_dblib
# https://stackoverflow.com/questions/43617752/docker-php-and-freetds-cannot-find-freetds-in-know-installation-directories
RUN ln -s /usr/lib/x86_64-linux-gnu/libsybdb.so /usr/lib/

#RUN docker-php-ext-configure hash --with-mhash && docker-php-ext-install hash

RUN docker-php-ext-configure imap --with-kerberos --with-imap-ssl && \
	docker-php-ext-install imap iconv

RUN docker-php-ext-install bcmath bz2 calendar ctype curl dba dom
RUN docker-php-ext-install fileinfo exif ftp gettext gmp
RUN docker-php-ext-install intl json ldap mbstring mysqli
RUN docker-php-ext-install opcache pcntl pspell
RUN docker-php-ext-install pdo pdo_dblib pdo_mysql pdo_pgsql pdo_sqlite pgsql phar posix
RUN docker-php-ext-install session shmop simplexml soap sockets sodium
RUN docker-php-ext-install sysvmsg sysvsem sysvshm
# RUN docker-php-ext-install snmp

# fix for docker-php-ext-install xmlreader
# https://github.com/docker-library/php/issues/373
RUN export CFLAGS="-I/usr/src/php" && docker-php-ext-install xmlreader xmlwriter xml xmlrpc xsl

RUN docker-php-ext-install tidy tokenizer  zip

# already build in... what they say...
# RUN docker-php-ext-install filter reflection spl standard
# RUN docker-php-ext-install pdo_firebird pdo_oci

# install pecl extension
RUN pecl install ds && \
	pecl install imagick && \
	pecl install igbinary && \
	pecl install redis && \
	pecl install memcached && \
	pecl install xlswriter && \
	docker-php-ext-enable ds imagick igbinary redis memcached xlswriter

# https://serverpilot.io/docs/how-to-install-the-php-ssh2-extension
# 	pecl install ssh2-1.1.2 && \
# docker-php-ext-enable ssh2

# install pecl extension
RUN pecl install mongodb && docker-php-ext-enable mongodb

# install xdebug
# RUN pecl install xdebug && docker-php-ext-enable xdebug

RUN yes "" | pecl install msgpack && \
	docker-php-ext-enable msgpack

# install APCu
RUN pecl install apcu && \
	docker-php-ext-enable apcu --ini-name docker-php-ext-10-apcu.ini

RUN apt-get update -y && apt-get install -y apt-transport-https locales gnupg

# install MSSQL support and ODBC driver
# RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
# 	curl https://packages.microsoft.com/config/debian/8/prod.list > /etc/apt/sources.list.d/mssql-release.list && \
# 	export DEBIAN_FRONTEND=noninteractive && apt-get update -y && \
# 	ACCEPT_EULA=Y apt-get install -y msodbcsql unixodbc-dev
# RUN set -xe \
# 	&& pecl install pdo_sqlsrv \
# 	&& docker-php-ext-enable pdo_sqlsrv \
# 	&& apt-get purge -y unixodbc-dev && apt-get autoremove -y && apt-get clean

# RUN docker-php-ext-configure spl && docker-php-ext-install spl

# install GD
RUN docker-php-ext-configure \
    gd \
	--with-webp=/usr/include  --with-jpeg=/usr/include --with-freetype=/usr/include \
	&& docker-php-ext-install -j$(nproc) gd


# set locale to utf-8
RUN echo "zh_CN.UTF-8 UTF-8" > /etc/locale.gen && locale-gen
ENV LANG='zh_CN.UTF-8' LANGUAGE='zh_CN:en' LC_ALL='en_US.UTF-8'

#--------------------------------------------------------------------------
# Final Touches
#--------------------------------------------------------------------------

# install required libs for health check
#RUN apt-get -y install libfcgi0ldbl nano htop iotop lsof mariadb-client


# Install composer
#ADD composer.phar /tmp/composer.phar
#RUN chmod +x /tmp/composer.phar     && mv /tmp/composer.phar /usr/local/bin/composer
RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer

#设置时区
RUN cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && \
  echo "${TIMEZONE}" > /etc/timezone


# Configure PHP-FPM
RUN rm -rf /usr/local/etc/php-fpm.d/www.conf
COPY config/php-fpm.d/default.conf /usr/local/etc/php-fpm.d/www.conf
COPY config/php-fpm.d /usr/local/etc/php-fpm.d.defualt

RUN cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini
RUN sed -i "s|;date.timezone =.*|date.timezone = ${TIMEZONE}|" /usr/local/etc/php/php.ini && \
    sed -i "s|memory_limit =.*|memory_limit = ${PHP_MEMORY_LIMIT}|" /usr/local/etc/php/php.ini && \
    sed -i "s|upload_max_filesize =.*|upload_max_filesize = ${MAX_UPLOAD}|" /usr/local/etc/php/php.ini && \
    sed -i "s|max_file_uploads =.*|max_file_uploads = ${PHP_MAX_FILE_UPLOAD}|" /usr/local/etc/php/php.ini && \
    sed -i "s|post_max_size =.*|post_max_size = ${PHP_MAX_POST}|" /usr/local/etc/php/php.ini && \
    sed -i "s|expose_php =.*|expose_php = Off|" /usr/local/etc/php/php.ini && \
    sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /usr/local/etc/php/php.ini && \
    sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /usr/local/etc/php/php.ini

# Add application
RUN mkdir -p /run/nginx
RUN mkdir -p /var/www/html

ADD scripts/fpm-conf.sh /fpm-conf
RUN chmod 755 /fpm-conf

# Clean up
RUN apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
# Add user group and user devops
RUN groupadd -g 1000 devops
RUN adduser -D -u 1000 -G devops devops

RUN mkdir -p /var/www
RUN chown -R devops:devops /var/www
RUN chown -R devops:devops /run
RUN chown -R devops:devops /var/lib/nginx

USER devops
EXPOSE 80 443

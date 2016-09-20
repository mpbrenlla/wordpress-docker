FROM php:7.0.11-fpm-alpine
MAINTAINER Martín Pérez <mpbrenlla@gmail.com>
RUN apk add --no-cache nginx mysql-client supervisor curl bash imagemagick-dev
RUN echo "http://dl-4.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && apk add --no-cache libtool build-base autoconf shadow && docker-php-ext-install -j$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) iconv gd mbstring fileinfo curl xmlreader xmlwriter spl ftp mysqli opcache && pecl install imagick && docker-php-ext-enable imagick && apk del libtool build-base autoconf 
ENV WORKDIR_ROOT /var/www/wp-content

ENV WP_ROOT /usr/src/wordpress
ENV WP_VERSION 4.6.1
ENV WP_SHA1 027e065d30a64720624a7404a1820e6c6fff1202
ENV WP_DOWNLOAD_URL https://wordpress.org/wordpress-$WP_VERSION.tar.gz

RUN curl -o wordpress.tar.gz -SL $WP_DOWNLOAD_URL && echo "$WP_SHA1 *wordpress.tar.gz" | sha1sum -c - && tar -xzf wordpress.tar.gz -C $(dirname $WP_ROOT) && rm wordpress.tar.gz

#RUN adduser -D www-data -s /bin/bash -G www-data

VOLUME $WORKDIR_ROOT
WORKDIR $WORKDIR_ROOT

RUN chown -R www-data:www-data  $WORKDIR_ROOT
RUN usermod -u 1000 www-data
RUN groupmod -g 1000 www-data

COPY wp-config.php $WP_ROOT
RUN chown -R www-data:www-data $WP_ROOT && chmod 640 $WP_ROOT/wp-config.php

#COPY cron.conf /etc/crontabs/deployer
#RUN chmod 600 /etc/crontabs/deployer

COPY nginx.conf /etc/nginx/nginx.conf
COPY vhost.conf /etc/nginx/conf.d/
RUN ln -sf /dev/stdout /var/log/nginx/access.log && ln -sf /dev/stderr /var/log/nginx/error.log && chown -R www-data:www-data /var/lib/nginx

COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT [ "docker-entrypoint.sh" ]

RUN mkdir -p /var/log/supervisor
COPY supervisord.conf /etc/supervisord.conf
COPY stop-supervisor.sh /usr/local/bin/
RUN chmod 700 /usr/local/bin/stop-supervisor.sh

CMD [ "/usr/bin/supervisord", "-c", "/etc/supervisord.conf" ]


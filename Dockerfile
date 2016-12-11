FROM php:7.0.11-fpm-alpine
MAINTAINER Martín Pérez <mpbrenlla@gmail.com>

# add required system dependencies
RUN apk add --no-cache nginx mysql-client supervisor curl bash imagemagick-dev 

# install shadow package for running usermod/groupmod commands in alpine linux
# install php extensions (chaining pattern)
# some php extensions are optional but recommended: opcache
RUN echo "http://dl-4.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && apk add --no-cache libtool build-base autoconf shadow && apk --update add php7-zip  && rm -rf /var/cache/apk/* && docker-php-ext-install -j$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) iconv gd mbstring fileinfo curl xmlreader xmlwriter spl ftp mysqli opcache && pecl install imagick && docker-php-ext-enable imagick && docker-php-ext-install zip && apk del libtool build-base autoconf 


# Wordpress environment variables
# For updating the wordpress version we need to update the SHA1 checksum
ENV WP_ROOT /usr/src/wordpress
ENV WP_VERSION 4.6.1
ENV WP_SHA1 027e065d30a64720624a7404a1820e6c6fff1202
ENV WP_DOWNLOAD_URL https://wordpress.org/wordpress-$WP_VERSION.tar.gz

# Download wordpress, check checksum, extract it and delete the tar.gz
RUN curl -o wordpress.tar.gz -SL $WP_DOWNLOAD_URL && echo "$WP_SHA1 *wordpress.tar.gz" | sha1sum -c - && tar -xzf wordpress.tar.gz -C $(dirname $WP_ROOT) && rm wordpress.tar.gz

# Create a new volume with data we need outside the container
ENV WORKDIR_ROOT /var/www/wp-content
VOLUME $WORKDIR_ROOT
WORKDIR $WORKDIR_ROOT

# www-data is the owner of wordpress folder
RUN chown -R www-data:www-data  $WORKDIR_ROOT

# Fix problem with permissions (by default volume is mounted with 1000 user)
RUN usermod -u 1000 www-data
RUN groupmod -g 1000 www-data

# Generic wp-config.php file that reads environment variables
COPY wp-config.php $WP_ROOT
RUN chown -R www-data:www-data $WP_ROOT && chmod 640 $WP_ROOT/wp-config.php

# Nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf
COPY vhost.conf /etc/nginx/conf.d/
RUN ln -sf /dev/stdout /var/log/nginx/access.log && ln -sf /dev/stderr /var/log/nginx/error.log && chown -R www-data:www-data /var/lib/nginx

# test mysql connection is up for running next commands
COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT [ "docker-entrypoint.sh" ]

# supervisor configuration
RUN mkdir -p /var/log/supervisor
COPY supervisord.conf /etc/supervisord.conf
COPY stop-supervisor.sh /usr/local/bin/
RUN chmod 700 /usr/local/bin/stop-supervisor.sh
CMD [ "/usr/bin/supervisord", "-c", "/etc/supervisord.conf" ]


FROM jkirkby91/ubuntusrvbase:latest

MAINTAINER James Kirkby <jkirkby91@gmail.com>

# Install packages specific to our project
RUN apt-get update && \
apt-get upgrade -y && \
apt-get install php-fpm php-cli php-mysql php-sqlite3 php-curl php-intl php-mcrypt php-xml php-mbstring php-memcached unzip -y --force-yes --fix-missing && \
apt-get remove --purge -y software-properties-common build-essential && \
apt-get autoremove -y && \
apt-get clean && \
apt-get autoclean && \
echo -n > /var/lib/apt/extended_states && \
rm -rf /var/lib/apt/lists/* && \
rm -rf /usr/share/man/?? && \
rm -rf /usr/share/man/??_*

RUN sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=1/g" /etc/php/7.0/fpm/php.ini && \
sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php/7.0/fpm/php.ini && \
sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php/7.0/fpm/php.ini && \
sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.0/fpm/php-fpm.conf && \
sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php/7.0/fpm/pool.d/www.conf && \
sed -i -e "s/pm.max_children = 5/pm.max_children = 9/g" /etc/php/7.0/fpm/pool.d/www.conf && \
sed -i -e "s/pm.start_servers = 2/pm.start_servers = 3/g" /etc/php/7.0/fpm/pool.d/www.conf && \
sed -i -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g" /etc/php/7.0/fpm/pool.d/www.conf && \
sed -i -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 4/g" /etc/php/7.0/fpm/pool.d/www.conf && \
sed -i -e "s/pm.max_requests = 500/pm.max_requests = 200/g" /etc/php/7.0/fpm/pool.d/www.conf && \
sed -i -e "s/;security.limit_extensions = .php .php3 .php4 .php5/security.limit_extensions = .php/g" /etc/php/7.0/fpm/pool.d/www.conf && \
sed -i -e "s|listen = /run/php/php7.0-fpm.sock|listen = 0.0.0.0:9000|g" /etc/php/7.0/fpm/pool.d/www.conf && \
sed -i -e "s|;listen.mode = 0660|listen.mode = 0660|g" /etc/php/7.0/fpm/pool.d/www.conf && \
sed -i -e "s|pid = /run/php/php7.0-fpm.pid|pid = /srv/run/php7.0-fpm.pid|g" /etc/php/7.0/fpm/php-fpm.conf && \
sed -i -e "s|pm = dynamic|pm = ondemand|g" /etc/php/7.0/fpm/php-fpm.conf && \
sed -i -e "s|;opcache.enable=0|;opcache.enable=1|g" /etc/php/7.0/fpm/php.ini && \
sed -i -e "s|;opcache.memory_consumption=64|opcache.memory_consumption=64|g" /etc/php/7.0/fpm/php.ini && \
sed -i -e "s|;opcache.interned_strings_buffer=4|opcache.interned_strings_buffer=8|g" /etc/php/7.0/fpm/php.ini && \
sed -i -e "s|;opcache.max_accelerated_files=2000|opcache.max_accelerated_files=8000|g" /etc/php/7.0/fpm/php.ini && \
sed -i -e "s|;opcache.validate_timestamps=1|opcache.validate_timestamps=2|g" /etc/php/7.0/fpm/php.ini && \
sed -i -e "s|;opcache.revalidate_freq=2|opcache.revalidate_freq=180|g" /etc/php/7.0/fpm/php.ini && \
sed -i -e "s|;opcache.revalidate_path=0|opcache.revalidate_path=0|g" /etc/php/7.0/fpm/php.ini && \
sed -i -e "s|;opcache.fast_shutdown=0|opcache.fast_shutdown=0|g" /etc/php/7.0/fpm/php.ini && \
sed -i -e "s|;opcache.max_file_size=0|opcache.max_file_size=10|g" /etc/php/7.0/fpm/php.ini && \
sed -i -e "s|;opcache.file_cache=|opcache.file_cache=/data/www/.opcache|g" /etc/php/7.0/fpm/php.ini && \
sed -i -e "s|;opcache.file_cache_only=0|opcache.file_cache_only=1|g" /etc/php/7.0/fpm/php.ini && \
sed -i -e "s|;php_admin_value[error_log] = /var/log/fpm-php.www.log|php_admin_value[error_log] = /srv/log/fpm-php.www.log|g" /etc/php/7.0/fpm/php.ini && \
sed -i -e "s|error_log = /var/log/php7.0-fpm.log|error_log = /srv/log/php7.0-fpm.log|g" /etc/php/7.0/fpm/php-fpm.conf

RUN curl -sS https://getcomposer.org/installer -o composer-setup.php

RUN php composer-setup.php --install-dir=/usr/local/bin --filename=composer

RUN mkdir /srv/log && \
mkdir /srv/run

RUN touch /srv/log/php-fpm-stdout.log && \
touch /srv/log/php-fpm-stdout.log && \
touch /srv/log/fpm-php.www.log && \
touch /srv/log/php7.0-fpm.log

COPY confs/apparmor/phpfpm.conf /etc/apparmor.d/phpfpm.conf

RUN service php7.0-fpm start

RUN usermod -u 1000 www-data && \
chown -Rf www-data:www-data /srv && \
chmod 755 /srv

RUN find /srv -type d -exec chmod 755 {} \;  && \
find /srv -type f -exec chmod 644 {} \;

COPY confs/supervisord/supervisord.conf /etc/supervisord.conf

COPY start.sh /start.sh

RUN chmod 777 /start.sh

EXPOSE 9000

WORKDIR /srv/www

RUN chown -Rf www-data:www-data /srv/log/*

USER www-data

CMD ["/bin/bash", "/start.sh"]

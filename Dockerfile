FROM extremeshok/openlitespeed:latest AS BUILD
LABEL mantainer="Adrian Kriel <admin@extremeshok.com>" vendor="eXtremeSHOK.com"
################################################################################
# This is property of eXtremeSHOK.com
# You are free to use, modify and distribute, however you may not remove this notice.
# Copyright (c) Adrian Jon Kriel :: admin@extremeshok.com
################################################################################

USER root

ARG DEBIAN_FRONTEND=noninteractive

RUN echo "**** Install fontconfig ****" \
  && apt-install fontconfig

RUN echo "**** Install PHP7.4 ****" \
  && apt-install \
  lsphp74 \
  lsphp74-dev \
  php-pear \
  php7.4-apcu \
  php7.4-common \
  php7.4-curl \
  php7.4-igbinary \
  php7.4-imagick  \
  php7.4-imap \
  php7.4-intl \
  php7.4-json \
  php7.4-ldap- \
  php7.4-memcached \
  php7.4-msgpack \
  php7.4-mysql \
  php7.4-opcache \
  php7.4-pgsql- \
  php7.4-pspell- \
  php7.4-redis \
  php7.4-snmp- \
  php7.4-sqlite3 \
  php7.4-sybase- \
  php7.4-tidy-
#php7.4-dev \
#php7.4-modules-source- \
## not available for php7.4
# lsphp74-ioncube

RUN echo "**** Default to PHP7.4 and create symbolic links ****" \
  && rm -f /usr/bin/php \
  && rm -f /usr/local/lsws/fcgi-bin/lsphp \
  && ln -s /usr/local/lsws/lsphp74/bin/php /usr/bin/php \
  && ln -s /usr/local/lsws/lsphp74/bin/lsphp /usr/local/lsws/fcgi-bin/lsphp

# RUN echo "**** Create symbolic links for php modules****" \
#   && rm -rf /usr/local/lsws/lsphp74/lib/php/20190902 \
#   && ln -s /usr/lib/php/20190902 /usr/local/lsws/lsphp74/lib/php/20190902

RUN echo "**** Copy php modules****" \
  && cp -f /usr/lib/php/20190902/* /usr/local/lsws/lsphp74/lib/php/20190902/

RUN echo "**** MSMTP ****" \
  && apt-install msmtp

RUN echo "**** Create symbolic links for /etc/php ****" \
  && rm -rf /etc/php \
  && mkdir -p /etc/php \
  && rm -rf /usr/local/lsws/lsphp74/etc/php/7.4 \
  && mkdir -p /usr/local/lsws/lsphp74/etc/php/7.4 \
  && ln -s /etc/php/litespeed /usr/local/lsws/lsphp74/etc/php/7.4/litespeed \
  && ln -s /etc/php/mods-available /usr/local/lsws/lsphp74/etc/php/7.4/mods-available

RUN echo "**** Fix permissions ****" \
  && chown -R lsadm:lsadm /usr/local/lsws

RUN echo "**** Create error.log for php ****" \
  && touch /usr/local/lsws/logs/php_error.log \
  && chown nobody:nogroup /usr/local/lsws/logs/php_error.log

COPY rootfs/ /

RUN echo "*** Backup PHP Configs ***" \
  && mkdir -p  /usr/local/lsws/default/php \
  && cp -rf  /usr/local/lsws/lsphp74/etc/php/7.4/* /usr/local/lsws/default/php

#When using Composer, disable the warning about running commands as root/super user
ENV COMPOSER_ALLOW_SUPERUSER=1

RUN echo "**** Install Composer ****" \
    && php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php composer-setup.php \
    && mv composer.phar /usr/local/bin/composer \
    && php -r "unlink('composer-setup.php');"

RUN echo "**** Install PHPUnit ****" \
    && wget -q https://phar.phpunit.de/phpunit.phar \
    && mv phpunit.phar /usr/local/bin/phpunit \
    && chmod +x /usr/local/bin/phpunit

RUN echo "**** Install WP-CLI ****" \
    && wget -q https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp-cli \
    && chmod +x /usr/local/bin/wp-cli

RUN echo "**** Ensure there is no admin password ****" \
  && rm -f /etc/openlitespeed/admin/htpasswd

RUN echo "**** Correct permissions ****" \
  && chmod +x /etc/cron.hourly/wp-autoupdate \
  && chmod +x /etc/services.d/tail-log-php-error/run

WORKDIR /var/www/vhosts/localhost/

EXPOSE 80 443 443/udp 7080 8088

# "when the SIGTERM signal is sent, it immediately quits and all established connections are closed"
# "graceful stop is triggered when the SIGUSR1 signal is sent "
STOPSIGNAL SIGUSR1

HEALTHCHECK --interval=5s --timeout=5s CMD [ "301" = "$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:7080/)" ] || exit 1

ENTRYPOINT ["/init"]

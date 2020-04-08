FROM extremeshok/openlitespeed:latest AS AS BUILD
LABEL mantainer="Adrian Kriel <admin@extremeshok.com>" vendor="eXtremeSHOK.com"

USER root

ARG DEBIAN_FRONTEND=noninteractive

# RUN echo "**** Install PHP7.3 ****" \
#   && apt-install \
#   lsphp73-apcu- \
#   lsphp73-common \
#   lsphp73-curl \
#   lsphp73-dev \
#   lsphp73-igbinary \
#   lsphp73-imagick  \
#   lsphp73-imap \
#   lsphp73-intl- \
#   lsphp73-ioncube \
#   lsphp73-json \
#   lsphp73-ldap- \
#   lsphp73-memcached \
#   lsphp73-modules-source- \
#   lsphp73-msgpack \
#   lsphp73-mysql \
#   lsphp73-opcache \
#   lsphp73-pear \
#   lsphp73-pgsql- \
#   lsphp73-pspell- \
#   lsphp73-recode- \
#   lsphp73-redis \
#   lsphp73-snmp- \
#   lsphp73-sqlite3 \
#   lsphp73-sybase- \
#   lsphp73-tidy-

RUN echo "**** Install PHP7.4 ****" \
  && apt-install \
  lsphp74-apcu- \
  lsphp74-common \
  lsphp74-curl \
  lsphp74-dev \
  lsphp74-igbinary \
  lsphp74-imagick  \
  lsphp74-imap \
  lsphp74-intl- \
  #lsphp74-ioncube \ #not available
  lsphp74-json \
  lsphp74-ldap- \
  lsphp74-memcached \
  lsphp74-modules-source- \
  lsphp74-msgpack \
  lsphp74-mysql \
  lsphp74-opcache \
  lsphp74-pear \
  lsphp74-pgsql- \
  lsphp74-pspell- \
  lsphp74-redis \
  lsphp74-snmp- \
  lsphp74-sqlite3 \
  lsphp74-sybase- \
  lsphp74-tidy-

# When using Composer, disable the warning about running commands as root/super user
ENV COMPOSER_ALLOW_SUPERUSER=1

RUN echo "**** Default to PHP7.4 ****" \
 && ln -s /usr/local/lsws/lsphp74/bin/php /usr/bin/php

RUN echo "**** Install Composer ****" \
    && php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php composer-setup.php \
    && mv composer.phar /usr/local/bin/composer \
    && php -r "unlink('composer-setup.php');"

RUN echo "**** Install PHPUnit ****" \
    && wget -q https://phar.phpunit.de/phpunit.phar \
    && chmod +x phpunit.phar \
    && mv phpunit.phar /usr/local/bin/phpunit

RUN echo "**** Install WP-CLI ****" \
    && wget -q https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp-cli

COPY rootfs/ /

WORKDIR /var/www/vhosts/localhost/

EXPOSE 80 443 443/udp 7080

# "when the SIGTERM signal is sent, it immediately quits and all established connections are closed"
# "graceful stop is triggered when the SIGUSR1 signal is sent "
STOPSIGNAL SIGUSR1

HEALTHCHECK --interval=5s --timeout=5s CMD [ "301" = "$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:7080/)" ] || exit 1

ENTRYPOINT ["/init"]

# docker-openlitespeed-php
# eXtremeSHOK.com Docker OpenLiteSpeed with mod_security and pagespeed and PHP 7.4 on Ubuntu LTS 20.04

## Uses the base image extremeshok/openlitespeed : https://hub.docker.com/repository/docker/extremeshok/openlitespeed

## Checkout our optimized production web-server setup based on docker https://github.com/extremeshok/docker-webserver

* Ubuntu LTS 20.04 with S6
* cron (/etc/cron.d) enabled for scheduling tasks, run as user nobody
* Optimized OpenLiteSpeed configs
* Optimized PHP configs
* session, memcached, apc serializer set to igbinary
* OpenLiteSpeed installed via github releases (always newer than the repo)
* OpenLiteSpeed Repository used for lsphp (litespeed-php)
* IONICE set to -10
* Low memory usage
* HEALTHCHECK activated
* Graceful shutdown
* tail modsec.log, error.log and php_error.log to stdout
* configs located in /etc/openlitespeed/
* php configs located in /etc/php/
* logs located in /usr/local/lsws/logs/
* default configs will be added if the config dir is empty
* OWASP modsecurity rules enabled
* Restart openlitespeed when changes to the vhost/domain.com/cert dirs are detected, ie ssl certificate is updated
* PHP 7.4 (lsphp74)
* Composer
* PHPUnit
* WP-CLI
* Expose php disabled
* msmtp enabled: send email via external smtp server, requires SMTP_HOST, SMTP_USER, SMTP_PASS

# VHOST_CRON_ENABLE (disabled by default)
## generate vhost cron from cron files located in vhost/cron (hourly)
* set VHOST_CRON_ENABLE to true to enable, disabled by default
* finds all vhost/cron files and places them in the /etc/cron.d/ , runs hourly
* Place cron files in **/var/www/vhosts/fqdn.com/cron** , see example **/var/www/vhosts/localhost/cron/example**

# WP_AUTOUPDATE_ENABLE (disabled by default)
## Automatically update all wordpress installs (hourly)
searches for wordpress installs located under /var/www/vhost/fqdn.com/html
* updates a wordpress wordpress (plugins, themes, core, core-db, woocommerce)
* if there was an update, caches are flushed (rewrites, transient, cache, lscache)  
* Set WP_AUTOUPDATE_ENABLE to true to enable, disabled by default
* Set WP_AUTOUPDATE_DEBUG to true to enable debug output, disabled by default
* To disable a specific wordpress install from Automatic updates, create a blank "autoupdate.disable" file in the wordpress directory (ie. directory which contains wp-config.php)

# PHP options (with defaults)
* PHP_TIMEZONE=UTC
* PHP_MAX_TIME=180 (in seconds)
* PHP_MAX_UPLOAD_SIZE=32 (in mbyte)
* PHP_MEMORY_LIMIT=256 (in mbyte)
* PHP_DISABLE_FUNCTIONS=shell_exec (set to false to disable, can use a comma separated list)
## Enable PHP-Redis-sessions (disabled by default)
* PHP_REDIS_SESSIONS=yes
* PHP_REDIS_HOST=redis
* PHP_REDIS_PORT=6379
## EXTERNAL SMTP (disabled by default), set hostname, user and pass to enable
* PHP_SMTP_HOST=mail.yoursmtp.com
* PHP_SMTP_PORT=587
* PHP_SMTP_USER=mail@yoursmtp.com
* PHP_SMTP_PASS=securpassword

# Notes:
 * PHP74 linked to /usr/bin/php and /usr/local/lsws/fcgi-bin/lsphp

# Included Modules:
* cache
* mod_js
* mod_security
* modgzip
* modinspector
* modpagespeed
* modreqparser
* uploadprogress

# Included PHP Modules
* apcu
* curl
* dev
* igbinary
* imagick
* imap
* intl
* json
* memcached
* msgpack
* mysql
* opcache
* pear
* redis
* sqlite3

### Note: ioncube ** not supported in php7.4 **

# Usage
Place files in **/var/www/vhosts/fqdn.com/** , see example **/var/www/vhosts/localhost/**

# Ports
* 80 : http
* 443 : httpS
* 443/udp : quic aka http/2
* 7080 : webadmin
* 8088 : example

# Default WebAdmin Login
* https://127.0.0.1:7080
* user: admin
* Password: please use the password set below

# To set your own password
replace container name with the container name, eg xs_openlitespeed-_1
```
docker exec -ti containername /bin/bash '/usr/local/lsws/admin/misc/admpass.sh'
```

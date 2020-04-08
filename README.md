# docker-openlitespeed-php
# eXtremeSHOK.com Docker OpenLiteSpeed with mod_security and pagespeed and PHP on Ubuntu 18.04

* Ubuntu 18.04 with S6
* cron (/etc/cron.d) enabled for scheduling tasks, run as user nobody
* OpenLiteSpeed Repository
* IONICE set to -10
* Low memory usage
* HEALTHCHECK activated
* Graceful shutdown
* accesslog = stdout
* errorlog = stderr
* PHP 7.4 ** Default **
* PHP 7.3
* Composer
* PHPUnit
* WP-CLI

# Included Modules:
* cache
* mod_security
* modgzip
* modinspector
* pagespeed
* uploadprogress

# Included PHP Modules
* curl
* dev
* igbinary
* imagick
* imap
* intl
* ioncube ** PHP 7.3 only **
* json
* memcached
* msgpack
* mysql
* opcache
* pear
* redis
* sqlite3

# Usage
Place files in **/var/www/vhosts/fqdn.com/** , see example **/var/www/vhosts/localhost/**

# Ports
* 80 : http
* 443 : httpS
* 443/udp : quic aka http/2
* 7080 : webadmin

# Default WebAdmin Login
* https://127.0.0.1:7080
* user: admin
* password: password

# To set your own password
replace container name with the container name, eg xs_openlitespeed-_1
```
docker exec -ti containername /bin/bash '/usr/local/lsws/admin/misc/admpass.sh'
```

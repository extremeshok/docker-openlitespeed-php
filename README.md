# docker-openlitespeed-php
# eXtremeSHOK.com Docker OpenLiteSpeed with modsecurity and pagespeed and PHP 7.4 on Ubuntu LTS

## Uses the base image extremeshok/openlitespeed : https://hub.docker.com/repository/docker/extremeshok/openlitespeed

## Checkout our optimized production web-server setup based on docker https://github.com/extremeshok/docker-webserver

## Note all configs are optimized and designed for production usage

* Ubuntu LTS with S6
* Will detect and apply new ssl certs automatically (WATCHMEDO_CERTS_ENABLE)
* cron (/etc/cron.d) enabled for scheduling tasks, run as user nobody
* cron runs every 1 minute, and will generate a new vhost cron every 15mins *if vhost_cron is enabled*
* Preinstalled IP2Location DB , updated monthly on start (IP2LOCATION-LITE-DB1.IPV6.BIN from https://lite.ip2location.com)
* IP2Location running in Shared Memory DB Cache
* Optimized OpenLiteSpeed configs
* Optimised HTTP Headers for Security (Content Security Policy (CSP), Access-Control-Allow-Methods, Content-Security-Policy, Strict-Transport-Security, X-Content-Type-Options, X-DNS-Prefetch-Control, X-Frame-Options, X-XSS-Protection)
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
* WP-CLI , (use comamnd ***wp*** , this will run wp-cli as the nobody user)
* Expose php disabled
* msmtp enabled: send email via external smtp server, requires SMTP_HOST, SMTP_USER, SMTP_PASS
* Increased php pcre limits
* xshok-vhost-fix-permissions, xshok-vhost-generate-cron and xshok-vhost-monitor-certs are all non-blocking (runs parallel)
* Outputs platform information on start
* mariadb-client (mysql command) added as this is required for wp-cli
* vim-tiny to provide ex which allows for advanced modification of files
* opcode caching in shared memory enabled
* opcode file_cache saved to /var/www/vhosts/.opcache

# VHOST_FIX_PERMISSIONS (enabled by default)
## Fix the vhosts folder and file perssions of the vhosts html directory
* set VHOST_FIX_PERMISSIONS to false to disable, enabled by default
* set XS_VHOST_FIX_PERMISSIONS_FOLDERS to false to disable fixing folder permissions, enabled by default
* set XS_VHOST_FIX_PERMISSIONS_FILES to false to disable fixing file permissions, enabled by default
* set XS_VHOST_FIX_PERMISSIONS_FOLDERS to false to disable, enabled by default

# VHOST_CRON (disabled by default)
## generate cron from cron files located in vhost/cron (hourly)
* set VHOST_CRON to true to enable, disabled by default
* finds all vhost/cron files and places them in the /etc/cron.d/ , runs hourly
* ignores  *.readme *.disabled *.disable *.txt *.sample files
* cron runs every 1 minute, and will generate a new vhost cron every 15mins
* Place cron files in **/var/www/vhosts/fqdn.com/cron** , see example **/var/www/vhosts/localhost/cron/example**

# VHOST_MONITOR_CERTS (enabled by default)
## Gracefully restarts openlitespeed to apply certificate updates, will only restart once every 300s
* set VHOST_MONITOR_CERTS to false to disable, enabled by default
* monitors /var/www/vhosts/*/certs, looking for changes (only detects *.pem)

# VHOST_AUTOUPDATE (enabled by default)
# VHOST_AUTOUPDATE_WP (enabled by default)
## Automatically update all wordpress installs (hourly)
* searches for wordpress installs located under /var/www/vhost/fqdn.com/html
* updates a wordpress wordpress (plugins, themes, core, core-db, woocommerce)
* if there was an update, caches are flushed (rewrites, transient, cache, lscache)  
* Set VHOST_AUTOUPDATE to false to disable, enabled by default
* Set VHOST_AUTOUPDATE_WP to false to disable, enabled by default
* Set VHOST_AUTOUPDATE_DEBUG to true to enable debug output, disabled by default
* To disable a specific wordpress install from Automatic updates, create a blank "autoupdate.disable" file in the wordpress directory (ie. directory which contains wp-config.php)

# PHP options (with defaults)
* PHP_TIMEZONE=UTC
* PHP_MAX_TIME=300 (in seconds)
* PHP_MAX_UPLOAD_SIZE=32 (in mbyte)
* PHP_MEMORY_LIMIT=256 (in mbyte)
* PHP_DISABLE_FUNCTIONS=shell_exec (set to false to disable, can use a comma separated list)
## Enable PHP Error messages only (error_reporting = E_ERROR & E_RECOVERABLE_ERROR & E_CORE_ERROR & E_USER_ERROR)
* PHP_ERRORS_ONLY=yes
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
# Check the headers
```
curl -XGET --resolve domain.com:443:ip.ad.re.ss https://domain.com -k -I
```

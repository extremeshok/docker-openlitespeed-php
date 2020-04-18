#!/bin/bash
################################################################################
# This is property of eXtremeSHOK.com
# You are free to use, modify and distribute, however you may not remove this notice.
# Copyright (c) Adrian Jon Kriel :: admin@extremeshok.com
################################################################################
## enable case insensitve matching
shopt -s nocaseglob

###### DEFAULTS ######
PHP_INI="/etc/php/litespeed/php.ini"
ADDITIONAL_PHP_INI="/etc/php/mods-available/"

###### VARIBLES ######
XS_REDIS_SESSIONS=${PHP_REDIS_SESSIONS:-no}
XS_REDIS_HOST=${PHP_REDIS_HOST:-redis}
XS_REDIS_PORT=${PHP_REDIS_PORT:-6379}

XS_TIMEZONE=${PHP_TIMEZONE:-UTC}

XS_DISABLE_FUNCTIONS=${PHP_DISABLE_FUNCTIONS:-shell_exec}

XS_MAX_UPLOAD_SIZE=${PHP_MAX_UPLOAD_SIZE:-32}
XS_MAX_UPLOAD_SIZE="${XS_MAX_UPLOAD_SIZE%m}"
XS_MAX_UPLOAD_SIZE="${XS_MAX_UPLOAD_SIZE%M}"

XS_MAX_TIME=${PHP_MAX_TIME:-180}
XS_MAX_TIME="${XS_MAX_TIME%s}"
XS_MAX_TIME="${XS_MAX_TIME%S}"

XS_MEMORY_LIMIT=${PHP_MEMORY_LIMIT:-256}
XS_MEMORY_LIMIT="${XS_MEMORY_LIMIT%M}"
XS_MEMORY_LIMIT="${XS_MEMORY_LIMIT%m}"

XS_SMTP_HOST=${PHP_SMTP_HOST:-}
XS_SMTP_PORT=${PHP_SMTP_PORT:-587}
XS_SMTP_USER=${PHP_SMTP_USER:-}
XS_SMTP_PASSWORD=${PHP_SMTP_PASSWORD:-}


###### ECC ######

if [[ $XS_MEMORY_LIMIT -lt 64 ]] ; then
  echo "WARNING: XS_MEMORY_LIMIT if ${XS_MEMORY_LIMIT} too low, setting to 128"
  XS_MEMORY_LIMIT=128
fi

###### MSMTP ######
## Configure Remote SMTP config
if [ -d "/etc/" ] && [ -w "/etc/" ] ; then

  if [ "$XS_SMTP_HOST" != "" ] && [ "$XS_SMTP_USER" != "" ] && [ "$XS_SMTP_PASSWORD" != "" ] ; then
    echo "Installing remote smtp (msmtp)"

    cat << EOF >> /etc/msmtprc
defaults
port ${XS_SMTP_PORT}
tls on
tls_starttls on
tls_certcheck off

account remote
host ${XS_SMTP_HOST}
from ${XS_SMTP_USER}
auth on
user ${XS_SMTP_USER}
password ${XS_SMTP_PASSWORD}

account default : remote

EOF
    if [ -f "/usr/sbin/sendmail" ] ; then
      mv -f /usr/sbin/sendmail /usr/sbin/sendmail.disabled
    fi
    ln -s /usr/bin/msmtp /usr/sbin/sendmail
  else
    rm -f /etc/msmtprc
    if [ -f "/usr/sbin/sendmail.disabled" ] ; then
      mv -f /usr/sbin/sendmail.disabled /usr/sbin/sendmail
    fi
  fi
fi

###### CONFIGURE PHP ######
if [ -d "$ADDITIONAL_PHP_INI" ] && [ -w "$ADDITIONAL_PHP_INI" ] ; then
  # MSMTP
  if [ "$XS_SMTP_HOST" != "" ] && [ "$XS_SMTP_USER" != "" ] && [ "$XS_SMTP_PASSWORD" != "" ] ; then
    echo "Installing remote smtp (msmtp)"
    echo 'sendmail_path = "/usr/bin/msmtp -C /etc/msmtprc -t"' > "${ADDITIONAL_PHP_INI}/xs_msmtp.ini"
  else
    rm -f "${ADDITIONAL_PHP_INI}/xs_msmtp.ini"
  fi
  ## disable functions
  if [ "$XS_DISABLE_FUNCTIONS" == "no" ] || [ "$XS_DISABLE_FUNCTIONS" == "false" ] || [ "$XS_DISABLE_FUNCTIONS" == "off" ] || [ "$XS_DISABLE_FUNCTIONS" == "0" ] ; then
    echo "" > "${ADDITIONAL_PHP_INI}/xs_disable_functions.conf"
  else
    echo "Disabling functions"
    echo "php_admin_value[disable_functions] = ${XS_DISABLE_FUNCTIONS}" > "${ADDITIONAL_PHP_INI}/xs_disable_functions.conf"
  fi
  # ioncube
  # if [ "$XS_IONCUBE" == "yes" ] || [ "$XS_IONCUBE" == "true" ] || [ "$XS_IONCUBE" == "on" ] || [ "$XS_IONCUBE" == "1" ] ; then
  #   echo "Enabling ioncube"
  #   echo "zend_extension=/usr/lib/php7.4/modules/ioncube_loader_lin_7.4.so" > "${ADDITIONAL_PHP_INI}/000000_ioncube.ini"
  # elif [ -f "${ADDITIONAL_PHP_INI}/000000_ioncube.ini" ] ; then
  #   rm -f "${ADDITIONAL_PHP_INI}/000000_ioncube.ini"
  # fi
  # Redis sessions
  if [ "$XS_REDIS_SESSIONS" == "yes" ] || [ "$XS_REDIS_SESSIONS" == "true" ] || [ "$XS_REDIS_SESSIONS" == "on" ] || [ "$XS_REDIS_SESSIONS" == "1" ] ; then
    echo "Enabling redis sessions"
    cat << EOF > "${ADDITIONAL_PHP_INI}/xs_redis.ini"
session.save_handler = redis
session.save_path = "tcp://${XS_REDIS_HOST}:${XS_REDIS_PORT}"
EOF
  elif [ -f "${ADDITIONAL_PHP_INI}/xs_redis.ini" ] ; then
    rm -f "${ADDITIONAL_PHP_INI}/xs_redis.ini"
  fi
  # timezone
  echo "date.timezone = ${XS_TIMEZONE}" > "${ADDITIONAL_PHP_INI}/xs_timezone.ini"
  # execution times
  cat << EOF > "${ADDITIONAL_PHP_INI}/xs_max_time.ini"
  max_execution_time = ${XS_MAX_TIME}
  max_input_time = ${XS_MAX_TIME}
EOF
  # upload size
  cat << EOF > "${ADDITIONAL_PHP_INI}/xs_max_upload_size.ini"
  upload_max_filesize = ${XS_MAX_UPLOAD_SIZE}M
  post_max_size = ${XS_MAX_UPLOAD_SIZE}M
EOF
  # memory limit
  echo "memory_limit = ${XS_MEMORY_LIMIT}M" > "${ADDITIONAL_PHP_INI}/xs_memory_limit.ini"
fi

echo "#### Checking PHP configs ####"
/usr/bin/php -t ${PHP_INI}
result=$?
if [ "$result" != "0" ] ; then
  echo "ERROR: CONFIG DAMAGED, sleeping ......"
  sleep 1d
  exit 1
fi

###### WAIT FOR REDIS SERVER ######
if [ "$XS_REDIS_SESSIONS" == "yes" ] || [ "$XS_REDIS_SESSIONS" == "true" ] || [ "$XS_REDIS_SESSIONS" == "on" ] || [ "$XS_REDIS_SESSIONS" == "1" ] ; then
  # wait for redis to start
  echo "waiting for redis ${XS_REDIS_HOST}:${XS_REDIS_PORT}"
  while ! echo PING | nc -q 10  ${XS_REDIS_HOST} ${XS_REDIS_PORT} ; do
    echo "waiting for redis ${XS_REDIS_HOST}:${XS_REDIS_PORT}"
    sleep 5s
  done
fi

######  Generate crontab ######
# busybox only allows for a single cron, all cron will be run as the nobody user
if [ ! -f "/etc/cron.d/*" ] ; then
  echo "Generating single crontab from cronjobs in /etc/cron.d/"
  cat /etc/cron.d/* | crontab -u nobody -
fi

######  Initialize Configs ######
# Restore configs if they are missing, ie if a new/empty volume was used to store the configs
if [ ! -f  "/etc/openlitespeed/conf/httpd_config.conf" ] || [ ! -f  "/etc/openlitespeed/admin/admin_config.conf" ] ; then
  cp -rf /usr/local/lsws/default/conf/* /etc/openlitespeed/conf/
  cp -rf /usr/local/lsws/default/admin/* /etc/openlitespeed/admin/
fi

# generate a random admin password, if one is not defined
if [ ! -f  "/etc/openlitespeed/admin/htpasswd" ] ; then
  echo "admin: $(/usr/local/lsws/admin/fcgi-bin/admin_php* -q /usr/local/lsws/admin/misc/htpasswd.php '$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)') " > /etc/openlitespeed/admin/htpasswd
fi

# Restore localhost if missing, ie if a new/empty volume was used to store the www/vhost
if [ ! -d  "/var/www/vhosts/localhost/" ] ; then
  mkdir -p /var/www/vhosts/localhost/
  cp -rf /usr/local/lsws/default/localhost/* /var/www/vhosts/localhost/
fi

if [ ! -f  "/var/www/vhosts/localhost/certs/privkey.pem" ] || [ ! -f  "/var/www/vhosts/localhost/certs/fullchain.pem" ] ; then
  echo "Generating default certificate and key for localhost"
  openssl req -new -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes -out /var/www/vhosts/localhost/certs/fullchain.pem -keyout  /var/www/vhosts/localhost/certs/privkey.pem -subj "/C=RO/ST=Bucharest/L=Bucharest/O=IT/CN=localhost"
fi


###### Fix vhost permissions ######
if [ -d "/var/www/vhosts" ] ; then
  echo "Fixing vhost permissions"
  chmod 777 /var/www/vhosts
  chmod 777 /var/www/vhosts/*
  chmod -R 640 /var/www/vhosts/*/certs/
fi

###### LAUNCH LITESPEEED SERVER ######
/usr/local/lsws/bin/lswsctrl start
while true; do
  if ! /usr/local/lsws/bin/lswsctrl status | grep -q "litespeed is running with PID" ; then
    break
  fi
  sleep 60
done

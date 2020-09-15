#!/usr/bin/env bash
################################################################################
# This is property of eXtremeSHOK.com
# You are free to use, modify and distribute, however you may not remove this notice.
# Copyright (c) Adrian Jon Kriel :: admin@extremeshok.com
################################################################################
#
# searches for wordpress installs and does updates (plugins, themes, core, core-db, wordpress, woocommerce)
#
# caches are flushed if there was an update (rewrites, transient, cache, lscache)
#
# Set WP_AUTOUPDATE_ENABLE to "no" to disable
# Set WP_AUTOUPDATE_DEBUG to "yes" to enable debug output of the wp-cli commands
#
#
#################################################################################

################# DEFAULTS
VHOST_DIR="/var/www/vhosts"

################# ECC
XS_WP_AUTOUPDATE_DEBUG=${WP_AUTOUPDATE_DEBUG:-no}
if [ "${XS_WP_AUTOUPDATE_DEBUG,,}" == "yes" ] || [ "${XS_WP_AUTOUPDATE_DEBUG,,}" == "true" ] || [ "${XS_WP_AUTOUPDATE_DEBUG,,}" == "on" ] || [ "${XS_WP_AUTOUPDATE_DEBUG,,}" == "1" ] ; then
  XS_WP_AUTOUPDATE_DEBUG=true
else
  XS_WP_AUTOUPDATE_DEBUG=false
fi

################# MAIN
if [ -d "${VHOST_DIR}" ] ; then
  while IFS= read -r wp_path ; do
    updated=""
    echo "Processing: ${wp_path}"
    if [ ! -f  "${wp_path}/autoupdate.disable" ] ; then
      # path contains /html , remeber files are always located under vhost/html
      if sudo -u nobody /usr/local/bin/wp-cli --path="${wp_path}" core is-installed ; then
        echo "- Valid wordpress"

        echo "-- plugin"
        result=$(sudo -u nobody /usr/local/bin/wp-cli --path="${wp_path}" plugin update --all 2>&1)
        result_short=${result##*$'\n'}
        if [[ "${result_short,,}" != *"no plugins updated"* ]] && [[ "${result_short,,}" != *"already updated"* ]]  ; then
            echo "PLUGIN/s UPDATED"
            updated="plugin"
            if [ $XS_WP_AUTOUPDATE_DEBUG ] ; then echo "$result" ; fi
        fi

        echo "--  theme"
        result=$(sudo -u nobody /usr/local/bin/wp-cli --path="${wp_path}" theme update --all 2>&1)
        result_short=${result##*$'\n'}
        if [[ "${result_short,,}" != *"no themes updated"* ]] && [[ "${result_short,,}" != *"already updated"* ]] ; then
            echo "THEME UPDATED!!"
            updated="theme"
            if [ $XS_WP_AUTOUPDATE_DEBUG ] ; then echo "$result" ; fi
        fi

        echo "-- core and core-db"
        result=$(sudo -u nobody /usr/local/bin/wp-cli --path="${wp_path}" core update 2>&1 )
        result_short=${result##*$'\n'}
        if [[ "${result_short,,}" != *"wordpress is up to date"* ]] ; then
            result_two=$(sudo -u nobody /usr/local/bin/wp-cli --path="${wp_path}" core update-db 2>&1)
            echo "CORE UPDATED!!"
            updated="core"
            if [ $XS_WP_AUTOUPDATE_DEBUG ] ; then echo "$result" ; fi
            if [ $XS_WP_AUTOUPDATE_DEBUG ] ; then echo "$result_two" ; fi
        fi

        echo "-- woocommerce"
        result=$(sudo -u nobody /usr/local/bin/wp-cli --path="${wp_path}" wc update 2>&1)
        result_short=${result##*$'\n'}
        if [[ "${result_short,,}" != *"no updates required"* ]] && [[ "${result_short,,}" != *"did you mean"* ]] && [[ "${result_short,,}" != *"already updated"* ]] ; then
            echo "WC UPDATED!!"
            updated="woocommerce"
            if [ $XS_WP_AUTOUPDATE_DEBUG ] ; then echo "$result" ; fi
        fi

        if [ "$updated" != "" ] ; then
          echo "- Flushing caches due to update : ${updated}"

          result=$(sudo -u nobody /usr/local/bin/wp-cli --path="${wp_path}" rewrite flush 2>&1)
          result_short=${result##*$'\n'}
          if [[ "${result_short,,}" == *"rewrite rules flushed"* ]] ; then
              echo "-- Rewrite rules flushed"
              if [ $XS_WP_AUTOUPDATE_DEBUG ] ; then echo "$result" ; fi
          fi

          result=$(sudo -u nobody /usr/local/bin/wp-cli --path="${wp_path}" transient delete --all 2>&1)
          result_short=${result##*$'\n'}
          if [[ "${result_short,,}" == *"transients deleted from"* ]] ; then
              echo "-- All transients deleted"
              if [ $XS_WP_AUTOUPDATE_DEBUG ] ; then echo "$result" ; fi
          fi

          result=$(sudo -u nobody /usr/local/bin/wp-cli --path="${wp_path}" cache flush 2>&1)
          result_short=${result##*$'\n'}
          if [[ "${result_short,,}" == *"cache was flushed"* ]] ; then
              echo "-- Cache was flushed"
              if [ $XS_WP_AUTOUPDATE_DEBUG ] ; then echo "$result" ; fi
          fi

          result=$(sudo -u nobody /usr/local/bin/wp-cli --path="${wp_path}" lscache-purge all 2>&1)
          result_short=${result##*$'\n'}
          if [[ "${result_short,,}" == *"purged all"* ]] ; then
              echo "-- Purged all lscache"
              if [ $XS_WP_AUTOUPDATE_DEBUG ] ; then echo "$result" ; fi
          fi
        fi
      fi
    fi
  done < <(find "${VHOST_DIR}" -path "*/html/*" -type f -name "wp-config.php" -printf '%h\n' | sort | uniq)  #dirs
fi

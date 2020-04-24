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
# Set WP_UPDATE_ENABLE to "no" to disable
#
#################################################################################

XS_WP_UPDATE_ENABLE=${WP_UPDATE_ENABLE:-yes}

VHOST_DIR="/var/www/vhosts"

if [ "$XS_WP_UPDATE_ENABLE" == "yes" ] || [ "$XS_WP_UPDATE_ENABLE" == "true" ] || [ "$XS_WP_UPDATE_ENABLE" == "on" ] || [ "$XS_WP_UPDATE_ENABLE" == "1" ] ; then
  if [ -d "${VHOST_DIR}" ] ; then
    while IFS= read -r wp_path ; do
      updated=""
      echo "Processing: ${wp_path}"
      if [[ "$wp_path" == *"/html"* ]] ; then
        # path contains /html , remeber files are always located under vhost/html
        if wp-cli --allow-root --path="${wp_path}" core is-installed ; then
          echo " Valid wordpress"

          echo "   plugin"
          result=$(wp-cli --allow-root --path="${wp_path}" plugin update --all 2>&1)
          result=${result##*$'\n'}
          if [[ "${result,,}" != *"no plugins updated"* ]] ; then
                echo "PLUGIN/s UPDATED"
                updated="plugin"
          fi

          echo "   theme"
          result=$(wp-cli --allow-root --path="${wp_path}" theme update --all 2>&1)
          result=${result##*$'\n'}
          if [[ "${result,,}" != *"no themes updated"* ]] ; then
                echo "THEME UPDATED!!"
                updated="theme"
          fi

          echo "   core and core-db"
          result=$(wp-cli --allow-root --path="${wp_path}" core update 2>&1 )
          result=${result##*$'\n'}
          if [[ "${result,,}" != *"wordpress is up to date"* ]] ; then
              result=$(wp-cli --allow-root --path="${wp_path}" core update-db 2>&1)
              echo "CORE UPDATED!!"
              updated="core"
          fi

          echo "   woocommerce"
          result=$(wp-cli --allow-root --path="${wp_path}" wc update 2>&1)
          result=${result##*$'\n'}
          if [[ "${result,,}" != *"no updates required"* ]] && [[ "${result,,}" != *"did you mean"* ]] ; then
              echo "WC UPDATED!!"
              updated="woocommerce"
          fi

          if [ "$updated" != "" ] ; then
            echo "Flushing caches due to update : ${updated}"

            result=$(wp-cli --allow-root --path="${wp_path}" rewrite flush 2>&1)
            result=${result##*$'\n'}
            if [[ "${result,,}" == *"rewrite rules flushed"* ]] ; then
                echo "Rewrite rules flushed"
            fi

            result=$(wp-cli --allow-root --path="${wp_path}" transient delete --all 2>&1)
            result=${result##*$'\n'}
            if [[ "${result,,}" == *"transients deleted from"* ]] ; then
                echo "All transients deleted"
            fi

            result=$(wp-cli --allow-root --path="${wp_path}" cache flush 2>&1)
            result=${result##*$'\n'}
            if [[ "${result,,}" == *"cache was flushed"* ]] ; then
                echo "Cache was flushed"
            fi

            result=$(wp-cli --allow-root --path="${wp_path}" lscache-purge all 2>&1)
            result=${result##*$'\n'}
            echo "$result"
            if [[ "${result,,}" == *"purged all"* ]] ; then
                echo "Purged all lscache"
            fi

          fi
        fi
      fi
    done < <(find "${VHOST_DIR}" -path "*/html/*" -type f -name "wp-config.php" -printf '%h\n' | sort | uniq)  #dirs
  fi
fi

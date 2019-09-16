#!/bin/bash

create_sitemap() {
  start creating the sitemap
    php /usr/local/vufind/util/sitemap.php
    chmod g+r,o+r /tmp/sitemap*.xml
    mv /tmp/sitemap{,-*,Index}.xml /var/www/html/
  finish
}

clear_caches() {
  start clearing the caches
    systemctl stop vufind apache2
    rm -rf /usr/local/vufind/local/cache/*
    rm -rf /var/cache/apache2/mod_cache_disk/aleph.muni.cz/*
    systemctl start vufind apache2
  finish
}

main() {
  if [ -z "$VUFIND_HOME" ]
  then
    export VUFIND_HOME="$(cd "$(dirname "$0")" && pwd -P)"
    if [ -z "$VUFIND_HOME" ]
    then
      exit 1
    fi
  fi

  . "$VUFIND_HOME"/vufind-common.sh

  if [ -z "$VUFIND_LOCAL_DIR" ]
  then
    export VUFIND_LOCAL_DIR="$VUFIND_HOME"/local
  fi

  start the maintenance of vufind
    (
      set -e

      create_sitemap
      clear_caches
    )
  finish
}

main

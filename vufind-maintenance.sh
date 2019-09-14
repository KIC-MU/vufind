#!/bin/bash

print_info() {
  printf '%s:\t%s%s\n' "$(date --rfc-3339=seconds)" \
    "$(for INDEX in $(seq 2 $1); do printf '  '; done)" \
    "${*:2}"
}

create_sitemap() {
  print_info 2 "Started creating the sitemap"
  php /usr/local/vufind/util/sitemap.php
  chmod g+r,o+r /tmp/sitemap*.xml
  mv /tmp/sitemap{,-*,Index}.xml /var/www/html/
  print_info 2 "Finished creating the sitemap"
}

clear_caches() {
  print_info 2 "Started clearing the caches"
  systemctl stop vufind apache2
  rm -rf /usr/local/vufind/local/cache/*
  rm -rf /var/cache/apache2/mod_cache_disk/aleph.muni.cz/*
  systemctl start vufind apache2
  print_info 2 "Finished clearing the caches"
}

main() {
  print_info 1 "Started the maintenance of vufind"
  START_TIME=$(date +%s.%N)
  (
    set -e

    if [ -z "$VUFIND_HOME" ]
    then
      export VUFIND_HOME="$(cd "$(dirname "$0")" && pwd -P)"
      if [ -z "$VUFIND_HOME" ]
      then
        exit 1
      fi
    fi

    if [ -z "$VUFIND_LOCAL_DIR" ]
    then
      export VUFIND_LOCAL_DIR="$VUFIND_HOME"/local
    fi

    create_sitemap
    clear_caches
  )
  FINISH_TIME=$(date +%s.%N)
  DURATION=$(LC_ALL=C printf '%.2f' $(bc -l <<< "($FINISH_TIME - $START_TIME) / 60"))
  print_info 1 "Finished the maintenance of vufind in $DURATION minutes with return code $?"
}

main

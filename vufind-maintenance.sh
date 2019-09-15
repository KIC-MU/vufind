#!/bin/bash

declare -A START_TIMES

start() {
  START_TIMES[$1]=$(date +%s.%N)
  print_info $1 Started "${@:2}"
}

finish() {
  FINISH_TIME=$(date +%s.%N)
  DURATION=$(LC_ALL=C printf '%.2f' $(bc -l <<< "($FINISH_TIME - ${START_TIMES[$1]}) / 60"))
  print_info $1 Finished "${@:2}" "in $DURATION minutes"
}

print_info() {
  printf '%s:\t%s%s\n' "$(date --rfc-3339=seconds)" \
    "$(for INDEX in $(seq 2 $1); do printf '  '; done)" \
    "${*:2}"
}

create_sitemap() {
  start 2 "creating the sitemap"
  php /usr/local/vufind/util/sitemap.php
  chmod g+r,o+r /tmp/sitemap*.xml
  mv /tmp/sitemap{,-*,Index}.xml /var/www/html/
  finish 2 "creating the sitemap"
}

clear_caches() {
  start 2 "clearing the caches"
  systemctl stop vufind apache2
  rm -rf /usr/local/vufind/local/cache/*
  rm -rf /var/cache/apache2/mod_cache_disk/aleph.muni.cz/*
  systemctl start vufind apache2
  finish 2 "clearing the caches"
}

main() {
  start 1 "the maintenance of vufind"
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
  finish 1 "the maintenance of vufind with return code $?"
}

main

#!/bin/bash
printf '%s:\tStarted reindexing Solr\n' "$(date --rfc-3339=seconds)"

(
  set -e

  cd /root/mu-aleph-dumps
  ./update-dumps.sh

  cd /usr/local/vufind
  curl http://localhost:8080/solr/biblio/update --data "<delete><query>*:*</query></delete>" -H "Content-type:text/xml; charset=utf-8" |
    grep -qF '<int name="status">0</int>'
  ./import-marc.sh <(cat /root/mu-aleph-dumps/mu-aleph-mub0?.dump.mrc)
  sudo -u solr ./index-alphabetic-browse.sh
  cd util
  php optimize.php
)

RETURN_CODE=$?
printf '%s:\tFinished reindexing Solr with return code %d\n' "$(date --rfc-3339=seconds)" $RETURN_CODE

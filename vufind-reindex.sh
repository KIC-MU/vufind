#!/bin/bash

print_info() {
  printf '%s:\t%s\n' "$(date --rfc-3339=seconds)" "$@"
}

usmarc_to_xml() {
  java -jar import/lib/marc4j*.jar to_xml |
  sed -r '{
    # Remove invalid character references to ASCII C0 and C1 control codes, produced by marc4j.
    s/&#([0-8bcefBCEF]|1.)//g

    # Replace some non-standard tags produced by Aleph with local data tags.
    s/datafield tag="Z30"/datafield tag="994"/g
  }'
}

download_dumps() {
  cd "$VUFIND_HOME"
  for BASENAME in mu-aleph-mub{01..02}.dump; do
    # Download the Aleph database dump.
    curl -L https://aleph.muni.cz/vufind-dump/${BASENAME}.mrc > ${BASENAME}.mrc.new
    mv ${BASENAME}.mrc{.new,}
    # Convert the database dump to XML and check that the XML is well-formed.
    usmarc_to_xml < ${BASENAME}.mrc > ${BASENAME}.xml.new
    xmllint --stream --noout - < ${BASENAME}.xml.new
    mv ${BASENAME}.xml{.new,}
  done
}

reindex_solr() {
  cd "$VUFIND_HOME"
  curl http://localhost:8080/solr/biblio/update --data "<delete><query>*:*</query></delete>" -H "Content-type:text/xml; charset=utf-8" |
  grep -qF '<int name="status">0</int>'
  ./import-marc.sh <(head -n -1 mu-aleph-mub01.dump.xml && tail -n +2 mu-aleph-mub02.dump.xml)
  sudo -u solr ./index-alphabetic-browse.sh
  cd util
  php optimize.php
}

print_info "Started reindexing Solr"
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

  download_dumps
  reindex_solr
)
print_info "Finished reindexing Solr with return code $?"

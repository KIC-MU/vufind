#!/bin/bash

print_info() {
  printf '%s:\t%s\n' "$(date --rfc-3339=seconds)" "$@"
}

usmarc_to_xml_biblio() {
  java -jar import/lib/marc4j*.jar to_xml |
  sed -r -n '{
    /<marc:record>/ {
      # Read entire MARC record into pattern space.
      :A
      N
      /<marc:datafield tag="STA" [^>]*>.*<marc:subfield code="a">PROZAT[IÍ]MNÍ/ {
        /<marc:datafield tag="STA".*</marc:datafield>/ ! {
          # Skip MARC records that are flagged as unfinished.
          :B
          N
          /<\/marc:record>/ bD
          bB
        }
      }
      /<\/marc:record>/ bC
      bA

      # Process pattern space.
      :C

      ## Remove invalid character references to ASCII C0 and C1 control codes produced by marc4j.
      s/&#([0-8bcefBCEF]|1.)//g

      ## Replace some non-standard tags produced by Aleph with local data tags.
      s/(<marc:datafield tag)="Z30"/\1="994"/g

      ## Merge sublibrary codes to the code of the main library.
      s#(<marc:subfield code="1">)(FFHUD|FFJZV|FF-K|FF-S|FFUHV)(</marc:subfield>)#\1FF\3#g
      s#(<marc:subfield code="1">)(PRIMA|PRI-S)(</marc:subfield>)#\1PRIF\3#g
    }

    # Print pattern space (XML declaration, trailing marc:collection tag, MARC record).
    p

    :D
  }'
}

usmarc_to_xml_authority() {
  java -jar import/lib/marc4j*.jar to_xml
}

download_dumps_biblio() {
  cd "$VUFIND_HOME"
  for BASENAME in mu-aleph-mub{01..02}.dump; do
    # Download the Aleph bibliography database dump.
    curl -L https://aleph.muni.cz/vufind-dump/${BASENAME}.mrc > ${BASENAME}.mrc.new
    mv ${BASENAME}.mrc{.new,}
    # Convert the database dump to XML and check that the XML is well-formed.
    usmarc_to_xml_biblio < ${BASENAME}.mrc > ${BASENAME}.xml.new
    xmllint --stream --noout - < ${BASENAME}.xml.new
    mv ${BASENAME}.xml{.new,}
  done
}

download_dumps_authority() {
  cd "$VUFIND_HOME"
  for BASENAME in mu-vufind-nkp10.dump; do
    # Download the NKP authority database dump.
    curl -L https://aleph.muni.cz/vufind-dump/${BASENAME}.mrc > ${BASENAME}.mrc.new
    mv ${BASENAME}.mrc{.new,}
    # Convert the database dump to XML and check that the XML is well-formed.
    usmarc_to_xml_authority < ${BASENAME}.mrc > ${BASENAME}.xml.new
    xmllint --stream --noout - < ${BASENAME}.xml.new
    mv ${BASENAME}.xml{.new,}
  done
}

download_dumps() {
  download_dumps_biblio
  download_dumps_authority
}

reindex_solr_biblio() {
  cd "$VUFIND_HOME"
  curl http://localhost:8080/solr/biblio/update \
    --data "<delete><query>*:*</query></delete>" \
    -H "Content-type:text/xml; charset=utf-8" |
  grep -qF '<int name="status">0</int>'
  ./import-marc.sh <(
    head -n -1 mu-aleph-mub01.dump.xml
    tail -n +2 mu-aleph-mub02.dump.xml
  )
  sudo -u solr ./index-alphabetic-browse.sh
}

reindex_solr_authority() {
  cd "$VUFIND_HOME"
  curl http://localhost:8080/solr/authority/update \
    --data "<delete><query>*:*</query></delete>" \
    -H "Content-type:text/xml; charset=utf-8" |
  grep -qF '<int name="status">0</int>'
  ./import-marc-auth.sh <(
    cat mu-vufind-nkp10.dump.xml
  ) marc_auth_fast_topical.properties
}

reindex_solr() {
  reindex_solr_biblio
  reindex_solr_authority
  (cd util && php optimize.php)
}

main() {
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
}

main

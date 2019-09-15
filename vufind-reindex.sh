#!/bin/bash
shopt -s extglob

DUMP_DIRECTORY=/var/tmp/vufind-reindex

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

usmarc_to_xml() {
  java -jar "$VUFIND_HOME"/import/lib/marc4j*.jar to_xml |
  sed -r '
    # Remove invalid character references to ASCII C0 and C1 control codes produced by marc4j.
    s/&#([0-8bcefBCEF]|1.)//g
  '
}

download_dumps() {
  for TYPE in biblio authority
  do
    start 2 "producing $TYPE.xml"

    rm -rf "$DUMP_DIRECTORY"/$TYPE
    mkdir -p "$DUMP_DIRECTORY"/$TYPE
    cd "$DUMP_DIRECTORY"/$TYPE

    case $TYPE in
      biblio)     BASENAMES=(mu-aleph-mub{02,01}.dump) ;;
      authority)  BASENAMES=(mu-vufind-{msh11,nkp10}.dump) ;;
      *)          BASENAMES=() ;;
    esac

    for BASENAME in "${BASENAMES[@]}"
    do
      start 3 "producing $BASENAME.xml"

      start 4 "downloading $BASENAME.mrc from aleph"
      curl -s -L https://aleph.muni.cz/vufind-dump/$BASENAME.mrc > $BASENAME.mrc
      finish 4 "downloading $BASENAME.mrc from aleph"

      start 4 "converting $BASENAME.mrc to $BASENAME.xml"
      usmarc_to_xml < $BASENAME.mrc > $BASENAME.xml
      finish 4 "converting $BASENAME.mrc to $BASENAME.xml"

      if compgen -G "$VUFIND_HOME"/vufind-reindex.d/$TYPE/'*'.xsl > /dev/null
      then

        start 4 "splitting $BASENAME.xml into chunks"
        rm -rf $BASENAME
        mkdir -p $BASENAME
        xml_split -l 1 -e .xml -g 1000 -n 3 -b $BASENAME/record $BASENAME.xml
        parallel --halt soon,fail=1 -- '
          sed -r -i '\''
            1,2 s#xmlns:xml_split="http://xmltwig.com/xml_split"#& xmlns:marc="http://www.loc.gov/MARC21/slim"#
          '\'' {}
        ' ::: $BASENAME/record-!(000).xml
        finish 4 "splitting $BASENAME.xml into chunks"

        for TRANSFORMATION in "$VUFIND_HOME"/vufind-reindex.d/$TYPE/*.xsl
        do
          start 4 "applying vufind-reindex.d/$TYPE/${TRANSFORMATION##*/} to chunks"
          parallel --halt soon,fail=1 -- "
            set -e
            xsltproc --output {}.new '$TRANSFORMATION' {}
            mv {}.new {}
          " ::: $BASENAME/record-!(000).xml
          finish 4 "applying vufind-reindex.d/$TYPE/${TRANSFORMATION##*/} to chunks"
        done

        start 4 "merging chunks into $BASENAME.xml"
        xml_merge -o $BASENAME.xml $BASENAME/record-000.xml
        finish 4 "merging chunks into $BASENAME.xml"

      fi

      start 4 "validating $BASENAME.xml"
      xmllint --stream --noout --xinclude - < $BASENAME.xml
      rm -rf $BASENAME
      finish 4 "validating $BASENAME.xml"

      finish 3 "producing $BASENAME.xml"
    done

    cd "$DUMP_DIRECTORY"

    start 3 "merging ${BASENAMES[@]/%/.xml} into $TYPE.xml"
    (
      for INDEX in "${!BASENAMES[@]}"
      do
        cat $TYPE/"${BASENAMES[$INDEX]}.xml" |
        (if (( $INDEX > 0 ));                      then tail -n +2; else cat; fi) |
        (if (( $INDEX < "${#BASENAMES[@]}" - 1 )); then head -n -1; else cat; fi)
      done
    ) > $TYPE.xml.new
    finish 3 "merging ${BASENAMES[@]/%/.xml} into $TYPE.xml"

    start 3 "validating $TYPE.xml"
    xmllint --stream --noout --xinclude - < $TYPE.xml.new
    rm -rf $TYPE
    finish 3 "validating $TYPE.xml"

    mv $TYPE.xml{.new,}
    finish 2 "producing $TYPE.xml"
  done
}

reindex_solr_biblio() {
  cd "$VUFIND_HOME"
  start 2 "indexing biblio.xml"
  curl http://localhost:8080/solr/biblio/update \
    --data "<delete><query>*:*</query></delete>" \
    -H "Content-type:text/xml; charset=utf-8" |
  grep -qF '<int name="status">0</int>'
  ./import-marc.sh "$DUMP_DIRECTORY"/biblio.xml
  finish 2 "indexing biblio.xml"

  start 2 "indexing alphabetical headings"
  sudo -u solr ./index-alphabetic-browse.sh
  finish 2 "indexing alphabetical headings"
}

reindex_solr_authority() {
  cd "$VUFIND_HOME"
  start 2 "indexing authority.xml"
  curl http://localhost:8080/solr/authority/update \
    --data "<delete><query>*:*</query></delete>" \
    -H "Content-type:text/xml; charset=utf-8" |
  grep -qF '<int name="status">0</int>'
  ./import-marc-auth.sh \
    "$DUMP_DIRECTORY"/authority.xml \
    marc_auth_fast_topical.properties
  finish 2 "indexing authority.xml"
}

reindex_solr() {
  reindex_solr_biblio
  reindex_solr_authority
  start 2 "optimizing solr"
  (cd "$VUFIND_HOME"/util && php optimize.php)
  finish 2 "optimizing solr"
}

main() {
  start 1 "reindexing solr"
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
  finish 1 "reindexing solr with return code $?"
}

main

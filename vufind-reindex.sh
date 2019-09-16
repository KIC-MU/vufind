#!/bin/bash
shopt -s extglob

DUMP_DIRECTORY=/var/tmp/vufind-reindex

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
    start producing $TYPE.xml
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
        start producing $BASENAME.xml
          start downloading $BASENAME.mrc from aleph
            curl -s -L https://aleph.muni.cz/vufind-dump/$BASENAME.mrc > $BASENAME.mrc
          finish

          start converting $BASENAME.mrc to $BASENAME.xml
            usmarc_to_xml < $BASENAME.mrc > $BASENAME.xml
          finish

          if compgen -G "$VUFIND_HOME"/vufind-reindex.d/$TYPE/'*'.xsl > /dev/null
          then

            start splitting $BASENAME.xml into chunks
              rm -rf $BASENAME
              mkdir -p $BASENAME
              xml_split -l 1 -e .xml -g 1000 -n 3 -b $BASENAME/record $BASENAME.xml
              parallel --halt soon,fail=1 -- '
                sed -r -i '\''
                  1,2 s#xmlns:xml_split="http://xmltwig.com/xml_split"#& xmlns:marc="http://www.loc.gov/MARC21/slim"#
                '\'' {}
              ' ::: $BASENAME/record-!(000).xml
            finish

            for TRANSFORMATION in "$VUFIND_HOME"/vufind-reindex.d/$TYPE/*.xsl
            do
              start applying vufind-reindex.d/$TYPE/${TRANSFORMATION##*/} to chunks
                parallel --halt soon,fail=1 -- "
                  set -e
                  xsltproc --output {}.new '$TRANSFORMATION' {}
                  mv {}.new {}
                " ::: $BASENAME/record-!(000).xml
              finish
            done

            start merging chunks into $BASENAME.xml
              xml_merge -o $BASENAME.xml $BASENAME/record-000.xml
            finish
          fi

          start validating $BASENAME.xml
            xmllint --stream --noout --xinclude - < $BASENAME.xml
            rm -rf $BASENAME
          finish

        finish
      done

      cd "$DUMP_DIRECTORY"

      start merging ${BASENAMES[@]/%/.xml} into $TYPE.xml
        (
          for INDEX in "${!BASENAMES[@]}"
          do
            cat $TYPE/"${BASENAMES[$INDEX]}.xml" |
            (if (( $INDEX > 0 ));                      then tail -n +2; else cat; fi) |
            (if (( $INDEX < "${#BASENAMES[@]}" - 1 )); then head -n -1; else cat; fi)
          done
        ) > $TYPE.xml.new
      finish

      start validating $TYPE.xml
        xmllint --stream --noout --xinclude - < $TYPE.xml.new
        rm -rf $TYPE
      finish

      mv $TYPE.xml{.new,}
    finish
  done
}

reindex_solr_biblio() {
  cd "$VUFIND_HOME"
  start indexing biblio.xml
    curl http://localhost:8080/solr/biblio/update \
      --data "<delete><query>*:*</query></delete>" \
      -H "Content-type:text/xml; charset=utf-8" |
    grep -qF '<int name="status">0</int>'
    ./import-marc.sh "$DUMP_DIRECTORY"/biblio.xml
  finish

  start indexing alphabetical headings
    sudo -u solr ./index-alphabetic-browse.sh
  finish
}

reindex_solr_authority() {
  cd "$VUFIND_HOME"
  start indexing authority.xml
    curl http://localhost:8080/solr/authority/update \
      --data "<delete><query>*:*</query></delete>" \
      -H "Content-type:text/xml; charset=utf-8" |
    grep -qF '<int name="status">0</int>'
    ./import-marc-auth.sh \
      "$DUMP_DIRECTORY"/authority.xml \
      marc_auth_fast_topical.properties
  finish
}

reindex_solr() {
  reindex_solr_biblio
  reindex_solr_authority
  start optimizing solr
    (cd "$VUFIND_HOME"/util && php optimize.php)
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

  start reindexing solr
    (
      set -e

      download_dumps
      reindex_solr
    )
  finish
}

main

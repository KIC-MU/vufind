#!/bin/bash

print_info() {
  printf '%s:\t%s\n' "$(date --rfc-3339=seconds)" "$@"
}

usmarc_to_marcmaker() {
  perl -e '
    use strict;
    use warnings;
    use diagnostics;

    use MARC;

    # Convert binary USMARC to the plaintext MARCBreaker file format.
    my $increment = 500;
    my $x = new MARC;
    $x->openmarc({file=>"/dev/stdin", format=>"usmarc", increment=>$increment});
    while ($x->nextmarc($increment)) {
        $x->output({file=>">>/dev/stdout",format=>"marcmaker"});
        $x->deletemarc();
    }
    $x->closemarc();
  ' |
  sed -r '{
    # Use exactly two spaces between field names and indicators.
    s/(^=...) */\1  /

    # Replace incorrectly parsed non-standard tags.
    /^=[zZ]30/ { N; s/(^=[zZ]30)  \r\n *-([0-9])/\1  \\\2/ }
    /^=... *\r$/ { N; s/(^=...)  \r\n */\1  / }

    # Replace non-standard indicator values with spaces.
    s/(^=([^0-9lL]..|[0-9lL][^0-9dD].|[0-9lL][0-9dD][^0-9rR]))  [^0-9\\]/\1  \\/
    s/(^=([^0-9lL]..|[0-9lL][^0-9dD].|[0-9lL][0-9dD][^0-9rR]))  ([0-9\\])[^0-9\\]/\1  \2\\/

    # Replace some non-standard tags produced by Aleph with local data tags.
    s/^=[zZ]30/=901/
    # The following is a catch-all for any other non-standard tags other
    # than LDR, which is part of the MARCBreaker syntax.
    s/^=([^0-9lL]..|[0-9lL][^0-9dD].|[0-9lL][0-9dD][^0-9rR])/=949/

    # Add missing character $ after indicators in non-control fields.
    s/(^=([1-9]..|0[1-9].)  [0-9\\][0-9\\])([^$])/\1$\3/

    # Remove empty subfields.
    s/\$+/$/g

    # Separate wrapped fields that are produced in the conversion, but
    # unsupported by SolrMarc, with blank lines.
    1! { s/^=.../\n&/ }
  }' |
  awk '
    # Unwrap the wrapped fields and remove the blank lines we introduced
    # in the previous step.
    {
      sub("\r$", "")
      printf "%s", $0
    }
    /^$/ { print "" }
    END { print "" }
  '
}

usmarc_to_xml() {
  java -jar import/lib/marc4j*.jar to_xml |
  sed -r '{
    # Replace some non-standard tags produced by Aleph with local data tags.
    s/datafield tag="Z30"/datafield tag="901"/g
  }'
}

download_dumps() {
  cd "$VUFIND_HOME"
  for BASENAME in mu-aleph-mub{01..03}.dump; do
    curl -L https://aleph.muni.cz/vufind-dump/${BASENAME}.mrc > ${BASENAME}.mrc.new
    mv ${BASENAME}.mrc{.new,}
    usmarc_to_xml < ${BASENAME}.mrc > ${BASENAME}.xml.new
    mv ${BASENAME}.xml{.new,}
  done
}

reindex_solr() {
  cd "$VUFIND_HOME"
  curl http://localhost:8080/solr/biblio/update --data "<delete><query>*:*</query></delete>" -H "Content-type:text/xml; charset=utf-8" |
  grep -qF '<int name="status">0</int>'
  ./import-marc.sh <(cat mu-aleph-mub0?.dump.xml)
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

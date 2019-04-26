#!/bin/bash
printf '%s:\tStarted reindexing Solr\n' "$(date --rfc-3339=seconds)"

(
  set -e

  cd "$VUFIND_HOME"

  # Download dumps
  for BASE in $(seq 1 3); do
    curl -L https://aleph.muni.cz/vufind-dump/mu-aleph-mub0${BASE}.dump.mrc |
      perl -e '
        use strict;
        use warnings;
        use diagnostics;

        use MARC;

        my $increment = 500;
        my $x = new MARC;
        $x->openmarc({file=>"/dev/stdin", format=>"usmarc", increment=>$increment});
        while ($x->nextmarc($increment)) {
            $x->output({file=>">>/dev/stdout",'format'=>"marcmaker"});
            $x->deletemarc();
        }
        $x->closemarc();
      ' |
      sed '{
        # Replace non-standard tags produced by Aleph with 901-907 and 910 local data tags
        s/^=AVA/=901/
        s/^=CAT/=902/
        s/^=FMT/=903/
        s/^=LOW/=904/
        s/^=M06/=905/
        s/^=M54/=906/
        s/^=STA/=907/
        s/^=Z30/=910/
      }' > mu-aleph-mub0${BASE}.dump.mrc.new
    mv mu-aleph-mub0${BASE}.dump.mrc.new mu-aleph-mub0${BASE}.dump.mrc
  done

  # Index dumps
  curl http://localhost:8080/solr/biblio/update --data "<delete><query>*:*</query></delete>" -H "Content-type:text/xml; charset=utf-8" |
    grep -qF '<int name="status">0</int>'
  ./import-marc.sh <(cat /root/mu-aleph-dumps/mu-aleph-mub0?.dump.mrc)
  sudo -u solr ./index-alphabetic-browse.sh
  cd util
  php optimize.php
)

RETURN_CODE=$?
printf '%s:\tFinished reindexing Solr with return code %d\n' "$(date --rfc-3339=seconds)" $RETURN_CODE

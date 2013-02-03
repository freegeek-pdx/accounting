#!/bin/sh

set -e

DB="$1"

if [ -z "$DB" ]; then
    DB=xtuple
fi

LASTLINE="account_id_hash = {"
TEMPFILE=$(mktemp)
echo "SELECT accnt_id, accnt_name FROM public.accnt;" | psql $DB | grep "^  " | less | sed -r 's/^.* ([0-9]+) \| [^-]+-[^-]+-(.+)$/"\2" => \1/g' > $TEMPFILE
while read LINE; do
    echo "$LASTLINE"
    LASTLINE="  $LINE,"
done < $TEMPFILE
rm $TEMPFILE
echo "$LASTLINE"
echo "}"

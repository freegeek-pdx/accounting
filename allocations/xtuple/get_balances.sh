#!/bin/sh

SUBACCNT=$1 # 930
YEAR=$2 # 2012
MONTH=$3 # Dec
TYPES="('E', 'R')"

die() {
    echo "Error: $@"
    exit 1
}

if [ -z "$1" -o -z "$2" -o -z "$3" ]; then
    die "Usage: $0 subaccnt year month (ex: 930 2012 Dec)"
fi

echo "SELECT accnt_number, accnt_descrip, accnt_comments, accnt_extref, trialbal_ending - trialbal_beginning AS balance_change FROM trialbal JOIN accnt ON trialbal_accnt_id = accnt_id JOIN period ON trialbal_period_id = period_id WHERE accnt_sub LIKE '$SUBACCNT' AND accnt_type IN $TYPES AND period_name LIKE '$YEAR - $MONTH';" | psql xtuple | ~/psql2csv

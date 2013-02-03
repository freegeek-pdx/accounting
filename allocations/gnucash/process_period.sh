#!/bin/sh

set -e

PERIOD_YEAR=$1
PERIOD_MONTH=$2
COSTPOOL_CODE=$3
PERIOD_ENDDATE=$4
ALLOCATION_FILE="$5"

DATA="$PERIOD_MONTH $PERIOD_YEAR for cost pool $COSTPOOL_CODE"

if [ "$(wc -l "$ALLOCATION_FILE" | cut -d ' ' -f 1)" = "1" ]; then
    echo "No allocation data found for $DATA"
    exit
fi


./get_balances.sh $COSTPOOL_CODE $PERIOD_YEAR $PERIOD_MONTH > input.csv
if [ "$(wc -l "input.csv" | cut -d ' ' -f 1)" = "1" ]; then
    echo "No balance data found for $DATA"
    exit
fi

echo "Allocating $DATA"

./allocations/allocate.rb input.csv "$ALLOCATION_FILE" output.csv 
./allocations/gen_sql.rb $PERIOD_ENDDATE $COSTPOOL_CODE input.csv "/home/ryan52/subaccounts.csv" output.csv > output.sql
psql --quiet gnucash < output.sql 

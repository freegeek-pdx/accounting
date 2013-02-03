#!/bin/sh

SUBACCNT=$1 # 930
YEAR=$2 # 2012
MONTH=$3 # Dec
TYPES="('EXPENSE', 'INCOME')"

die() {
    echo "Error: $@"
    exit 1
}

if [ -z "$1" -o -z "$2" -o -z "$3" ]; then
    die "Usage: $0 subaccnt year month (ex: 930 2012 Dec)"
fi

echo "SELECT SUBSTRING(code FROM 0 FOR 5), accounts.name, accounts.description, COALESCE(slots.string_val, ''), SUM(COALESCE(value_num, 0)) AS balance_change FROM accounts LEFT OUTER JOIN splits ON accounts.guid = account_guid LEFT OUTER JOIN transactions ON splits.tx_guid = transactions.guid LEFT OUTER JOIN slots ON slots.name LIKE 'notes' AND slots.obj_guid = accounts.guid WHERE LPAD(SUBSTRING(code FROM 6 FOR 3), 3, '0') LIKE '$SUBACCNT' AND account_type IN $TYPES AND EXTRACT(year FROM post_date) = $YEAR AND to_char(post_date, 'Mon') LIKE '$MONTH' GROUP BY 1, 2, 3, 4;" | psql gnucash | ~/psql2csv


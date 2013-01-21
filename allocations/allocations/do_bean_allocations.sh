#!/bin/sh

set -e

SERVER=bean

echo "Preparing to generate allocation data"
scp periods.csv $SERVER:
scp ~/import/subaccounts.csv $SERVER:

./pre_allocations.sh

ssh $SERVER rm -fr allocation_data
ssh $SERVER mkdir -p allocation_data
scp -r sales_data/93* floorplan_data/93* hours_data/93* $SERVER:allocation_data/
ssh $SERVER prename 's/\ -\ /_/g' allocation_data/*/*.csv
ssh $SERVER ./forall_allocations_and_periods.rb periods.csv ./process_period.sh

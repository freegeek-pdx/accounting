#!/bin/sh

set -e

SERVER=lima

echo "Preparing to generate allocation data"
scp ~/import/subaccounts.csv $SERVER:
ssh $SERVER ./get_periods.sh > periods.csv
scp periods.csv $SERVER:

./pre_allocations.sh
# PUSH_ALLOCATIONS

ssh $SERVER rm -fr allocation_data
ssh $SERVER mkdir -p allocation_data
scp -r sales_data/93* floorplan_data/93* hours_data/93* $SERVER:allocation_data/
ssh $SERVER prename 's/\ -\ /_/g' allocation_data/*/*.csv

ssh $SERVER ./forall_allocations_and_periods.rb periods.csv ./process_period.sh

echo 
echo "Allocation complete. You must manually forward update the trial balances to complete the process:"
echo
echo "Run Forward Update Accounts in xTuple"
echo

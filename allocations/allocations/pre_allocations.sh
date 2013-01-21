#!/bin/sh

set -e

rm -fr sales_data hours_data floorplan_data
mkdir -p sales_data hours_data floorplan_data
echo "Getting sales data"
ssh zhora ./fgdb.rb/script/pull_sales_gizmo_income_allocations.sh | ~/psql2csv > sales_data/results.csv
echo "Getting hours data"
# run with: start date, end date, saving output to name.csv
# later todo: cleanup the online sales data, free transactions by certain users in time period?
./forall_periods.rb periods.csv hours_data ssh zhora ./fgdb.rb/script/pull_worker_income_stream_allocations.sh

echo "Cleaning up data for allocating"

# splits by type name
./fixup_sales_data.rb periods.csv sales_data
# copies for before tracking dates
./fixup_hours_data.rb periods.csv hours_data
# duplicate it, a lot
./copy_floorplan_data.rb periods.csv 931.csv floorplan_data

for i in hours_data/930 floorplan_data/931 sales_data/932 sales_data/933 sales_data/934; do
    ./fixup_x00_accounts.rb periods.csv $i
done

echo "Beginning allocations"

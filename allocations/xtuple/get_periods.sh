#!/bin/sh

echo 'SELECT period_name, period_start, period_end FROM period ORDER BY 2;' | psql xtuple | ~ryan52/psql2csv

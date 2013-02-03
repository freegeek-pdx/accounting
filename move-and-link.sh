#!/bin/sh

TARGET=/home/ryan52/accounting/allocations/xtuple/
mkdir -p $TARGET

F=$1
if test -f $F; then
    F=$(readlink -f $F)
    mv $F $TARGET
    ln -s $TARGET/$(basename $F) $F
fi

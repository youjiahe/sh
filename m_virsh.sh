#!/bin/bash
if [ $# -ne 3 ]; then
   echo "$0 (start|stop) <start_num> <end_num>"
   exit 1
fi
for h in `seq $2 $3`
do
   virsh $1 host$h
done & 

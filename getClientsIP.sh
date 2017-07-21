#! /bin/bash

ips=$(sed '/^$/d' ./clients/clients | sed '/^#/d' | awk '{print $1}' | sort -k2n | awk '{if ($0!=line) print;line=$0}')

for ip in $ips
do
    ./checkIP.sh $ip >> /dev/null
    if [ $? -ne 0 ]
    then
        exit 1
    fi
done

echo $ips
exit 0

#! /bin/bash
dir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)
client_dir=$(cd -P -- "$(dirname -- "$0")" && cd ../clients && pwd -P)

ips=$(sed '/^$/d' $client_dir/clients | sed '/^#/d' | awk '{print $1}' | sort -k2n | awk '{if ($0!=line) print;line=$0}')

for ip in $ips
do
    $dir/checkIP.sh $ip >> /dev/null
    if [ $? -ne 0 ]
    then
        exit 1
    fi
done

echo $ips
exit 0

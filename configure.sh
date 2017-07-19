#! /bin/bash

password=$1
server=$2

function usage () {
    echo 'Usage : Script <password> <username@server address>'
    exit 0
}

if [ "$#" -ne 2 ]
then
  usage
fi

if [ `whoami` = "root" ]
then
    echo "Don't run as root!"
    exit 1
fi

./pre-config.sh $password $server

if [ $? -ne 0 ]
then
    echo "pre-config installration failed, may try again."
    exit 1
fi

sleep 1

echo "pre-config is done"

./hadoopconfig.sh $password $server
exit 0

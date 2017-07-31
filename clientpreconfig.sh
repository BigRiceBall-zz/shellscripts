#! /bin/bash

password=$1
client=$2

function usage () {
    echo 'Usage : Script <password> <client>'
    exit 1
}

# check whether the necessary parameter is two or not
if [ "$#" -ne 2 ]
then
    usage
    exit 1
fi

if [ `whoami` = "root" ]
then
    echo "Don't run as root!"
    exit 1
fi

./jdkclient.sh $password $client
# configure ssh without password
./sshclient.sh $password $client
# configure NTP client
./ntpclient.sh $password $client

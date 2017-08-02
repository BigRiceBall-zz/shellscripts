#! /bin/bash

password=$1
client=$2
working_dir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

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

$working_dir/jdk/jdkclient.sh $password $client
# configure ssh without password
$working_dir/ssh/sshclient.sh $password $client
# configure NTP client
$working_dir/ntp/ntpclient.sh $password $client

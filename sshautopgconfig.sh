#! /bin/bash

function usage () {
    echo 'Usage : Script <username@server address> <password>'
    exit 0
}

if [ "$#" -ne 2 ]
then
  usage
fi

server=$1
password=$2

expect <<- DONE
    set timeout -1
    spawn sudo scp -o StrictHostKeyChecking=no -r /usr/local/java $server:/usr/local/
    expect "*?assword*"
    send -- "$password\r"
    expect "*?assword*"
    send -- "$password\r"
    expect eof
    spawn sudo scp -o StrictHostKeyChecking=no /etc/profile.d/jdkenv.sh $server:/etc/profile.d/jdkenv.sh
    expect "*?assword*"
    send -- "$password\r"
    expect "*?assword*"
    send -- "$password\r"
    expect eof
DONE

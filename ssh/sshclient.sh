#! /bin/bash

password=$1
client=$2
# clients=($(./getClientsIP.sh))

function usage () {
    echo 'Usage : Script <password> <client>'
    exit 1
}

# check whether the necessary parameter is empty or not
if [ "$#" -ne 2 ]
then
    usage
    exit 1
fi

expect <<- DONE
    set timeout -1

    spawn ssh-copy-id -i $HOME/.ssh/id_rsa.pub -o StrictHostKeyChecking=no $client

    # Look for passwod prompt
    expect "*?assword*"

    # Send password aka $password
    send -- "$password\r"

    expect eof
DONE

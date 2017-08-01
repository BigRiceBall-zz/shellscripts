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

# # check whether the IP array is empty or not.
# if [ ${#clients[@]} -eq 0 ]
# then
#     echo "There are some errors in the clients file"
#     exit 1
# fi

# copy the public key to each client
# for x in $( seq 0 `expr ${#clients[@]} - 1` )
# do
expect <<- DONE
    set timeout -1

    spawn ssh-copy-id -i $HOME/.ssh/id_rsa.pub -o StrictHostKeyChecking=no $client

    # Look for passwod prompt
    expect "*?assword*"

    # Send password aka $password
    send -- "$password\r"

    expect eof
DONE
# done

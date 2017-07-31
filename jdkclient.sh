#! /bin/bash

password=$1
client=$2
# clients=($(./getClientsIP.sh))

function usage () {
    echo 'Usage : Script <password>'
    exit 1
}

# check whether the necessary parameter is empty or not
if [ "$#" -ne 2 ]
then
    usage
    exit 1
fi

# check whether the IP array is empty or not.
# if [ ${#clients[@]} -eq 0 ]
# then
#     echo "There are some errors in the clients file"
#     exit 1
# fi

# for x in $( seq 0 `expr ${#clients[@]} - 1` )
# do
expect <<- DONE
    set timeout -1
    spawn sudo scp -o StrictHostKeyChecking=no -r /usr/local/java $client:/usr/local/
    expect {
        "*?assword*" {
            send -- "$password\r"
            exp_continue
        }
        eof
    }
    spawn sudo scp -o StrictHostKeyChecking=no /etc/profile.d/jdkenv.sh $client:/etc/profile.d/jdkenv.sh
    expect {
        "*?assword*" {
            send -- "$password\r"
            exp_continue
        }
        eof
    }
DONE
# done

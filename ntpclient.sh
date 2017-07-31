#! /bin/bash

password=$1
ip=$(ip route get 8.8.8.8 | head -1 | cut -d' ' -f8)
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


# if [ ${#clients[@]} -eq 0 ]
# then
#     echo "There are some errors in the clients file"
#     exit 1
# fi

# modified the client config according to the ip
sed -i "25 s/.*/server $ip iburst/" ./ntpconfigfiles/ntpclient.conf

#
# for x in $( seq 0 `expr ${#clients[@]} - 1` )
# do

expect <<- DONE
    set timeout -1

    # send the ntp client config to the client.
    spawn sudo scp -o StrictHostKeyChecking=no ./ntpconfigfiles/ntpclient.conf $client:/etc/ntp.conf
    expect {
        "*?assword*" {
            send -- "$password\r"
            exp_continue
        }
        eof
    }
DONE

ssh $client << EOF
expect <<- DONE
    set timeout -1

    # restart the ntpd in the clients
    spawn sudo service ntpd stop
    expect "*?assword*"
    send -- "$password\r"
    expect eof
    spawn sudo service ntpd start
    expect "*?assword*"
    send -- "$password\r"
    expect eof

    # disable chronyd so that ntpd can run on boot
    spawn sudo systemctl disable chronyd.service
    expect "*?assword*"
    send -- "$password\r"
    expect eof

    # start the ntpd when boot
    spawn sudo chkconfig ntpd on
    expect "*?assword*"
    send -- "$password\r"
    expect eof
DONE
EOF

# done

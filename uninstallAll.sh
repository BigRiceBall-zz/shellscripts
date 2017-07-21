#! /bin/bash

clients=($(./getClientsIP.sh))
password=$1

function usage () {
    echo 'Usage : Script <password>'
    exit 0
}

# check whether the necessary parameter is empty or not
if [ "$#" -ne 1 ]
then
    usage
    exit 1
fi

if [ `whoami` = "root" ]
then
    echo "Don't run as root!"
    exit 1
fi

# check whether the IP array is empty or not.
if [ ${#clients[@]} -eq 0 ]
then
    echo "There are some errors in the clients file"
    exit 1
fi

expect <<- DONE
    set timeout -1

    spawn sudo rm -rf /home/sunyue/.ssh/
    expect "*?assword*"
    send -- "$password\r"
    expect eof

    spawn sudo rm -rf /usr/local/java
    expect "*?assword*"
    send -- "$password\r"
    expect eof

    spawn sudo rm  /etc/profile.d/jdkenv.sh
    expect "*?assword*"
    send -- "$password\r"
    expect eof

    spawn sudo rm  /etc/ntp.conf
    expect "*?assword*"
    send -- "$password\r"
    expect eof

    spawn sudo rm  /etc/hosts
    expect "*?assword*"
    send -- "$password\r"
    expect eof


    spawn sudo rm -rf /usr/local/hadoop
    expect "*?assword*"
    send -- "$password\r"
    expect eof

    spawn sudo rm -rf /etc/profile.d/hadoopenv.sh
    expect "*?assword*"
    send -- "$password\r"
    expect eof

    spawn sudo rm -rf /home/sunyue/hadoop_work
    expect "*?assword*"
    send -- "$password\r"
    expect eof
DONE

for x in $( seq 0 `expr ${#clients[@]} - 1` )
do
ssh -o StrictHostKeyChecking=no ${clients[$x]} << EOF
expect <<- FIN
    set timeout -1

    spawn sudo rm -rf /home/sunyue/.ssh/
    expect "*?assword*"
    send -- "$password\r"
    expect eof

    spawn sudo rm -rf /usr/local/java
    expect "*?assword*"
    send -- "$password\r"
    expect eof

    spawn sudo rm  /etc/profile.d/jdkenv.sh
    expect "*?assword*"
    send -- "$password\r"
    expect eof

    spawn sudo rm  /etc/ntp.conf
    expect "*?assword*"
    send -- "$password\r"
    expect eof

    spawn sudo rm  /etc/hosts
    expect "*?assword*"
    send -- "$password\r"
    expect eof


    spawn sudo rm -rf /usr/local/hadoop
    expect "*?assword*"
    send -- "$password\r"
    expect eof

    spawn sudo rm -rf /etc/profile.d/hadoopenv.sh
    expect "*?assword*"
    send -- "$password\r"
    expect eof

    spawn sudo rm -rf /home/sunyue/hadoop_work
    expect "*?assword*"
    send -- "$password\r"
    expect eof
FIN
EOF
done

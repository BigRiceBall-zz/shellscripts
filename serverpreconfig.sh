#! /bin/bash

password=$1

function usage () {
    echo 'Usage : Script <password>'
    exit 1
}

# check whether the necessary parameter is two or not
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

# install java jdk
expect <<- DONE
    set timeout -1
    spawn sudo ./jdkserver.sh
    expect {
        "*?assword*" {
            send -- "$password\r"
            exp_continue
        }
        "*Already tried 5 times, all failed, exit*" {
            exit 1
        }
        eof {
            exit 0
        }
    }
DONE

if [ $? -ne 1 ]
then
    # configure ssh without password
    ./sshserver.sh $password
    # configure NTP server
    ./ntpserver.sh $password

    exit 0
else
    exit 1
fi
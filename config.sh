#! /bin/bash

password=$1
server=$2

function usage () {
    echo 'Usage : Script <password> <username@hostname> '
    exit 0
}

# check whether the necessary parameter is two or not
if [ "$#" -ne 2 ]
then
    usage
    exit 1
fi

# install java jdk
expect <<- DONE
set timeout -1
spawn sudo ./javainstall.sh
expect {
    "*?assword*" {
      send -- "$password\r"
      exp_continue
    }
    "*failed*" {
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
./sshwopassconfig.sh $server $password

# install java jdk in another server
./sshautopgconfig.sh $server $password

# configure NTP server and configure NTP Client
./sync.sh $password $server
fi

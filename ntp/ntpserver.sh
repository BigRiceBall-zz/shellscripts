#! /bin/bash

password=$1
working_dir=$(cd -P -- "$(dirname -- "$0")" && cd .. && pwd -P)

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

expect <<- DONE
    set timeout -1

    # copy ntp server config to /etc/
    spawn sudo cp $working_dir/conf/ntp/ntp.conf /etc/
    expect "*?assword*"
    send -- "$password\r"
    expect eof

    # # open the port 123
    # spawn sudo firewall-cmd --add-service=ntp --permanent
    # expect "*?assword*"
    # send -- "$password\r"
    # expect eof
    # spawn sudo firewall-cmd --reload
    # expect "*?assword*"
    # send -- "$password\r"
    # expect eof

    # start the ntpd
    spawn sudo systemctl restart ntpd
    expect "*?assword*"
    send -- "$password\r"
    expect eof
    spawn sudo systemctl enable ntpd.service
    expect "*?assword*"
    send -- "$password\r"
    expect eof
    spawn sudo systemctl status ntpd
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

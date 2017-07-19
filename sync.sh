#! /bin/bash

password=$1
server=$2
ip=$(ip route get 8.8.8.8 | head -1 | cut -d' ' -f8)

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

# modified the client config according to the ip
sed -i "25 s/.*/server $ip iburst/" ./ntpconfigfiles/ntpclient.conf

expect <<- DONE
    set timeout -1

    # copy ntp server config to /etc/
    spawn sudo cp ./ntpconfigfiles/ntp.conf /etc/
    expect "*?assword*"
    send -- "$password\r"
    expect eof

    # open the port 123
    spawn sudo firewall-cmd --add-service=ntp --permanent
    expect "*?assword*"
    send -- "$password\r"
    expect eof
    spawn sudo firewall-cmd --reload
    expect "*?assword*"
    send -- "$password\r"
    expect eof

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

    # send the ntp client config to the client.
    spawn sudo scp ./ntpconfigfiles/ntpclient.conf $server:/etc/ntp.conf
    expect "*?assword*"
    send -- "$password\r"
    expect "*?assword*"
    send -- "$password\r"
    expect eof
    # spawn sudo ntpd
    # expect "*?assword*"
    # send -- "$password\r"
    # expect eof

DONE

ssh $server << EOF
expect <<- DONE
    set timeout -1
    spawn sudo service ntpd stop
    expect "*?assword*"
    send -- "$password\r"
    expect eof
    spawn sudo service ntpd start
    expect "*?assword*"
    send -- "$password\r"
    expect eof
DONE
EOF

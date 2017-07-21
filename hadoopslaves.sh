#! /bin/bash

hadoop_dir=/usr/local
password=$1
clients=($(./getClientsIP.sh))

function usage () {
    echo 'Usage : Script <password>'
    exit 0
}

if [ `whoami` = "root" ]
then
    echo "Don't run as root!"
    exit 1
fi

# check whether the necessary parameter is empty or not
if [ "$#" -ne 1 ]
then
    usage
    exit 1
fi

# check whether the IP array is empty or not.
if [ ${#clients[@]} -eq 0 ]
then
    echo "There are some errors in the clients file"
    exit 1
fi

for x in $( seq 0 `expr ${#clients[@]} - 1` )
do

expect <<- DONE
    # configure the host file to datanode
    spawn sudo scp -o StrictHostKeyChecking=no ./hadoopconfigfiles/hosts ${clients[$x]}:/etc/hosts
    expect "*?assword*"
    send -- "$password\r"
    expect "*?assword*"
    send -- "$password\r"
    expect eof

    # copy the hadoop to datanodes
    spawn sudo scp -r ${hadoop_dir}/hadoop ${clients[$x]}:/usr/local/
    expect "*?assword*"
    send -- "$password\r"
    expect "*?assword*"
    send -- "$password\r"
    expect eof
    spawn sudo scp ./hadoopconfigfiles/hadoopenv.sh ${clients[$x]}:/etc/profile.d/
    expect "*?assword*"
    send -- "$password\r"
    expect "*?assword*"
    send -- "$password\r"
    expect eof
DONE

ssh ${clients[$x]} << EOF
    expect <<- DONE
        # change the hostname of datanode
        spawn sudo hostname hadoop-slave-`expr $x + 1`
        expect "*?assword*"
        send -- "$password\r"
        expect eof

        # change the owner of the folder so that the user can access without sudo
        spawn sudo chown -R $(whoami).$(whoami) /usr/local/hadoop
        expect "*?assword*"
        send -- "$password\r"
        expect eof

        # stop the firewall and disable the firewall of the datanodes when boot
        spawn sudo systemctl stop firewalld.service
        expect "*?assword*"
        send -- "$password\r"
        expect eof
        spawn sudo systemctl disable firewalld.service
        expect "*?assword*"
        send -- "$password\r"
        expect eof
    DONE
EOF
DONE
done

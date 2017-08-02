#! /bin/bash

hadoop_dir=/usr/local
password=$1
client=$2
hostname=$3
working_dir=$(cd -P -- "$(dirname -- "$0")" && cd .. && pwd -P)

function usage () {
    echo 'Usage : Script <password> <client> <client hostname>'
    exit 1
}

if [ `whoami` = "root" ]
then
    echo "Don't run as root!"
    exit 1
fi

# check whether the necessary parameter is empty or not
if [ "$#" -ne 3 ]
then
    usage
    exit 1
fi

expect <<- DONE
    set timeout -1
    # configure the host file to datanode
    spawn sudo scp -o StrictHostKeyChecking=no $working_dir/conf/hadoop/hosts $client:/etc/hosts
    expect {
        "*?assword*" {
            send -- "$password\r"
            exp_continue
        }
        eof
    }

    # copy the hadoop to datanodes
    spawn sudo scp -r ${hadoop_dir}/hadoop $client:/usr/local/
    expect {
        "*?assword*" {
            send -- "$password\r"
            exp_continue
        }
        eof
    }
    spawn sudo scp $working_dir/conf/hadoop/hadoopenv.sh $client:/etc/profile.d/
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
    # change the hostname of datanode
    spawn sudo hostname $hostname
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
exit 0
# done

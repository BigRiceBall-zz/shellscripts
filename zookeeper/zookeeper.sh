#! /bin/bash


zookeeper_dir=/usr/local
working_dir=$(cd -P -- "$(dirname -- "$0")" && cd .. && pwd -P)
password=$1
client=$2
clientID=$3

function usage () {
    echo 'Usage : Script <password> <client address>'
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

# download the zookeeper
for time in $( seq 1 6 )
do
    if [ "$time" = "6" ]
    then
        echo "Already tried 5 times, all failed, exit"
        exit 1
    fi
    wget -c -O $HOME/Downloads/zookeeper.tar.gz -t 0 http://mirror.bit.edu.cn/apache/zookeeper/zookeeper-3.4.10/zookeeper-3.4.10.tar.gz
    md5=$(md5sum $HOME/Downloads/zookeeper.tar.gz | cut -d ' ' -f1)
    if [ "$md5" != "e4cf1b1593ca870bf1c7a75188f09678" ]
    then
        echo "md5 check failed, re-downloading"
        rm $HOME/Downloads/zookeeper.tar.gz
        continue
    fi
    echo -e "\n md5 check success \n"
    break
done

# unzip the file and rename it
rm -rf $HOME/Downloads/zookeeper
tar -xzvf $HOME/Downloads/zookeeper.tar.gz -C $HOME/Downloads/
mv $HOME/Downloads/zookeeper-3.4.10 $HOME/Downloads/zookeeper
rm $HOME/Downloads/zookeeper/conf/zoo_sample.cfg
cp $working_dir/conf/zookeeper/zoo.cfg $HOME/Downloads/zookeeper/conf
echo $clientID > $working_dir/conf/zookeeper/myid

ssh -o StrictHostKeyChecking=no $client << EOF
expect <<- DONE
    spawn sudo rm -rf /var/lib/zookeeper
    expect {
        "*?assword*" {
            send -- "$password\r"
            exp_continue
        }
        eof
    }
    spawn sudo mkdir /var/lib/zookeeper
    expect {
        "*?assword*" {
            send -- "$password\r"
            exp_continue
        }
        eof
    }
    spawn sudo rm -rf /usr/local/zookeeper
    expect {
        "*?assword*" {
            send -- "$password\r"
            exp_continue
        }
        eof
    }
DONE
EOF

expect <<- DONE
    set timeout -1
    spawn sudo scp -o StrictHostKeyChecking=no $working_dir/conf/zookeeper/myid $client:/var/lib/zookeeper/
    expect {
        "*?assword*" {
            send -- "$password\r"
            exp_continue
        }
        eof
    }
    spawn sudo scp -o StrictHostKeyChecking=no -r $HOME/Downloads/zookeeper $client:/usr/local/zookeeper
    expect {
        "*?assword*" {
            send -- "$password\r"
            exp_continue
        }
        eof
    }

DONE

rm -rf $HOME/Downloads/zookeeper

ssh -o StrictHostKeyChecking=no $client << EOF
expect <<- DONE
    # change the owner of the folder so that the user can access without sudo
    spawn sudo chown -R $(whoami).$(whoami) /usr/local/zookeeper
    expect "*?assword*"
    send -- "$password\r"
    expect eof
    spawn sudo chown -R $(whoami).$(whoami) /var/lib/zookeeper
    expect "*?assword*"
    send -- "$password\r"
    expect eof
DONE
source /etc/profile.d/jdkenv.sh && source /etc/profile.d/hadoopenv.sh && /usr/local/zookeeper/bin/zkServer.sh start
EOF
exit 0

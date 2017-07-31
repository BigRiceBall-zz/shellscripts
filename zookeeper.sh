#! /bin/bash


zookeeper_dir=/usr/local
password=$1

function usage () {
    echo 'Usage : Script <password>'
    exit 1
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

# download the zookeeper
for time in $( seq 1 6 )
do
    if [ "$time" = "6" ]
    then
        echo "Already tried 5 times, all failed, exit"
        exit 1
    fi
    wget -c -O $HOME/Downloads/zookeeper.tar.gz -t 0 http://mirror.bit.edu.cn/apache/zookeeper/zookeeper-3.4.10/zookeeper-3.4.10.tar.gz
    result=$?
    md5=$(md5sum $HOME/Downloads/zookeeper.tar.gz | cut -d ' ' -f1)
    if [ "$md5" != "e4cf1b1593ca870bf1c7a75188f09678" ]
    then
        echo "md5 check failed, re-downloading"
        rm $HOME/Downloads/zookeeper.tar.gz
        continue
    fi
    echo -e "\n md5 check success \n"
    if [ "$result" != "0" ]
    then
        echo "failed, download error, re-downloading"
        rm $HOME/Downloads/zookeeper.tar.gz
        continue
    else
        break
    fi
done

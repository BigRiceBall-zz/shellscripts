#! /bin/bash

hadoop_dir=/usr/local
password=$1
server=$2
ip=$(ip route get 8.8.8.8 | head -1 | cut -d' ' -f8)

function usage () {
    echo 'Usage : Script <password> <username@server address>'
    exit 0
}

if [ "$#" -ne 2 ]
then
  usage
fi

if [ `whoami` = "root" ]
then
    echo "Don't run as root!"
    exit 1
fi

# download the hadoop-2.7.3
wget -c -O $HOME/Downloads/hadoop.tar.gz -t 0 http://mirrors.tuna.tsinghua.edu.cn/apache/hadoop/common/hadoop-2.7.3/hadoop-2.7.3.tar.gz

if [ $? -ne 0 ]
then
    echo "failed, download error, may try again"
    exit 1
fi

# configure the hosts
touch ./hadoopconfigfiles/hosts
echo "127.0.0.1 localhost" > ./hadoopconfigfiles/hosts
echo "$ip hadoop-master" >> ./hadoopconfigfiles/hosts
echo "$server hadoop-slave-1" >> ./hadoopconfigfiles/hosts


expect <<- DONE
    set timeout -1

    # set the hostname of namenode
    spawn sudo hostname hadoop-master
    expect "*?assword*"
    send -- "$password\r"
    expect eof

    # copy the host file to /etc/ in namenode
    spawn sudo cp ./hadoopconfigfiles/hosts /etc/hosts
    expect "*?assword*"
    send -- "$password\r"
    expect eof

    # configure the host file to datanode
    spawn sudo scp -o StrictHostKeyChecking=no ./hadoopconfigfiles/hosts $server:/etc/hosts
    expect "*?assword*"
    send -- "$password\r"
    expect "*?assword*"
    send -- "$password\r"
    expect eof

    # configure unzip the file and rename it
    spawn sudo tar -xzvf $HOME/Downloads/hadoop.tar.gz -C ${hadoop_dir}
    expect "*?assword*"
    send -- "$password\r"
    expect eof
    spawn sudo mv ${hadoop_dir}/hadoop-2.7.3 ${hadoop_dir}/hadoop
    expect "*?assword*"
    send -- "$password\r"
    expect eof

    # change the owner of the folder so that the user can access without sudo
    spawn sudo chown -R $(whoami).$(whoami) ${hadoop_dir}/hadoop
    expect "*?assword*"
    send -- "$password\r"
    expect eof

    # configure the hadoop to namenode
    spawn sudo cp ./hadoopconfigfiles/hadoopenv.sh /etc/profile.d/
    expect "*?assword*"
    send -- "$password\r"
    expect eof
    spawn sudo cp ./hadoopconfigfiles/core-site.xml ${hadoop_dir}/hadoop/etc/hadoop
    expect "*?assword*"
    send -- "$password\r"
    expect eof
    spawn sudo cp ./hadoopconfigfiles/hdfs-site.xml ${hadoop_dir}/hadoop/etc/hadoop
    expect "*?assword*"
    send -- "$password\r"
    expect eof
    spawn sudo cp ./hadoopconfigfiles/mapred-site.xml ${hadoop_dir}/hadoop/etc/hadoop
    expect "*?assword*"
    send -- "$password\r"
    expect eof
    spawn sudo cp ./hadoopconfigfiles/yarn-site.xml ${hadoop_dir}/hadoop/etc/hadoop
    expect "*?assword*"
    send -- "$password\r"
    expect eof
    spawn sudo cp ./hadoopconfigfiles/masters ${hadoop_dir}/hadoop/etc/hadoop
    expect "*?assword*"
    send -- "$password\r"
    expect eof
    spawn sudo cp ./hadoopconfigfiles/slaves ${hadoop_dir}/hadoop/etc/hadoop
    expect "*?assword*"
    send -- "$password\r"
    expect eof

    # stop the firewall and disable the firewall when boot
    spawn sudo systemctl stop firewalld.service
    expect "*?assword*"
    send -- "$password\r"
    expect eof
    spawn sudo systemctl disable firewalld.service
    expect "*?assword*"
    send -- "$password\r"
    expect eof

    # # open some ports which is used by hadoop according to the confiuration
    # spawn sudo firewall-cmd --add-port=9000/tcp --permanent
    # expect "*?assword*"
    # send -- "$password\r"
    # expect eof
    # spawn sudo firewall-cmd --add-port=8031/tcp --permanent
    # expect "*?assword*"
    # send -- "$password\r"
    # expect eof
    # spawn sudo firewall-cmd --add-port=8032/tcp --permanent
    # expect "*?assword*"
    # send -- "$password\r"
    # expect eof
    # spawn sudo firewall-cmd --reload
    # expect "*?assword*"
    # send -- "$password\r"
    # expect eof

    # copy the hadoop to datanodes
    spawn sudo scp -r ${hadoop_dir}/hadoop $server:/usr/local/
    expect "*?assword*"
    send -- "$password\r"
    expect "*?assword*"
    send -- "$password\r"
    expect eof
    spawn sudo scp ./hadoopconfigfiles/hadoopenv.sh $server:/etc/profile.d/
    expect "*?assword*"
    send -- "$password\r"
    expect "*?assword*"
    send -- "$password\r"
    expect eof
DONE

ssh $server << EOF
    expect <<- DONE
        # change the hostname of datanode
        spawn sudo hostname hadoop-slave-1
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

rm ./hadoopconfigfiles/hosts

source /etc/profile.d/hadoopenv.sh

# format the namenode and datanode and start the dfs and yarn
expect <<- DONE
    spawn $HADOOP_HOME/bin/hadoop namenode -format
    expect {
        "*Are you sure you want to continue connecting*" {
            send -- "yes\r"
            exp_continue
        }
        eof
    }

    spawn $HADOOP_HOME/sbin/start-dfs.sh
    expect {
        "*Are you sure you want to continue connecting*" {
            send -- "yes\r"
            exp_continue
        }
        eof
    }

    spawn $HADOOP_HOME/sbin/start-yarn.sh
    expect {
        "*Are you sure you want to continue connecting*" {
            send -- "yes\r"
            exp_continue
        }
        eof
    }
DONE
$HADOOP_HOME/sbin/mr-jobhistory-daemon.sh start historyserver

exit 0

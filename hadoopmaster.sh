#! /bin/bash

hadoop_dir=/usr/local
password=$1
clients=($(./getClientsIP.sh))
ip=$(ip route get 8.8.8.8 | head -1 | cut -d' ' -f8)

function usage () {
    echo 'Usage : Script <password>'
    exit 0
}

# check whether the necessary parameter is empty or not
if [ "$#" -ne 1 ]
then
  usage
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

# download the hadoop-2.7.3
for time in $( seq 1 6 )
do
    if [ "$time" = "6" ]
    then
        echo "Already tried 5 times, all failed, exit"
        exit 1
    fi
    wget -c -O $HOME/Downloads/hadoop.tar.gz -t 0 http://mirrors.tuna.tsinghua.edu.cn/apache/hadoop/common/hadoop-2.7.3/hadoop-2.7.3.tar.gz
    md5=$(md5sum $HOME/Downloads/hadoop.tar.gz | cut -d ' ' -f1)
    md5=$(echo $md5 | tr [a-z] [A-Z])
    result=$?
    if [ "$md5" != "3455BB57E4B4906BBEA67B58CCA78FA8" ]
    then
        echo "md5 check failed, re-downloading"
        rm $HOME/Downloads/hadoop.tar.gz
        continue
    fi
    echo -e "\n md5 check success \n"
    if [ "$result" != "0" ]
    then
        echo "failed, download error, re-downloading"
        rm $HOME/Downloads/hadoop.tar.gz
        continue
    else
        break
    fi
done


# configure the hosts
touch ./hadoopconfigfiles/hosts
echo "127.0.0.1 localhost" > ./hadoopconfigfiles/hosts
echo "$ip hadoop-master" >> ./hadoopconfigfiles/hosts
for x in $( seq 0 `expr ${#clients[@]} - 1` )
do
    echo "${clients[$x]} hadoop-slave-`expr $x + 1`" >> ./hadoopconfigfiles/hosts
    if [ $x -eq 0 ]
    then
        echo "hadoop-slave-`expr $x + 1`" > ./hadoopconfigfiles/slaves
    else
        echo "hadoop-slave-`expr $x + 1`" >> ./hadoopconfigfiles/slaves
    fi
done


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
DONE

source /etc/profile.d/hadoopenv.sh

# # format the namenode and datanode and start the dfs and yarn
# expect <<- DONE
#     spawn $HADOOP_HOME/bin/hadoop namenode -format
#     expect {
#         "*Are you sure you want to continue connecting*" {
#             send -- "yes\r"
#             exp_continue
#         }
#         eof
#     }
#
#     spawn $HADOOP_HOME/sbin/start-dfs.sh
#     expect {
#         "*Are you sure you want to continue connecting*" {
#             send -- "yes\r"
#             exp_continue
#         }
#         eof
#     }
#
#     spawn $HADOOP_HOME/sbin/start-yarn.sh
#     expect {
#         "*Are you sure you want to continue connecting*" {
#             send -- "yes\r"
#             exp_continue
#         }
#         eof
#     }
# DONE
# $HADOOP_HOME/sbin/mr-jobhistory-daemon.sh start historyserver
#
# exit 0

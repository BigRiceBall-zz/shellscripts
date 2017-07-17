#! /bin/bash

hadoop_dir=/usr/local
password=$1
server=$2
ip=$(ip route get 8.8.8.8 | head -1 | cut -d' ' -f8)

if [ `whoami` = "root" ]
then
    echo "Don't run as root!"
    exit 1
fi


wget -c -O ${hadoop_dir}/hadoop.tar.gz -t 0 http://mirrors.tuna.tsinghua.edu.cn/apache/hadoop/common/hadoop-2.7.3/hadoop-2.7.3.tar.gz
if [ $? -ne 0 ]
then
    echo "failed, download error, may try again"
    exit 1
fi

touch ./hadoopconfigfiles/hosts
echo "127.0.0.1 localhost" > ./hadoopconfigfiles/hosts
echo "$ip hadoop-master" >> ./hadoopconfigfiles/hosts
echo "$server hadoop-slave-1" >> ./hadoopconfigfiles/hosts


expect <<- DONE
set timeout -1

# copy the host file to /etc/
spawn sudo cp ./hadoopconfigfiles/hosts /etc/hosts
expect "*?assword*"
send -- "$password\r"
expect eof

# configure the host file to datanode
spawn sudo scp ./hadoopconfigfiles/hosts $server:/etc/hosts
expect "*?assword*"
send -- "$password\r"
expect "*?assword*"
send -- "$password\r"
expect eof

# configure unzip the file and rename it
spawn sudo tar -xzvf ${hadoop_dir}/hadoop.tar.gz -C ${hadoop_dir}
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

# open some ports which is used by hadoop according to the confiuration
spawn sudo firewall-cmd --add-port=9000/tcp --permanent
expect "*?assword*"
send -- "$password\r"
expect eof
spawn sudo firewall-cmd --add-port=8031/tcp --permanent
expect "*?assword*"
send -- "$password\r"
expect eof
spawn sudo firewall-cmd --add-port=8032/tcp --permanent
expect "*?assword*"
send -- "$password\r"
expect eof
spawn sudo firewall-cmd --reload
expect "*?assword*"
send -- "$password\r"
expect eof
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
# change the owner of the folder so that the user can access without sudo
spawn sudo chown -R $(whoami).$(whoami) /usr/local/hadoop
expect "*?assword*"
send -- "$password\r"
expect eof

# open datanode ports
spawn sudo firewall-cmd --add-port=50010/tcp --permanent
expect "*?assword*"
send -- "$password\r"
expect eof
DONE
EOF

rm ./hadoopconfigfiles/hosts

source /etc/profile.d/hadoopenv.sh

$HADOOP_HOME/bin/hadoop namenode -format
$HADOOP_HOME/sbin/start-dfs.sh
$HADOOP_HOME/sbin/start-yarn.sh
$HADOOP_HOME/sbin/mr-jobhistory-daemon.sh start historyserver

# if [ $? -ne 0 ]
# then
#     echo "failed, unzip error, may try again"
#     rm -rf ${hadoop_dir}/hadoop-2.7.3
#     exit 1
# fi
# echo "export HADOOP_HOME=${hadoop_dir}/hadoop" > /etc/profile.d/hadoopenv.sh
# echo "export PATH=$PATH:\$HADOOP_HOME/bin" >> /etc/profile.d/hadoopenv.sh
# echo "export PATH=$PATH:\$HADOOP_HOME/sbin" >> /etc/profile.d/hadoopenv.sh
# echo "export HADOOP_MAPRED_HOME=\$HADOOP_HOME" >> /etc/profile.d/hadoopenv.sh
# echo "export HADOOP_COMMON_HOME=\$HADOOP_HOME" >> /etc/profile.d/hadoopenv.sh
# echo "export HADOOP_HDFS_HOME=\$HADOOP_HOME" >> /etc/profile.d/hadoopenv.sh
# echo "export YARN_HOME=\$HADOOP_HOME" >> /etc/profile.d/hadoopenv.sh
# echo "export HADOOP_COMMON_LIB_NATIVE_DIR=\$HADOOP_HOME/lib/native" >> /etc/profile.d/hadoopenv.sh
# echo "export HADOOP_OPTS=\"-Djava.library.path=\$HADOOP_HOME/lib:\$HADOOP_COMMON_LIB_NATIVE_DIR\"" >> /etc/profile.d/hadoopenv.sh
# echo "export CLASSPATH=\$CLASSPATH:/usr/local/hadoop/lib/*" >> /etc/profile.d/hadoopenv.sh
# source /etc/profile.d/hadoopenv.sh

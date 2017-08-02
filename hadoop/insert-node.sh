#! /bin/bash


working_dir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)
type=$1
client=$2
function usage () {
    echo 'Usage : Script <type> <client>'
    exit 1
}

# check whether the necessary parameter is two or not
if [ "$#" -ne 2 ]
then
    usage
    exit 1
fi

case $type in
    datanode)
        datanodes=($(sed '/^$/d' $HADOOP_HOME/etc/hadoop/slaves | sed '/^#/d' | awk '{print $1}' | sort -k2n | awk '{if ($0!=line) print;line=$0}'))
        num_of_nodes=`expr ${#datanodes[@]} + 1`
        hostname="datanode-$num_of_nodes"
        num_of_service=
        echo $hostname >> $HADOOP_HOME/etc/hadoop/slaves
        echo $hostname >> /etc/hosts
        for x in $( seq 0 `expr ${#clients[@]} - 1` )
        do
        nameservices=($($HADOOP_PREFIX/bin/hdfs getconf -confKey dfs.nameservices | cut -d '@' -f 1))
        echo ${nameservices[0]}
        ;;
        *)
        echo "$type is not a valid node type"
        exit 1
        ;;
esac

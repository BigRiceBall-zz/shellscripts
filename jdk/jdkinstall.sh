#! /bin/bash

password=$1
server=$1
java_dir=/usr/local/java

function usage () {
    echo 'Usage : Script <password> <server address>'
    exit 1
}

# check whether the necessary parameter is empty or not
if [ "$#" -ne 2 ]
then
    usage
    exit 1
fi

for time in $( seq 1 6 )
do
    if [ "$time" = "6" ]
    then
        echo "Already tried 5 times, all failed, exit"
        exit 1
    fi
    wget -c -O $HOME/Downloads/jdk.tar.gz -t 0 --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u141-b15/336fa29ff2bb4ef291e347e091f7f4a7/jdk-8u141-linux-x64.tar.gz
    md5=$(md5sum $HOME/Downloads/jdk.tar.gz | cut -d ' ' -f1)
    if [ "$md5" != "8cf4c4e00744bfafc023d770cb65328c" ]
    then
        echo "md5 check failed, re-downloading"
        rm $HOME/Downloads/jdk.tar.gz
        continue
    fi
    echo -e "\n md5 check success \n"
    break
done
mkdir $java_dir

for time in $( seq 1 6 )
do
    if [ "$time" = "6" ]
    then
        echo "Already tried 5 times, all failed, exit"
        exit 1
    fi
    tar -xzvf $HOME/Downloads/jdk.tar.gz -C $HOME/Downloads
    if [ $? -ne 0 ]
    then
        echo "failed, unzip error, may try again"
        rm -rf $HOME/Downloads/jdk1.8.0_141
    else
        break
    fi
done
mv ${java_dir}/jdk1.8.0_141 ${java_dir}/jdk
touch /etc/profile.d/jdkenv.sh
echo "export JAVA_HOME=${java_dir}/jdk" >> /etc/profile.d/jdkenv.sh
echo "export PATH=$PATH:${java_dir}/jdk/bin" >> /etc/profile.d/jdkenv.sh
source /etc/profile.d/jdkenv.sh
rm ${java_dir}/jdk.tar.gz
exit 0

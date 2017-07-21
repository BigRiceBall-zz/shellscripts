#! /bin/bash


# default java path is /usr/local/java, you can specify the path by passing the arguement.
if [ $# = 0 ]
then
    java_dir=/usr/local/java
else
    java_dir=$1
fi
# check login as root or not.
if [ `whoami` = "root" ]
then
    mkdir $java_dir
    for time in $( seq 1 6 )
    do
        if [ "$time" = "6" ]
        then
            echo "Already tried 5 times, all failed, exit"
            exit 1
        fi
        wget -c -O ${java_dir}/jdk.tar.gz -t 0 --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u141-b15/336fa29ff2bb4ef291e347e091f7f4a7/jdk-8u141-linux-x64.tar.gz
        md5=$(md5sum ${java_dir}/jdk.tar.gz | cut -d ' ' -f1)
        result=$?
        if [ "$md5" != "8cf4c4e00744bfafc023d770cb65328c" ]
        then
            echo "md5 check failed, re-downloading"
            rm ${java_dir}/jdk.tar.gz
            continue
        fi
        echo -e "\n md5 check success \n"
        if [ "$result" != "0" ]
        then
            echo "failed, download error, re-downloading"
            rm ${java_dir}/jdk.tar.gz
            continue
        else
            break
        fi
    done
    for time in $( seq 1 6 )
    do
        if [ "$time" = "6" ]
        then
            echo "Already tried 5 times, all failed, exit"
            exit 1
        fi
        tar -xzvf ${java_dir}/jdk.tar.gz -C ${java_dir}
        if [ $? -ne 0 ]
        then
            echo "failed, unzip error, may try again"
            rm -rf ${java_dir}/jdk1.8.0_141
        else
            break
        fi
    done
    touch /etc/profile.d/jdkenv.sh
    echo "export JAVA_HOME=${java_dir}/jdk1.8.0_141" >> /etc/profile.d/jdkenv.sh
    echo "export PATH=$PATH:${java_dir}/jdk1.8.0_141/bin" >> /etc/profile.d/jdkenv.sh
    # echo "export JAVA_HOME=${java_dir}/jdk1.8.0_131/bin/java" >> $HOME/.bashrc
    # echo "export JAVA_HOME=${java_dir}/jdk1.8.0_131/bin/java" >> $HOME/.profile
    # echo "export PATH=$PATH:${java_dir}/jdk1.8.0_131/bin" >> $HOME/.bashrc
    # echo "export PATH=$PATH:${java_dir}/jdk1.8.0_131/bin" >> $HOME/.profile
    # source $HOME/.bashrc
    # source $HOME/.profile
    source /etc/profile.d/jdkenv.sh
    rm ${java_dir}/jdk.tar.gz
    exit 0
else
    echo "Permission denined, try: sudo javainstall.sh"
    exit 1
fi

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
    wget -c -O ${java_dir}/jdk.tar.gz -t 0 --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.tar.gz
    if [ $? -ne 0 ]
    then
        echo "failed, download error, may try again"
        exit 1
    fi
    tar -xzvf ${java_dir}/jdk.tar.gz -C ${java_dir}
    if [ $? -ne 0 ]
    then
        echo "failed, unzip error, may try again"
        rm -rf ${java_dir}/jdk1.8.0_131
        exit 1
    fi
    touch /etc/profile.d/jdkenv.sh
    echo "export JAVA_HOME=${java_dir}/jdk1.8.0_131/" >> /etc/profile.d/jdkenv.sh
    echo "export PATH=$PATH:${java_dir}/jdk1.8.0_131/bin" >> /etc/profile.d/jdkenv.sh
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

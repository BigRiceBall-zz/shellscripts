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
    tar -xzvf ${java_dir}/jdk.tar.gz -C ${java_dir} --remove-files
    touch /etc/profile.d/jdkenv.sh
    echo "export JAVA_HOME=${java_dir}/jdk1.8.0_131/bin/java" >> /etc/profile.d/jdkenv.sh
    echo "export PATH=$PATH:${java_dir}/jdk1.8.0_131/bin" >> /etc/profile.d/jdkenv.sh
    source /etc/profile.d/jdkenv.sh
    # exit 0
else
    echo "please login as root by runing the following command: sudo -s"
    echo "and then run: source javainstall.sh"
fi

# shellscripts
The main goal of this project is to automate the initial configuration of hadoop.

Note: At present, it only support one namenode and one datanode.

# Run

automatically download java jdk and congfigure enviroment vairables, ssh,
ntp, hadoop. (This script will run pre-config.sh and hadoopconfig.sh together, so you only need to run the following command)

./configure.sh password server


# Explanation of the files

## automatically download java jdk and congfigure enviroment vairables, ssh, ntp in namenode and datanode

./pre-config.sh password server

## automatically download hadoop and configure it in namenode and datanode
./hadoopconfig.sh password server

## automatically configure the NTP server and send configuration to client
./sync.sh password client

## automatically configure the client jdk
./sshautopgconfig.sh client password

## automatically configure ssh that it can assess client without password
./sshwopassconfig.sh client password

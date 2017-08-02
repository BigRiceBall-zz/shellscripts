# shellscripts
The main goal of this project is to automate the initial configuration of hadoop.

### Run
***
automatically configure all including jdk, ntp, ssh, hadoop in server and all clients
(Note: configure the file "clients.xml" in ./clients folder before runing the following command)  
`python hadoopconfig.py password`

automatically download and configure hadoop in server  
`./hadoopmaster.sh password masterhostname`

automatically transfer hadoop to client  
`./hadoopslave.sh password client clienthostname`

automatically download java jdk and congfigure enviroment vairables, ssh, and ntp in server  
`./serverpreconfig.sh password`

automatically transfer java jdk, ssh, and ntp to client      
`./clientpreconfig.sh password client`

# Explanation of the files

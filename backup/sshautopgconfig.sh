#! /bin/bash

function usage () {
    echo 'Usage : Script <username@server address> <password>'
    exit 0
}

if [ "$#" -ne 2 ]
then
  usage
fi

server=$1
password=$2

# filepath=$2
# expect <<- DONE
# spawn scp -P 2222 ./javainstall.sh $server:/tmp/javainstall.sh
# expect "*?assword:*"
# send -- "$password\r"
# expect eof
# DONE

scp -P 2222 -o StrictHostKeyChecking=no ./javainstall.sh $server:/tmp/javainstall.sh
# ssh -t $server << EOF
# # sudo yum install expect
# chmod +x /tmp/javainstall.sh
# expect <<- DONE
# spawn sudo /tmp/javainstall.sh
# expect "*?assword:*"
# send -- "$password\r"
# expect eof
# DONE
# EOF

#login without password and execute the script $filepath
# scp $filepath $server:/tmp/jdkinstall.sh


# expect <<- DONE
#
#     # copy the file to remote tmp
#     spawn scp $filepath $server:/tmp/jdkinstall.sh
#     # Look for passwod prompt
#     expect "*?assword:*"
#     # Send password aka $password
#     send -- "$password\r"
#
#     # auto intsall java
#     spawn ssh -t $server "chmod +x /tmp/jdkinstall.sh && sudo /tmp/jdkinstall.sh"
#     expect "*?assword:*"
#     send -- "$password\r"
#     expect eof
#
# DONE

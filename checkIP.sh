#! /bin/bash


server=$1


function checkIP() {
    if [[ $1 == *@* ]]
    then
        hostname=$(echo $1 | cut -d '@' -f 1)
        IP=$(echo $1 | cut -d '@' -f 2)
        if [ -n "$hostname" ]
        then
            if [[ $IP =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]
            then
                for x in $( seq 1 4 )
                do
                    part=$(echo $IP | cut -d '.' -f $x)
                    if [ $part -ge 255 ] || [ $part -le 0 ]
                    then
                        echo -e "\nIP $server is incorrect.\n"
                        exit 1
                    fi
                done
                echo -e "\nIP $server is correct.\n"
                exit 0
            else
                echo -e "\nIP $server is incorrect.\n"
                exit 1
            fi
        else
            echo -e "\nIP $server is incorrect.\n"
            exit 1
        fi
    else
        if [[ $1 =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]
        then
            for x in $( seq 1 4 )
            do
                part=$(echo $1 | cut -d '.' -f $x)
                if [ $part -ge 255 ] || [ $part -le 0 ]
                then
                    echo -e "\nIP $server is incorrect.\n"
                    exit 1
                fi
            done
            echo -e "\nIP $server is correct.\n"
            exit 0
        else
            echo -e "\nIP $server is incorrect.\n"
            exit 1
        fi
    fi
}

checkIP $server

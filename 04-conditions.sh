#!/bin/bash

ID=$(id -u)

if [ $ID -ne 0 ]; then

    echo " you are not the root user,you dont have permissions to run this "
else
    echo " you are the root user "

fi	
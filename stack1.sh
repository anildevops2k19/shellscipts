#!/bin/bash

log=/tmp/stack.log
ID=$(id -u)
Mod_jk_url=http://mirrors.estointernet.in/apache/tomcat/tomcat-connectors/jk/tomcat-connectors-1.2.46-src.tar.gz
Mod_jk_tar=$(echo $Mod_jk_url | awk -F / '{print $NF}') ##$(echo $Mod_jk_url | cut -d / -f8)
Mod_jk_pack=tomcat-connectors-1.2.46-src

if [ $ID -ne 0 ]; then

    echo " you are not the root user,you dont have permissions to run this "
	exit 1
else
    echo " you are the root user "

fi	

echo " Installing webserver"
yum install httpd -y &>>$log

if [ $? -ne 0 ]; then

    echo " Installing web server ---------- Failed "
	exit 1
else
    echo " Installing web server ---------- Success "

fi

echo " starting the webserver"
systemctl start httpd &>>$log

if [ $? -ne 0 ]; then

    echo " starting the web server ---------- Failed "
	exit 1
else
    echo " starting the web server ---------- Success "

fi

echo " Installing the MOD_JK "

##cd /opt

wget $Mod_jk_url -O /opt/$Mod_jk_tar &>>$log

if [ $? -ne 0 ]; then

    echo " Downloading the mod_jk ---------- Failed "
	exit 1
else
    echo " Downloading the mod_jk ---------- Success "

fi

cd /opt

tar -xf $Mod_jk_tar &>>$log

if [ $? -ne 0 ]; then

    echo " Extracting the mod_jk ---------- Failed "
	exit 1
else
    echo " Extracting the mod_jk ---------- Success "

fi	
	
yum install gcc httpd-devel -y &>>$log


if [ $? -ne 0 ]; then

    echo " Installing the GCC and httpd-devel ---------- Failed "
	exit 1
else
    echo " Installing the GCC and httpd-devel ---------- Success "

fi	

cd $Mod_jk_pack/native


sh configure --with-apxs=/bin/apxs &>>$log && make &>>$log && make install &>>$log
		
if [ $? -ne 0 ]; then

    echo " Compiling the MOD_JK ---------- Failed "
	exit 1
else
    echo " Compiling the MOD_JK  ---------- Success "

fi

cd /etc/httpd/conf.d

echo 'LoadModule jk_module modules/mod_jk.so
JkWorkersFile conf.d/workers.properties
JkLogFile logs/mod_jk.log
JkLogLevel info
JkLogStampFormat "[%a %b %d %H:%M:%S %Y]"
JkOptions +ForwardKeySize +ForwardURICompat -ForwardDirectories
JkRequestLogFormat "%w %V %T"
JkMount /student tomcatA
JkMount /student/* tomcatA' > mod_jk.conf

if [ $? -ne 0 ]; then

    echo " Creating the mod_jk.conf ---------- Failed "
	exit 1
else
    echo " Creating the mod_jk.conf ---------- Success "

fi


echo '### Define workers
worker.list=tomcatA
### Set properties
worker.tomcatA.type=ajp13
worker.tomcatA.host=localhost
worker.tomcatA.port=8009' > workers.properties

if [ $? -ne 0 ]; then

    echo " Creating the workers.properties ---------- Failed "
	exit 1
else
    echo " Creating the workers.properties ---------- Success "

fi

systemctl restart httpd 


if [ $? -ne 0 ]; then

    echo " Restarting the webserver ---------- Failed "
	exit 1
else
    echo " Restarting the webserver ---------- Success "

fi

echo " Installing the application server"

yum install java -y &>>log

wget http://mirrors.estointernet.in/apache/tomcat/tomcat-9/v9.0.19/bin/apache-tomcat-9.0.19.tar.gz -O /opt/apache-tomcat-9.0.19.tar.gz &>>log

if [ $? -ne 0 ]; then

    echo " Downloading the tomcat application ---------- Failed "
	exit 1
else
    echo " Downloading the tomcat application ---------- Success "

fi


cd /opt

tar -xf apache-tomcat-9.0.19.tar.gz &>>$log

if [ $? -ne 0 ]; then

    echo " Extracting the tomcat application ---------- Failed "
	exit 1
else
    echo " Extracting the tomcat application ---------- Success "

fi	

cd 	apache-tomcat-9.0.19/bin

sh startup.sh  &>>$log

if [ $? -ne 0 ]; then

    echo " starting the tomcat application ---------- Failed "
	exit 1
else
    echo " starting the tomcat application ---------- Success "

fi	

cd /opt/apache-tomcat-9.0.19/webapps

wget https://github.com/devops2k18/DevOpsDecember/raw/master/APPSTACK/student.war &>>log

if [ $? -ne 0 ]; then

    echo " Downloading the studentfile ---------- Failed "
	exit 1
else
    echo " Downloading the studentfile ---------- Success "

fi	

cd /opt/apache-tomcat-9.0.19/lib

wget https://github.com/devops2k18/DevOpsDecember/raw/master/APPSTACK/mysql-connector-java-5.1.40.jar &>>log

if [ $? -ne 0 ]; then

    echo " Downloading the mysqlconnector ---------- Failed "
	exit 1
else
    echo " Downloading the mysqlconnector---------- Success "

fi	

cd 	/opt/apache-tomcat-9.0.19/bin 

sh shutdown.sh &>>log

if [ $? -ne 0 ]; then

    echo " stopping the tomcat application ---------- Failed "
	exit 1
else
    echo " stoping the tomcat application---------- Success "

fi	


sh startup.sh &>>log

if [ $? -ne 0 ]; then

    echo " restarting the tomcat application ---------- Failed "
	exit 1
else
    echo " restarting the tomcat application--------- Success "

fi	


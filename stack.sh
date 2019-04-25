#!/bin/bash

log=/tmp/stack.log
ID=$(id -u)
Mod_jk_url=http://mirrors.estointernet.in/apache/tomcat/tomcat-connectors/jk/tomcat-connectors-1.2.46-src.tar.gz
Mod_jk_tar=$(echo $Mod_jk_url | awk -F / '{print $NF}') ##$(echo $Mod_jk_url | cut -d / -f8)
Mod_jk_pack=$(echo $Mod_jk_tar | sed -e 's/.tar.gz//')
Tomcat_url=http://mirrors.estointernet.in/apache/tomcat/tomcat-9/v9.0.19/bin/apache-tomcat-9.0.19.tar.gz
Tomcat_tar=$(echo $Tomcat_url | awk -F / '{print $NF}')
Tomcat_pack=$(echo $Tomcat_tar | sed -e 's/.tar.gz//')
Mysql_connector=https://github.com/devops2k18/DevOpsDecember/raw/master/APPSTACK/mysql-connector-java-5.1.40.jar
Student_war=https://github.com/devops2k18/DevOpsDecember/raw/master/APPSTACK/student.war
R="\e[31m"
G="\e[32m"
Y="\e[33m"
B="\e[34m"
C="\e[36m"
N="\e[0m"


if [ $ID -ne 0 ]; then

    echo -e " $R you are not the root user,you dont have permissions to run this $N "
	exit 1
else
    echo -e " $C you are the root user $N "

fi	 

echo -e " $B Installing webserver $N"
yum install httpd -y &>>$log

skip() {


    echo -e " $1 ---------- $Y skipping $N "

}

Validate() {
if [ $1 -ne 0 ]; then

    echo -e " $2 ---------- $R Failed $N  "
	exit 1
else
    echo -e " $2 ---------- $G Success $N "

fi
}
Validate $? "Installing the webserver"

systemctl start httpd &>>$log

Validate $? "starting the webserver"

##cd /opt

if [ -f /opt/$Mod_jk_tar ] ; then 
    skip "downloading the modjk"
else	
	wget $Mod_jk_url -O /opt/$Mod_jk_tar &>>$log
	Validate $? "downloading the modjk"
fi	

cd /opt

if [ -d /opt/$Mod_jk_pack ] ; then 
    skip "extracting  the modjk"
else	
	tar -xf $Mod_jk_tar &>>$log
	Validate $? "Extracting the modjk"
fi	

	
yum install gcc httpd-devel -y &>>$log

Validate $? "Installing the GCC and httpd-devel"

if [ -f /etc/httpd/modules/mod_jk.so ] ; then

       skip "Compiling the mod_jk.so"   
else	   
	   cd $Mod_jk_pack/native
	   sh configure --with-apxs=/bin/apxs &>>$log && make &>>$log && make install &>>$log
       Validate $? "Compiling the MOD_JK"	
fi	   

cd /etc/httpd/conf.d

if [ -f /etc/httpd/conf.d/mod_jk.conf ] ; then

       skip "Mod_jk.conf file is exists so"   
else	   
	echo 'LoadModule jk_module modules/mod_jk.so
	JkWorkersFile conf.d/workers.properties
	JkLogFile logs/mod_jk.log
	JkLogLevel info
	JkLogStampFormat "[%a %b %d %H:%M:%S %Y]"
	JkOptions +ForwardKeySize +ForwardURICompat -ForwardDirectories
	JkRequestLogFormat "%w %V %T"
	JkMount /student tomcatA
	JkMount /student/* tomcatA' > mod_jk.conf

	Validate $? "Creating the mod_jk.conf"
fi	

if [ -f /etc/httpd/conf.d/workers.properties ] ; then

       skip "workers.properties file exists so"   
else	   
		echo '### Define workers
		worker.list=tomcatA
		### Set properties
		worker.tomcatA.type=ajp13
		worker.tomcatA.host=localhost
		worker.tomcatA.port=8009' > workers.properties

		Validate $? "Creating the workers.properties"
fi

systemctl restart httpd 


Validate $? "Restarting the web server"

echo -e " $B Installing the application server $N "

yum install java -y &>>log

if [ -f /opt/$Tomcat_tar ] ; then 
    skip "Downloading the tomcat tar file is"
else	
	wget $Tomcat_url -O /opt/$Tomcat_tar &>>log

	Validate $? "Downloading the Tomcat"
fi

cd /opt

if [ -d /opt/$Tomcat_pack ] ; then 
    skip "extracting the tomcat directory is"
else	
	
	tar -xf $Tomcat_tar &>>$log
	Validate $? "Extracting the tomcat"
fi	
	
cd 	apache-tomcat-9.0.19/bin

cd /opt/apache-tomcat-9.0.19/webapps

wget $Student_war &>>log

Validate $? "Downloading the student.war"

cd /opt/apache-tomcat-9.0.19/lib
if [ -f /opt/apache-tomcat-9.0.19/lib/mysql-connector-java-5.1.40.jar ] ; then 
    skip "Downloading the tomcat connector is"
else	
	
	wget $Mysql_connector &>>log

	Validate $? "Downloading the mysql-connector-java-5.1.40.jar"
fi	

cd /opt/apache-tomcat-9.0.19/conf

sed -i -e '/TestDB/ d' context.xml

sed -i -e '$ i <Resource name="jdbc/TestDB" auth="Container" type="javax.sql.DataSource" maxTotal="100" maxIdle="30" maxWaitMillis="10000" username="student" password="student@1" driverClassName="com.mysql.jdbc.Driver" url="jdbc:mysql://localhost:3306/studentapp"/>' context.xml

	Validate $? "Adding database info to the application server"

cd 	/opt/apache-tomcat-9.0.19/bin

sh startup.sh &>>log

Validate $? "Starting the tomcat"

echo -e " $B Installing the mariadb server $N "

yum install mariadb mariadb-server -y &>>$log

Validate $? "Installing the mariadb client and mariadb-server"

systemctl enable mariadb &>>$log

systemctl start mariadb &>>$log

Validate $? " starting the mariadb "

echo "create database if not exists studentapp;
use studentapp;
CREATE TABLE if not exists Students(student_id INT NOT NULL AUTO_INCREMENT,
	student_name VARCHAR(100) NOT NULL,
    student_addr VARCHAR(100) NOT NULL,
	student_age VARCHAR(3) NOT NULL,
	student_qual VARCHAR(20) NOT NULL,
	student_percent VARCHAR(10) NOT NULL,
	student_year_passed VARCHAR(10) NOT NULL,
	PRIMARY KEY (student_id)
);
grant all privileges on studentapp.* to 'student'@'localhost' identified by 'student@1';" >/opt/student.sql

Validate $? " creating the student.sql file "

mysql </opt/student.sql





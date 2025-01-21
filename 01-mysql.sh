#!/bin/bash
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/expense-shell-logs"
LOG_FILE=$(echo $0 | cut -d '.' -f1)
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE_NAME="$LOGS_FOLDER/$LOG_FILE-$TIMESTAMP.log"

USERID=$(id -u)

VALIDATE(){
    if [ $1 -ne 0 ]
    then 
        echo -e "$2... $R Failure" $N
        exit 1
    else 
        echo -e "$2... $G success" $N
    fi
}
CHECK_ROOT(){
    if [ $USERID -ne 0 ]
    then 
        echo -e $R "ERROR:: You must have sudo access to execute the script" $N
        exit 1
    fi
}
CHECK_ROOT

echo "script started executing at :$TIMESTAMP" &>>$LOG_FILE_NAME

if [ $USERID -ne 0 ]
then
    echo -e $R "ERROR: YOU NEED TO LOGIN WITH SUDO"
    exit 1
fi
dnf install mysql-server -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing MYSQL-SERVER..."
systemctl enable mysqld &>>$LOG_FILE_NAME
VALIDATE $? "Enabling Mysql..."
systemctl start mysqld &>>$LOG_FILE_NAME
VALIDATE $? "Starting mysql..."
mysql_secure_installation --set-root-pass ExpenseApp@1 &>>$LOG_FILE_NAME
mysql -h mysql.daws-82s.store -u root -pExpenseApp@1 -e "show databases;" &>>$LOG_FILE_NAME
if [ $? -ne 0 ]
then 
    echo "MYSQL SERVER root password not setup"
    VALIDATE $? "SETUP root password"
else
    echo "ROOT password alredy setup"
fi
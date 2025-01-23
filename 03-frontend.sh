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
mkdir -p /var/log/expense-shell-logs
if [ $? -ne 0 ]
then 
    echo "LOGs_FOLDER is not created" &>>$LOGS_FOLDER
    VALIDATE $? "LOGs_FOLDER is creating..."
else
    echo ""
fi
dnf install nginx -y &>>$LOGS_FOLDER
VALIDATE $? "Installing NGINX..."
systemctl enable nginx &>>$LOGS_FOLDER
VALIDATE $? "Enabling NGINX..."
systemctl starting nginx &>>$LOGS_FOLDER
VALIDATE $? "Starting NGINX..."
rm -rf /usr/share/nginx/html/* &>>$LOGS_FOLDER
VALIDATE $? "Removing the files from /usr/share/nginx/html/"
curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip &>>$LOGS_FOLDER
VALIDATE $? "copy the files into frontend.zip"
cd /usr/share/nginx/html &>>$LOGS_FOLDER
VALIDATE $? "Changing the directories.."
unzip /tmp/frontend.zip &>>$LOGS_FOLDER
VALIDATE $? "Unzip the frontend files.."
systemctl restart nginx &>>$LOGS_FOLDER
VALIDATE $? "Restarting the nginx.."

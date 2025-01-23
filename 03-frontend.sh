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

mkdir -p $LOGS_FOLDER
echo "script started executing at :$TIMESTAMP" &>>$LOG_FILE_NAME
CHECK_ROOT

if [ $USERID -ne 0 ]
then
    echo -e $R "ERROR: YOU NEED TO LOGIN WITH SUDO"
    exit 1
fi

dnf install nginx -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing NGINX..."
systemctl enable nginx &>>$LOG_FILE_NAME
VALIDATE $? "Enabling NGINX..."
systemctl start nginx &>>$LOG_FILE_NAME
VALIDATE $? "Starting NGINX..."
rm -rf /usr/share/nginx/html/* &>>$LOG_FILE_NAME
VALIDATE $? "Removing existing version of code"
curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip &>>$LOG_FILE_NAME
VALIDATE $? "Downloading latest code"
cd /usr/share/nginx/html &>>$LOG_FILE_NAME
VALIDATE $? "Moving to html code.."
unzip /tmp/frontend.zip &>>$LOG_FILE_NAME
VALIDATE $? "Unzip the frontend files.."
cp /home/ec2-user/expense-shell/expense.conf /etc/nginx/default.d/expense.conf
VALIDATE $? "Copying the config files..."
systemctl restart nginx &>>$LOG_FILE_NAME
VALIDATE $? "Restarting the nginx.."

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
dnf module disable nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "Disabling nodejs..."
dnf module enable nodejs:20 -y &>>$LOG_FILE_NAME
VALIDATE $? "Enabling nodejs..."
dnf install nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing nodejs..."
id expense &>>$LOG_FILE_NAME
if [ $? -ne 0 ]
then 
    useradd expense &>>$LOG_FILE_NAME
    VALIDATE $? "Adding user to expense app..."
else
    echo -e "Expense user exists already...$Y SKIPPING" $N
fi
mkdir -p /app &>>$LOG_FILE_NAME
VALIDATE $? "Make an directory to app..."
curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOG_FILE_NAME
VALIDATE $? "Download application code to created app directory..." 
cd /app &>>$LOG_FILE_NAME
unzip /tmp/backend.zip &>>$LOG_FILE_NAME
VALIDATE $? "Unzip backend..."
npm install &>>$LOG_FILE_NAME
VALIDATE $? "Install dependencies..."
cp /home/ec2-user/expense-shell/backend.service /etc/systemd/system/backend.service &>>$LOG_FILE_NAME
VALIDATE $? "Copying backend.service to services folder..."

#prepare mysql scheme
dnf install mysql -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing mysql..."
mysql -h mysql.daws-82s.store -uroot -pExpenseApp@1 < /app/schema/backend.sql &>>$LOG_FILE_NAME
VALIDATE $? "Setting up the transaction schema and table..."

systemctl daemon-reload &>>$LOG_FILE_NAME
VALIDATE $? "Reload the backend..."
systemctl enable backend &>>$LOG_FILE_NAME
VALIDATE $? "Enabling backend..."
systemctl start backend &>>$LOG_FILE_NAME
VALIDATE $? "Starting backend..."
#!/bin/bash
# Ask the user for their os name
echo "Please Enter the name of Operating System in which you are install this code-deploy agent like ubuntu or centOs"
read osname
serverName=$1
echo $osname
if [ "$osname" != "ubuntu" ] && [ "$osname" != "centOs" ]; then
    echo "$(tput setaf 1)"
    echo "Please provide your os name as ubuntu or centOs.Other kind of formation is not allowed here."
    echo "$(tput sgr0)"
    exit
fi

echo "Hello"
aws s3 cp s3://masterops/stage/tempJson/iam.json iam.json
aws cloudformation create-stack --stack-name "iam-user-$serverName" --template-body file://iam.json --parameters ParameterKey=UserArnName,ParameterValue=$serverName --capabilities CAPABILITY_NAMED_IAM
echo "Please wait user is creating"
sleep 5s
stackStatus=`aws cloudformation describe-stacks --stack-name iam-user-$serverName --query 'Stacks[*].[StackStatus]' --output text`

if [ "$stackStatus" != "CREATE_COMPLETE" ]; then
    while [ "$stackStatus" != "CREATE_COMPLETE" ] 
    do
        sleep 60s
        stackStatus=`aws cloudformation describe-stacks --stack-name iam-user-$serverName --query 'Stacks[*].[StackStatus]' --output text`
        echo "Please wait user creation is in process.It will take time."
        if [ "$stackStatus" = "UPDATE_ROLLBACK_COMPLETE" ]; then
          echo "$(tput setaf 1)"
          echo "User Creation is failed. Please contact administrator."
          echo "$(tput sgr0)"
          exit
        fi
    done
fi

aws iam get-user --user-name $serverName > arn.json
arn=$(jq ".User.Arn" arn.json)
arn=`echo "$arn" | tr -d '"'`

rm -rf arn.json
rm -rf iam.json

aws iam create-access-key --user-name $serverName > credential.json
AccessKeyId=$(jq ".AccessKey.AccessKeyId" credential.json)
AccessKeyId=`echo "$AccessKeyId" | tr -d '"'`

SecretAccessKey=$(jq ".AccessKey.SecretAccessKey" credential.json)
SecretAccessKey=`echo "$SecretAccessKey" | tr -d '"'`
rm -rf credential.json

template='{"aws_access_key_id": %s,"aws_secret_access_key":%s ,"iam_user_arn": %s,"region":"ap-south-1"}'
json_string=$(printf "$template" $AccessKeyId $SecretAccessKey $arn)
echo $json_string > fileName.json
yq eval -P fileName.json > codedeploy.onpremises.yml
rm fileName.json

echo "Code deploy agent is installing"
sudo mkdir -p /etc/codedeploy-agent/conf
cp codedeploy.onpremises.yml  /etc/codedeploy-agent/conf

if [ $osname = "ubuntu" ]; then
    sudo apt update
    sudo apt install ruby-full
    sudo apt install wget
fi

if [ $osname = "centOs" ]; then
    yum update
    yum install ruby
    yum install wget
fi

wget https://aws-codedeploy-ap-south-1.s3.ap-south-1.amazonaws.com/latest/install	
chmod +x ./install
sudo ./install auto  /tmp/logfile
aws deploy register-on-premises-instance --instance-name $serverName --iam-user-arn $arn
aws deploy add-tags-to-on-premises-instances --instance-names $serverName --tags Key=Name,Value=$serverName

rm -rf codedeploy.onpremises.yml
echo "Code Deploy agent is installed"

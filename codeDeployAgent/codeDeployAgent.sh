#!/bin/bash
serverName=$1
aws s3 cp s3://masterops/codeDeployAgent/codeDeploy.sh .
chmod +x codeDeploy.sh
echo "Installing code deploy agent on your server"
./codeDeploy.sh $serverName
echo "Code deploy agent is installed"
rm codeDeploy.sh
#!/bin/bash
cd #path/#project/#branch/#repo

branch=#branch

Want_To_Encrypt=`jq -r ".deployments.${branch}.build.encryption.wantToEncrypt" devops.json`
repo_folder_name=#repo
DIRNAME=#project
CONFIRM_ENCRYPT_TYPE=`jq -r ".deployments.${branch}.build.encryption.confirmEncryptType" devops.json`
EXPIRE_ON=`jq -r ".deployments.${branch}.build.encryption.expireOn" devops.json`



cd /home/php7encode
./enc1.sh $Want_To_Encrypt $repo_folder_name $DIRNAME $CONFIRM_ENCRYPT_TYPE $EXPIRE_ON $branch

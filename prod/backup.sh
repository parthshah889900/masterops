#!/bin/bash
cd #livepath/public_html
isBackup=#backup
if [ $isBackup == true ]; then 
    fileName=`date "+%d_%m_%y__%H_%M_%S"`
    aws s3 cp s3://#bucket-onprintshop/#change/Rollback/rollback.zip rollback.zip
    unzip -o rollback.zip
    file6=rollback.sh
    sed -i "s|#datetime|$fileName|g" $file6
    rm -rf rollback.zip
    zip -r $fileName . -x \devops.json robots.txt sitemap.xml vendor\* images\* cache\* localconfig\*
    aws s3 cp $fileName.zip s3://#bucket-onprintshop/#change/Backup/
    rm -rf $fileName.zip
    rm -rf appspec.yml
    rm -rf rollback.sh
    rm -rf delete.sh
fi
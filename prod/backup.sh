#!/bin/bash
cd #livepath

if [ ! -d "#proj" ]; then
    sudo mkdir -p #proj/#change
    sudo chown -R devops:devops #proj
    cd #proj/#change
    mkdir public_html
fi

cd #livepath

if [ ! -d #livepath/#proj/#change ]; then
    cd #proj
    mkdir #change
    cd #change
    mkdir public_html
fi

gitCloneProperty=#isGit
if [ "$gitCloneProperty" = "true" ]; then
    cd #livepath/#proj/#change
    if [ ! -d "#proj" ]; then
        git clone #gitUrl
        cd #proj
        git checkout #change
    fi
fi

cd #livepath/#proj/#change/public_html

fileName=`date "+%d_%m_%y__%H_%M_%S"`
aws s3 cp s3://#bucket-onprintshop/#change/Rollback/rollback.zip rollback.zip
unzip -o rollback.zip
file6=rollback.sh
sed -i "s|#datetime|$fileName|g" $file6
rm -rf rollback.zip
zip -r $fileName . -x \devops.json robots.txt sitemap.xml vendor\* images\* cache\*
aws s3 cp $fileName.zip s3://#bucket-onprintshop/#change/Backup/
rm -rf $fileName.zip
rm -rf appspec.yml
rm -rf rollback.sh
rm -rf delete.sh

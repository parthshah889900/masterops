#!/bin/bash

cd #livepath/public_html
aws s3 cp s3://#bucket-onprintshop/#change/Artifact/artifact.zip artifact.zip
project=#bucket
unzip -o artifact.zip
declare -a myArray
filename=deletefiles.txt
myArray=(`cat "$filename"`)
for (( i = 0 ; i < ${#myArray[@]} ; i++))
do
    if [ -e ${myArray[$i]} ]; then
        echo ${myArray[$i]}
        rm ${myArray[$i]}
    fi
done

declare -a myArray2
filename2=deletefiles2.txt
myArray2=(`cat "$filename2"`)
for (( i = 0 ; i < ${#myArray2[@]} ; i++))
do
    if [ -e ${myArray2[$i]} ]; then
        echo ${myArray2[$i]}
        rm -rf ${myArray2[$i]}
    fi
done

rm -rf artifact.zip

aws s3 ls s3://#bucket-onprintshop| awk '{print $2}' > folderName.txt
variable=(`cat "folderName.txt"`)
rm -rf folderName.txt

cd ..
if [[ ${variable[@]} =~ "additionalArtifact/" ]]; then
    if [ ! -d "temp" ]; then
        mkdir temp
    fi
    cd temp/
    aws s3 cp s3://#bucket-onprintshop/additionalArtifact/additionalArtifact.zip additionalArtifact.zip
    unzip -o additionalArtifact.zip
    cd ..
    actionUploadNumber=`jq ".build.action.upload | length" public_html/upload.json`
    for (( i=0; i<actionUploadNumber; i++ ))
    do 
        uploadDestination=$(jq ".build.action.upload[$i].destination" public_html/upload.json)
        uploadDestination=`echo "$uploadDestination" | tr -d '"'`
        source=$(jq ".build.action.upload[$i].source" public_html/upload.json)
        source=`echo "$source" | tr -d '"'`
        permission=$(jq ".build.action.upload[$i].permission" public_html/upload.json)
        permission=`echo "$permission" | tr -d '"'`
        folder=`echo ${source##*/}`
        if [ $permission = true ]; then
            cd temp/
            chmod -R 777 $folder
            cd ..
        fi
        if [ ! -d $uploadDestination ]; then
            mkdir -p $uploadDestination
        fi 
        cp -rp temp/$folder  #livepath/$uploadDestination    
    done
    rm -rf temp/
    aws s3 rm s3://#bucket-onprintshop/additionalArtifact --recursive
else 
    echo "not contain"
fi

cd #livepath/public_html
if [ ! -d vendor ]; then
    composer install
fi

if [ ! -d cache ]; then
    mkdir cache
    chmod -R 777 cache
fi

if [ ! -f robots.txt ]; then
    touch robots.txt
    chmod 777 robots.txt
fi
if [ ! -f sitemap.xml ]; then
    touch sitemap.xml
    chmod 777 sitemap.xml
fi
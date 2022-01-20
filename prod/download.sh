#!/bin/bash

cd #livepath/#proj/#change/public_html
aws s3 cp s3://#bucket-onprintshop/#change/Artifact/artifact.zip artifact.zip

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
rm -rf artifact.zip
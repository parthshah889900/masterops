#!/bin/bash
branch=$1

assetNumber=`jq ".deployments.${branch}.build.gitPush | length" devops.json`

if [ ! -d "assets" ]; then
    mkdir assets
fi

for (( i=0; i<$assetNumber; i++ ))
do
    source=$(jq ".deployments.${branch}.build.gitPush[$i].source" devops.json)
    destination=$(jq ".deployments.${branch}.build.gitPush[$i].destination" devops.json)

    source=`echo "$source" | tr -d '"'`
    destination=`echo "$destination" | tr -d '"'`

    cd $source
    cp -r $source $destination
done

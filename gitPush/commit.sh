#!/bin/bash

cd #livepath/#project/#branch/#repo

git stash
git pull

artifactNumber=`jq ".deployments.#branch.build.gitPush | length" devops.json`

for (( i=0; i<$artifactNumber; i++ ))
do
        assetsSource=$(jq ".deployments.#branch.build.gitPush[$i].source" devops.json)
        assetsSource=`echo "$assetsSource" | tr -d '"'`

        assetsDestination=$(jq ".deployments.#branch.build.gitPush[$i].destination" devops.json)
        assetsDestination=`echo "$assetsDestination" | tr -d '"'`

        if [ ! -d $assetsDestination ]; then
            mkdir -p $assetsDestination
        fi

        cp -r #livepath/#project/#branch/public_html$assetsSource #livepath/#project/#branch/#repo$assetsDestination
done

git add .
git commit -m "add $assetsDestination"

git push

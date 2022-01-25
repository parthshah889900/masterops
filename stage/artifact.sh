#!/bin/bash

cd #path
branch=#branch
project=#project
repo=#repo
fileB=backup.sh
file2=download.sh
livepath=#prod
gitClone=#git_url
gitWant=`jq ".deployments.${branch}.codeRunner.isGitClone" #path/#project/#branch/#repo/devops.json`
gitWant=`echo "$gitWant" | tr -d '"'`
prodServerUser=`jq ".deployments.${branch}.codeRunner.serverUser" #path/#project/#branch/#repo/devops.json` 
gitNumber=`jq ".deployments.${branch}.build.includeArtifact | length" #path/#project/#branch/#repo/devops.json`


for (( i=0; i<$gitNumber; i++ ))
do
    assetUrl=$(jq ".deployments.${branch}.build.includeArtifact[$i].sourceControl.url" #path/#project/#branch/#repo/devops.json)
    assetUrl=`echo "$assetUrl" | tr -d '"'`

    disabled=$(jq ".deployments.${branch}.build.includeArtifact[$i].sourceControl.disabled" #path/#project/#branch/#repo/devops.json)
    disabled=`echo "$disabled" | tr -d '"'`

    if [ "$disabled" != "true" ]; then
        if [ "$assetUrl" != "" ]; then
            assetBranch=$(jq ".deployments.${branch}.build.includeArtifact[$i].sourceControl.branch" #path/#project/#branch/#repo/devops.json)
            assetBranch=`echo "$assetBranch" | tr -d '"'`

            readarray -d / -t variable<<< $assetUrl
            variable=`echo ${variable[-1]}`
            repoFolder=`echo "${variable::-4}"`

            if [ ! -d $repoFolder ]; then
                mkdir $repoFolder
                cd $repoFolder
                mkdir $assetBranch
                cd $assetBranch
                git clone $assetUrl
                cd $repoFolder
                git checkout $assetBranch
                cd ../../..
            fi

            if [ -d $repoFolder ]; then
                if [ ! -d $repoFolder/$assetBranch ]; then
                    cd $repoFolder
                    mkdir $assetBranch
                    cd $assetBranch
                    git clone $assetUrl
                    cd $repoFolder
                    git checkout $assetBranch
                    cd ../../..
                else
                    cd $repoFolder/$assetBranch/$repoFolder
                    git pull
                    cd ../../..
                fi
            fi
        fi
    fi
done


destinationPath="$project/$branch/artifact"

#files are copies through here:
includeArtifactNumber=`jq ".deployments.${branch}.build.includeArtifact | length" #path/#project/#branch/#repo/devops.json`
for (( j=0; j<$includeArtifactNumber; j++ ))
do

    disabled=$(jq ".deployments.${branch}.build.includeArtifact[$j].sourceControl.disabled" #path/#project/#branch/#repo/devops.json)
    disabled=`echo "$disabled" | tr -d '"'`

    if [ "$disabled" != "true" ]; then
        assetNumber=`jq ".deployments.${branch}.build.includeArtifact[$j].assets | length" #path/#project/#branch/#repo/devops.json`
        for (( i=0; i<$assetNumber; i++ ))
        do
            assetsDestination=$(jq ".deployments.${branch}.build.includeArtifact[$j].assets | .[$i].destination" #path/#project/#branch/#repo/devops.json)
            assetsDestination=`echo "$assetsDestination" | tr -d '"'`
            if [ ! -d $destinationPath/$assetsDestination ]; then
                mkdir -p $destinationPath/$assetsDestination
            fi
            assetsSource=$(jq ".deployments.${branch}.build.includeArtifact[$j].assets | .[$i].source" #path/#project/#branch/#repo/devops.json)
            assetsSource=`echo "$assetsSource" | tr -d '"'` 

            assetUrl=$(jq ".deployments.${branch}.build.includeArtifact[$j].sourceControl.url" #path/#project/#branch/#repo/devops.json)
            assetUrl=`echo "$assetUrl" | tr -d '"'`

            if [ "$assetUrl" != "" ]; then
                assetBranch=$(jq ".deployments.${branch}.build.includeArtifact[$j].sourceControl.branch" #path/#project/#branch/#repo/devops.json)
                assetBranch=`echo "$assetBranch" | tr -d '"'`

                readarray -d / -t variable<<< $assetUrl
                variable=`echo ${variable[-1]}`
                repoFolder=`echo "${variable::-4}"`
                cp -r $repoFolder/$assetBranch/$repoFolder/$assetsSource $destinationPath/$assetsDestination
            else
                cp -r #project/#branch/#repo/$assetsSource #project/#branch/artifact/$assetsDestination
            fi
        done
    fi
done

excludeArtifactNumber=`jq ".deployments.${branch}.build.excludeArtifact | length" #path/#project/#branch/#repo/devops.json`
for (( i=0; i<$excludeArtifactNumber; i++ ))
do    
    source=$(jq ".deployments.${branch}.build.excludeArtifact[$i].source" #path/#project/#branch/#repo/devops.json)
    source=`echo "$source" | tr -d '"'`

    fileNumber=`jq ".deployments.${branch}.build.excludeArtifact[$i].file | length" #path/#project/#branch/#repo/devops.json`
    
    for (( j=0; j<$fileNumber; j++ ))
    do    
        file=$(jq ".deployments.master.build.excludeArtifact[$i].file[$j]" #path/#project/#branch/#repo/devops.json)
        file=`echo "$file" | tr -d '"'`
        rm #project/#branch/artifact$source/$file
    done
done

#zip for artifact is creating
cd #path/#project/#branch/artifact

rm .gitlab-ci.yml
rm devops.json
rm -rf node_modules
rm -rf .git
rm -rf .gitignore
rm -f ..gitignore.swp
rm CONTRIBUTING.md
rm package.json
rm -rf vendor
rm -rf .vscode
rm -rf .history
rm -rf changedfiles.txt
rm -rf setupDeployment.sh


zip -r artifact.zip .
aws s3 cp artifact.zip s3://#project-onprintshop/#branch/Artifact/
sleep 1s
cd ..
rm -rf artifact/*
rm -rf artifact/.*

cd artifact
# live side zip created
aws s3 cp s3://masterops/prod/ . --recursive

sed -i "s|#bucket|$project|g" $fileB
sed -i "s|#bucket|$project|g" $file2
sed -i "s|#proj|$project|g" $fileB
sed -i "s|#proj|$project|g" $file2
sed -i "s|#livepath|$livepath|g" $fileB
sed -i "s|#livepath|$livepath|g" $file2
sed -i "s|#change|$branch|g" $fileB
sed -i "s|#change|$branch|g" $file2
sed -i "s|#isGit|$gitWant|g" $fileB
sed -i "s|#gitUrl|$gitClone|g" $fileB

template='{"version":0.0,"os":"linux","hooks":{"ApplicationStart":[{"location":"backup.sh","timeout":300,"runas":%s}],"ValidateService":[{"location":"download.sh","timeout":300,"runas":%s}]}}'
json_string=$(printf "$template" $prodServerUser $prodServerUser)
echo $json_string > fileName.json
yq eval -P fileName.json > appspec.yml
rm fileName.json

zip -r prod.zip .
aws s3 cp prod.zip s3://#project-onprintshop/#branch/Prod/
cd ..
rm -rf artifact/*

cd artifact

# rollback side source created
aws s3 cp s3://masterops/rollback/ . --recursive
file3=delete.sh
file4=rollback.sh


sed -i "s|#livepath|$livepath|g" $file3
sed -i "s|#proj|$project|g" $file3
sed -i "s|#change|$branch|g" $file3
sed -i "s|#livepath|$livepath|g" $file4
sed -i "s|#proj|$project|g" $file4
sed -i "s|#change|$branch|g" $file4
sed -i "s|#bucket|$project|g" $file4

template='{"version":0.0,"os":"linux","hooks":{"ApplicationStart":[{"location":"delete.sh","timeout":300,"runas":%s}],"ValidateService":[{"location":"rollback.sh","timeout":300,"runas":%s}]}}'
json_string=$(printf "$template" $prodServerUser $prodServerUser)
echo $json_string > fileName.json
yq eval -P fileName.json > appspec.yml
rm fileName.json

zip -r rollback.zip .
aws s3 cp rollback.zip s3://#project-onprintshop/#branch/Rollback/

cd ..
rm -rf artifact/*



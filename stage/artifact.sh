#!/bin/bash

cd #path
branch=#branch
project=#project
repo=#repo
fileB=backup.sh
file2=download.sh
livepath=#prod
gitClone=#git_url
prodServerUser=`jq ".deployments.${branch}.codeRunner.serverUser" #path/#project/#branch/#repo/devops.json` 
gitNumber=`jq ".deployments.${branch}.build.includeArtifact | length" #path/#project/#branch/#repo/devops.json`
isBackup=`jq ".deployments.${branch}.codeRunner.isBackup" #path/#project/#branch/#repo/devops.json`
isBackup=`echo "$isBackup" | tr -d '"'`

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
                cp -r #project/#branch/artifact/$assetsSource #project/#branch/artifact/$assetsDestination
                if [ "$assetsSource" != "*" ]; then
                    rm -rf #project/#branch/artifact/$assetsSource
                fi
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
        file=$(jq ".deployments.${branch}.build.excludeArtifact[$i].file[$j]" #path/#project/#branch/#repo/devops.json)
        file=`echo "$file" | tr -d '"'`
        if [ -z "$source" ] && [ -z "$file" ]
        then
            echo "hello its empty"
        else
            rm -rf #project/#branch/artifact$source/$file
        fi
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
rm -rf changedfiles2.txt
rm -rf setupDeployment.sh
rm -rf images
rm composer.lock
# rm -rf "thirdparty/bootstrap/css" "thirdparty/css" "thirdparty/fancybox/css" "thirdparty/flipbook/css" "thirdparty/ace-admin/css" "thirdparty/dataTables" "templates/css" "admin/includes/css"
# rm -rf "thirdparty/js" "thirdparty/ace-admin/js" "thirdparty/bootstrap/js" "thirdparty/dataTables" "thirdparty/dataTables/extensions/TableTools/js" "thirdparty/fancybox/js" "thirdparty/ckeditor" "admin/includes/js" "\thirdparty/flipbook/js"
# rm -rf "thirdparty/bootstrap/css" "thirdparty/css" "thirdparty/fancybox/css" "templates/css" "thirdparty/slick/css" "thirdparty/flipbook/css" "thirdparty/calendarPreview/css"
# rm -rf "templates/js" "thirdparty/js" "studio/Scripts/realpreview" "thirdparty/intel-tel-input/js" "thirdparty/jsSocials/js" "studio/Scripts/photoprint" "thirdparty/bootstrap/js" "thirdparty/fancybox/js" "thirdparty/slick/js" "thirdparty/flipbook/js" "thirdparty/calendarPreview/js"
# rm -rf "studio/Scripts/lib/bootstrap/css" "studio/Scripts/lib/font-awesome/css" "studio/Scripts/lib/angular-ui-select" "studio/Scripts/lib/fine-uploader" "studio/Scripts/lib/jQuery" "studio/Scripts/lib/colorpicker" "studio/Scripts/lib/angular-hotkeys-master" "studio/Scripts/lib/fancybox" "studio/Scripts/lib/angular-ui-notification" "studio/Scripts/lib/intro" "studio/Scripts/lib/flipbook/css" "studio/Scripts/lib/calendarPreview/css" "studio/Content/css"

jq ".deployments.development" #path/#project/#branch/#repo/devops.json > upload.json

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
sed -i "s|#backup|$isBackup|g" $fileB

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



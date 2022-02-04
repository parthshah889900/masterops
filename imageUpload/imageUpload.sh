#!/bin/bash
cd #path
branch=#branch
git_url=#git_url
project=#project
flag=false
clone(){
        git clone $git_url public_html
        flag=true
        cd public_html
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
        if [ ! -d vendor ]; then
            cd ..
            composer install -d public_html
        fi
}

if [ ! -d "public_html" ]; then
    mkdir public_html
    clone
else
    cd public_html
    if [ ! -f devops.json ]; then
        cd ..       
        clone
    fi
fi

if [ $flag != true ]; then
    cd #path/public_html
    git stash
    git pull
    actionUploadNumber=`jq ".deployments.${branch}.build.action.upload | length" devops.json`

    cd ..
    if [ ! -d "temp" ]; then
        mkdir temp
    fi
    for (( i=0; i<actionUploadNumber; i++ ))
    do  
        source=$(jq ".deployments.${branch}.build.action.upload[$i].source" public_html/devops.json)
        source=`echo "$source" | tr -d '"'`
        if [ -z "$source" ]
            then
                echo "hello its empty"
            else
             if [ -d "$source" ] || [ -f "$source" ]; then
                folder=`echo ${source##*/}`
                cp -r #path/$source temp 
            else
                 echo "file or folder not found"                
            fi   
        fi    
    done
    cd temp
    zip -r additionalArtifact.zip .
    aws s3 cp additionalArtifact.zip "s3://$project-onprintshop/additionalArtifact/"
    cd ..
    if [ -d "temp" ]; then
        rm -rf temp/
    fi
fi
#!/bin/bash

Reply=$1
if [ $Reply = "--init" ]; then
    if aws iam get-role --role-name codeDeployRole-onprintshop --query 'Role.[Arn]' --output text 2>&1 | grep -q 'NoSuchEntity'
    then
        aws s3 cp s3://masterops/stage/tempJson/deployRole.json .
        aws s3 cp s3://masterops/stage/tempJson/pipelineRole.json .
        aws cloudformation create-stack --stack-name "Code-Deploy-role" --template-body file://deployRole.json --parameters ParameterKey=RoleArnName,ParameterValue=codeDeployRole-onprintshop --capabilities CAPABILITY_NAMED_IAM
        aws cloudformation create-stack --stack-name "Code-Pipeline-role" --template-body file://pipelineRole.json --parameters ParameterKey=RoleArnName,ParameterValue=codePipelineRole-onprintshop --capabilities CAPABILITY_NAMED_IAM
        sleep 2m
        rm deployRole.json
        rm pipelineRole.json
        echo "Code deploy role and code pipeline role has been created, So please use this same role for every project."
        codePipeArn=`aws iam get-role --role-name codePipelineRole-onprintshop --query 'Role.[Arn]' --output text`
        codeDeployArn=`aws iam get-role --role-name codeDeployRole-onprintshop --query 'Role.[Arn]' --output text`
        echo "Your code pipeline Arn is:" $codePipeArn
        echo "Your code deploy Arn is :" $codeDeployArn
    fi
    codePipeArn=`aws iam get-role --role-name codePipelineRole-onprintshop --query 'Role.[Arn]' --output text`
    codeDeployArn=`aws iam get-role --role-name codeDeployRole-onprintshop --query 'Role.[Arn]' --output text`
    templates='{"sourceControl":"","deployments":{"master":{"build":{"server":"","path":"","serverUser":"","includeArtifact":[{"sourceControl":{"url":"","branch":""},"assets":[{"source":"","destination":""}]},{"sourceControl":{"url":"","branch":""},"assets":[{"source":"","destination":""}]}],"encryption":{"wantToEncrypt":"","confirmEncryptType":"","expireOn":""}},"codeRunner":{"server":"","path":"","serverUser":""}}},"aws":{"arn":{"codepipeline":"%s","codedeploy":"%s"}}}'
    json_string=$(printf "$templates" $codePipeArn $codeDeployArn )
    jq -n $json_string > devops.json
fi

setUp(){
    echo "You are on a $Reply branch"
    aws s3 cp s3://masterops/target/ . --recursive
    chmod +x target.sh
    echo "Process started"
    ./target.sh $Reply
    Url=$(jq '.sourceControl' devops.json)
    Url=`echo "$Url" | tr -d '"'`
    readarray -d / -t variable<<< $Url
    variable=`echo ${variable[-1]}`
    repoFolder=`echo "${variable::-4}"`


    echo "$(tput setaf 1)##################################################################################"

    if [ -f ".gitlab-ci.yml" ]; then
        master="${repoFolder}-master-stage"
        development="${repoFolder}-development-stage"
        
        template='{"build-job":{"stage":"build","script":["aws codepipeline start-pipeline-execution --name %s --region ap-south-1"]},"uploadImage-job":{"stage":"build","script":["aws codepipeline start-pipeline-execution --name %s --region ap-south-1"]}}'
        json_string=$(printf "$template" $master $development )
        echo $json_string > gitlab.json
        yq eval -P gitlab.json > abc.yml
        echo "$(tput sgr0)"
        cat abc.yml

        echo "$(tput setaf 1) Please add above line in your .gitlab-ci.yml file"
        rm -rf abc.yml
        rm gitlab.json

    else
        name="${repoFolder}-${Reply}-stage"
        template='{"build-job":{"when":"manual","variables":{"GIT_STRATEGY":"none"},"stage":"build","script":["aws codepipeline start-pipeline-execution --name rxarchitecture-master-stage --region ap-south-1"]},"uploadImage-job":{"when":"manual","variables":{"GIT_STRATEGY":"none"},"stage":"build","script":["aws codepipeline start-pipeline-execution --name rxarchitecture-development-stage --region ap-south-1"]}}'
        json_string=$(printf "$template" $name )
        echo $json_string > gitlab.json
        yq eval -P gitlab.json > .gitlab-ci.yml

        echo ".gitlab-ci.yml has been created. Please push into repo to use GitLab CI"
        rm gitlab.json
    fi

    echo "################################################################################## $(tput sgr0)"
    rm target.sh
}

if [ $Reply = "development" ] || [ $Reply = "master" ]; then
    if [ -f "devops.json" ]; then
        setUp
    else 
        echo "devops.json not found.Please run command ./setupDeployment.sh --init to get devops.json"
    fi
else 
    echo "You have entered the wrong branch. Please enter the proper branch again."
fi
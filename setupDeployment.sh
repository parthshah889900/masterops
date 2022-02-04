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
    templates='{"sourceControl":"","deployments":{"development":{"build":{"server":"","path":"","serverUser":"","action":{"upload":[{"source":"","destination":"","permission":""},{"source":"","destination":"","permission":""}]}}},"master":{"build":{"server":"","path":"","serverUser":"","cacheVersion":[{"from":"","to":""},{"from":"","to":""}],"includeArtifact":[{"sourceControl":{"url":"","branch":"","tag":"","disabled":""},"assets":[{"source":"","destination":""}]},{"sourceControl":{"url":"","branch":"","tag":"","disabled":""},"assets":[{"source":"","destination":""}]}],"excludeArtifact":[{"source":"","file":[""]},{"source":"","file":[""]}],"encryption":{"wantToEncrypt":"","confirmEncryptType":"","expireOn":""}},"codeRunner":{"server":"","path":"","serverUser":"","isBackup":""}}},"aws":{"arn":{"codepipeline":"%s","codedeploy":"%s"}}}'
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
    if [ $Reply = "development" ]; then

        echo "$(tput setaf 1)##################################################################################"

        if [ -f ".gitlab-ci.yml" ]; then
            masterStage="${repoFolder}-master-stage"
            masterProd="${repoFolder}-master-prod"
            developmentStage="${repoFolder}-development-stage"
                    
            echo 'build-job:
  when: manual
  variables:
    GIT_STRATEGY: none
  stage: build
  script: |
    aws codepipeline start-pipeline-execution --name rxarchitecture-master-stage --region ap-south-1
    sleep 10s
    status=`aws codepipeline get-pipeline-state --name rxarchitecture-master-stage --query stageStates[-1].latestExecution.status --region ap-south-1`
    status=${status:1}
    status=${status::-1}
    if [ "$status" != "Succeeded" ]; then
        echo "Build Pipeline is started"
        while [ "$status" != "Succeeded" ] 
        do
            sleep 15s
            status=`aws codepipeline get-pipeline-state --name rxarchitecture-master-stage --query stageStates[-1].latestExecution.status --region ap-south-1`
            status=${status:1}
            status=${status::-1}
            echo "Please wait build pipeline is in process.It will take time."
            if [ "$status" = "Failed" ]; then
            echo "$(tput setaf 1)"
            echo "Your build pipeline is failed. Please contact administrator."
            echo "$(tput sgr0)"
            exit
            fi
        done
        echo "Build Pipeline Finished"
    fi

    func(){
        sleep 5s
        status=`aws codepipeline get-pipeline-state --name rxarchitecture-master-prod --query stageStates[-1].latestExecution.status --region ap-south-1`
        status=${status:1}
        status=${status::-1}
        if [ "$status" != "Succeeded" ]; then
            echo "Prod Pipeline is started"
            while [ "$status" != "Succeeded" ] 
            do
                sleep 15s
                status=`aws codepipeline get-pipeline-state --name rxarchitecture-master-prod --query stageStates[-1].latestExecution.status --region ap-south-1`
                status=${status:1}
                status=${status::-1}
                echo "Please wait prod pipeline is in process.It will take time."
                if [ "$status" = "Failed" ]; then
                echo "$(tput setaf 1)"
                echo "Your prod pipeline is failed. Please contact administrator."
                echo "$(tput sgr0)"
                exit
                fi
            done
        echo "Prod Pipeline Finished"
    fi
    }

    func
    func

uploadImage-job:
  when: manual
  variables:
    GIT_STRATEGY: none
  stage: build
  script: |
    aws codepipeline start-pipeline-execution --name rxarchitecture-development-stage --region ap-south-1
    sleep 10s
    status=`aws codepipeline get-pipeline-state --name rxarchitecture-development-stage --query stageStates[-1].latestExecution.status --region ap-south-1`
    status=${status:1}
    status=${status::-1}
    if [ "$status" != "Succeeded" ]; then
        echo "Upload image Pipeline is started"
        while [ "$status" != "Succeeded" ] 
        do
            sleep 15s
            status=`aws codepipeline get-pipeline-state --name rxarchitecture-development-stage --query stageStates[-1].latestExecution.status --region ap-south-1`
            status=${status:1}
            status=${status::-1}
            echo "Please wait upload image pipeline is in process.It will take time."
            if [ "$status" = "Failed" ]; then
            echo "$(tput setaf 1)"
            echo "Your upload image pipeline is failed. Please contact administrator."
            echo "$(tput sgr0)"
            exit
            fi
        done
        echo "Upload image Pipeline Finished"
    fi
    '>temp.txt

            sed -i "s/\bmasterStage\b/$masterStage/g" temp.txt
            sed -i "s/\bmasterProd\b/$masterProd/g" temp.txt
            sed -i "s/\bdevelopmentStage\b/$developmentStage/g" temp.txt

            cat temp.txt
            rm temp.txt

            echo "$(tput setaf 1) Please add above line in your .gitlab-ci.yml file"
        else
            masterStage="${repoFolder}-master-stage"
            masterProd="${repoFolder}-master-prod"
            developmentStage="${repoFolder}-development-stage"
            echo 'build-job:
  when: manual
  variables:
    GIT_STRATEGY: none
  stage: build
  script: |
    aws codepipeline start-pipeline-execution --name rxarchitecture-master-stage --region ap-south-1
    sleep 10s
    status=`aws codepipeline get-pipeline-state --name rxarchitecture-master-stage --query stageStates[-1].latestExecution.status --region ap-south-1`
    status=${status:1}
    status=${status::-1}
    if [ "$status" != "Succeeded" ]; then
        echo "Build Pipeline is started"
        while [ "$status" != "Succeeded" ] 
        do
            sleep 15s
            status=`aws codepipeline get-pipeline-state --name rxarchitecture-master-stage --query stageStates[-1].latestExecution.status --region ap-south-1`
            status=${status:1}
            status=${status::-1}
            echo "Please wait build pipeline is in process.It will take time."
            if [ "$status" = "Failed" ]; then
            echo "$(tput setaf 1)"
            echo "Your build pipeline is failed. Please contact administrator."
            echo "$(tput sgr0)"
            exit
            fi
        done
        echo "Build Pipeline Finished"
    fi

    func(){
        sleep 5s
        status=`aws codepipeline get-pipeline-state --name rxarchitecture-master-prod --query stageStates[-1].latestExecution.status --region ap-south-1`
        status=${status:1}
        status=${status::-1}
        if [ "$status" != "Succeeded" ]; then
            echo "Prod Pipeline is started"
            while [ "$status" != "Succeeded" ] 
            do
                sleep 15s
                status=`aws codepipeline get-pipeline-state --name rxarchitecture-master-prod --query stageStates[-1].latestExecution.status --region ap-south-1`
                status=${status:1}
                status=${status::-1}
                echo "Please wait prod pipeline is in process.It will take time."
                if [ "$status" = "Failed" ]; then
                echo "$(tput setaf 1)"
                echo "Your prod pipeline is failed. Please contact administrator."
                echo "$(tput sgr0)"
                exit
                fi
            done
        echo "Prod Pipeline Finished"
    fi
    }

    func
    func

uploadImage-job:
  when: manual
  variables:
    GIT_STRATEGY: none
  stage: build
  script: |
    aws codepipeline start-pipeline-execution --name rxarchitecture-development-stage --region ap-south-1
    sleep 10s
    status=`aws codepipeline get-pipeline-state --name rxarchitecture-development-stage --query stageStates[-1].latestExecution.status --region ap-south-1`
    status=${status:1}
    status=${status::-1}
    if [ "$status" != "Succeeded" ]; then
        echo "Upload image Pipeline is started"
        while [ "$status" != "Succeeded" ] 
        do
            sleep 15s
            status=`aws codepipeline get-pipeline-state --name rxarchitecture-development-stage --query stageStates[-1].latestExecution.status --region ap-south-1`
            status=${status:1}
            status=${status::-1}
            echo "Please wait upload image pipeline is in process.It will take time."
            if [ "$status" = "Failed" ]; then
            echo "$(tput setaf 1)"
            echo "Your upload image pipeline is failed. Please contact administrator."
            echo "$(tput sgr0)"
            exit
            fi
        done
        echo "Upload image Pipeline Finished"
    fi
    ' >.gitlab-ci.yml
            sed -i "s/\bmasterStage\b/$masterStage/g" .gitlab-ci.yml
            sed -i "s/\bmasterProd\b/$masterProd/g" .gitlab-ci.yml
            sed -i "s/\bdevelopmentStage\b/$developmentStage/g" .gitlab-ci.yml
            echo ".gitlab-ci.yml has been created. Please push into repo to use GitLab CI"
        fi

        echo "################################################################################## $(tput sgr0)"
    fi
    rm target.sh
}

if [ $Reply != "--init" ]; then
    if [ $Reply = "development" ] || [ $Reply = "master" ]; then
        if [ -f "devops.json" ]; then
            setUp
        else 
            echo "devops.json not found.Please run command ./setupDeployment.sh --init to get devops.json"
        fi
    else 
        echo "You have entered the wrong branch. Please enter the proper branch again."
    fi
fi
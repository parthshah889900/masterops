#!/bin/bash
branch=$1
# Assigning the variable to other parameters
arnDeployGroup=`jq -r '.aws.arn.codedeploy' devops.json`
arnCodePipeline=`jq -r '.aws.arn.codepipeline' devops.json`
valueBuildServer=`jq -r ".deployments.${branch}.build.server" devops.json`
valueLiveServer=`jq -r ".deployments.${branch}.codeRunner.server" devops.json`
buildServerPath=`jq -r ".deployments.${branch}.build.path" devops.json`
livesServerPath=`jq -r ".deployments.${branch}.codeRunner.path" devops.json`
buildUser=`jq -r ".deployments.${branch}.build.serverUser" devops.json`
produser=`jq -r ".deployments.${branch}.codeRunner.serverUser" devops.json`
git_url=`jq -r '.sourceControl' devops.json`



variable=`echo ${git_url##*/}`
project=`echo "${variable::-4}"`
echo "Your project name is" $project

# Assigning the variable to repository name
repo=$project
echo $project
echo $repo

#it will  create a bucket if its's does not exist
if aws s3 ls "s3://$project-onprintshop" 2>&1 | grep -q 'NoSuchBucket'
then
  echo "Bucket is creating please wait"
  aws cloudformation create-stack --stack-name "$project-bucket" --template-body file://tempJson/bucket.json --parameters ParameterKey=S3BucketName,ParameterValue="$project-onprintshop" --capabilities CAPABILITY_NAMED_IAM
  echo "Process wait for 30 second.It will resume after completing the s3 bucket creation process"
  sleep 50s
fi


############################ new -pipeline side code ########################################
if aws codepipeline get-pipeline-state --name $project-$branch-new 2>&1 | grep -q 'PipelineNotFoundException'
then 
  aws s3 cp s3://masterops/new/ . --recursive
  file5=newProject.sh
  sed -i "s|#project|$project|g" $file5
  sed -i "s|#repo|$repo|g" $file5
  sed -i "s|#git_url|$git_url|g" $file5
  sed -i "s|#branch|$branch|g" $file5
  sed -i "s|#path|$buildServerPath|g" $file5
  buildServerUser=`jq ".deployments.${branch}.build.serverUser" devops.json`
  template='{"version":0.0,"os":"linux","hooks":{"ApplicationStart":[{"location":"newProject.sh","timeout":300,"runas":%s}]}}'
  json_string=$(printf "$template" $buildServerUser)
  echo $json_string > fileName.json
  yq eval -P fileName.json > appspec.yml
  rm fileName.json

  #it will create the zip and send to the bucket
  zip new.zip appspec.yml newProject.sh
  aws s3 cp new.zip "s3://$project-onprintshop/$branch/New/"
  sleep 1s

  rm appspec.yml
  rm newProject.sh 
  rm -rf new.zip
fi 

newPipeline(){
  aws s3 cp s3://masterops/stage/tempJson/ tempJson --recursive
  sleep 1s
  aws cloudformation create-stack --stack-name "$project-$branch-new" --template-body file://tempJson/newproject.json --parameters ParameterKey=CodeDeployApplication,ParameterValue="$project-$branch-new"  ParameterKey=DeploymentGroupName,ParameterValue="$project-$branch-new" ParameterKey=ArnforDeploymentGroup,ParameterValue=$arnDeployGroup ParameterKey=KeyForDEploymentGroup,ParameterValue=Name ParameterKey=ValueForDeploymentGroup,ParameterValue=$valueBuildServer ParameterKey=CodePipelineName,ParameterValue="$project-$branch-new" ParameterKey=S3BucketName,ParameterValue="$project-onprintshop" ParameterKey=S3ObjectKeys,ParameterValue="$branch/New/new.zip" ParameterKey=ArnforCodePipeline,ParameterValue=$arnCodePipeline --capabilities CAPABILITY_NAMED_IAM
  echo "Please wait your project is creating"
  sleep 20s
  pipelineStatus=`aws codepipeline get-pipeline-state --name $project-$branch-new --query 'stageStates[-1].latestExecution.[status]' --output text`

  if [ "$pipelineStatus" != "Succeeded" ]; then
      while [ "$pipelineStatus" != "Succeeded" ] 
      do
          sleep 60s
          pipelineStatus=`aws codepipeline get-pipeline-state --name $project-$branch-new --query 'stageStates[-1].latestExecution.[status]' --output text`
          echo "Please wait new project pipeline is in process.It will take time."
          if [ "$pipelineStatus" = "Failed" ]; then
            echo "$(tput setaf 1)"
            echo "Your new project pipeline is failed. Please contact administrator."
            echo "$(tput sgr0)"
            exit
          fi
      done
  fi
  rm -rf tempJson
}

if aws cloudformation describe-stacks --stack-name "$project-$branch-new" --query 'Stacks[*].[StackStatus]' --output text 2>&1 | grep -q 'ValidationError'
then 
  newPipeline
else
  newPipeState=`aws codepipeline get-pipeline-state --name $project-$branch-new --query [stageStates[-1].latestExecution.status] --output text`
  if [ $newPipeState != "Succeeded" ]; then
    aws cloudformation delete-stack --stack-name "$project-$branch-new"
    echo "Your project stack is deleting please wait"
    sleep 15s
    newPipeline
  fi
fi


######################################## staging side #######################
if aws codepipeline get-pipeline-state --name $project-$branch-stage 2>&1 | grep -q 'PipelineNotFoundException'
then 
  aws s3 cp s3://masterops/stage/ . --recursive
  file=encrypt.sh
  file2=gitStatus.sh

  file4=artifact.sh

  sed -i "s|#project|$project|g" $file
  sed -i "s|#repo|$repo|g" $file
  sed -i "s|#path|$buildServerPath|g" $file
  sed -i "s|#branch|$branch|g" $file
  sed -i "s|#project|$project|g" $file2
  sed -i "s|#repo|$repo|g" $file2
  sed -i "s|#path|$buildServerPath|g" $file2
  sed -i "s|#branch|$branch|g" $file2
  sed -i "s|#project|$project|g" $file4
  sed -i "s|#branch|$branch|g" $file4
  sed -i "s|#path|$buildServerPath|g" $file4
  sed -i "s|#prod|$livesServerPath|g" $file4
  sed -i "s|#repo|$repo|g" $file4
  sed -i "s|#git_url|$git_url|g" $file4

  buildServerUser=`jq ".deployments.${branch}.build.serverUser" devops.json`
  template='{"version":0.0,"os":"linux","hooks":{"AfterInstall":[{"location":"gitStatus.sh","timeout":300,"runas":%s}],"ApplicationStart":[{"location":"encrypt.sh","timeout":300,"runas":%s}],"ValidateService":[{"location":"artifact.sh","timeout":300,"runas":%s}]}}'
  json_string=$(printf "$template" $buildServerUser $buildServerUser $buildServerUser)
  echo $json_string > fileName.json
  yq eval -P fileName.json > appspec.yml
  rm fileName.json
  # source.zip is created here
  zip source.zip appspec.yml encrypt.sh gitStatus.sh artifact.sh 

  # it will move source.zip to bucket

  aws s3 cp source.zip "s3://$project-onprintshop/$branch/Source/"

  rm appspec.yml
  rm $file
  rm $file2
  rm $file4
  rm source.zip
fi

stageDeploy(){
  echo "Build pipeline is running please wait"
  aws cloudformation create-stack --stack-name "$project-$branch-stagedeploy" --template-body file://tempJson/stagedeploy.json --parameters ParameterKey=CodeDeployApplication,ParameterValue="$project-$branch-stage"  ParameterKey=DeploymentGroupName,ParameterValue="$project-$branch-stage" ParameterKey=ArnforDeploymentGroup,ParameterValue=$arnDeployGroup ParameterKey=KeyForDEploymentGroup,ParameterValue=Name ParameterKey=ValueForDeploymentGroup,ParameterValue=$valueBuildServer ParameterKey=CodePipelineName,ParameterValue="$project-$branch-stage" ParameterKey=S3BucketName,ParameterValue="$project-onprintshop" ParameterKey=S3ObjectKeys,ParameterValue="$branch/Source/source.zip" ParameterKey=ArnforCodePipeline,ParameterValue=$arnCodePipeline --capabilities CAPABILITY_NAMED_IAM
  sleep 15s
  aws codepipeline get-pipeline-state --name $project-$branch-stage >temp.json
  status=$(jq ".stageStates[-1].latestExecution.status" temp.json)
  status=`echo "$status" | tr -d '"'`

  if [ "$status" != "Succeeded" ]; then
      while [ "$status" != "Succeeded" ] 
      do
          sleep 60s
          aws codepipeline get-pipeline-state --name $project-$branch-stage >temp.json
          status=$(jq ".stageStates[-1].latestExecution.status" temp.json)
          status=`echo "$status" | tr -d '"'`
          echo "Please wait build pipeline is in process.It will take time."
          if [ "$status" = "Failed" ]; then
            echo "$(tput setaf 1)"
            echo "Your build pipeline is failed. Please contact administrator."
            echo "$(tput sgr0)"
            exit
          fi
      done
      rm temp.json
  fi
}

if aws cloudformation describe-stacks --stack-name "$project-$branch-stagedeploy" --query 'Stacks[*].[StackStatus]' --output text 2>&1 | grep -q 'ValidationError'
then 
  stageDeploy
else
  stagePipeState=`aws codepipeline get-pipeline-state --name $project-$branch-stage --query [stageStates[-1].latestExecution.status] --output text`
  if [ $stagePipeState != "Succeeded" ]; then 
    aws cloudformation delete-stack --stack-name "$project-$branch-stagedeploy"
    sleep 30s
    stageDeploy
  fi
fi

############################################### live side deploy #################################
prodDeploy(){
  echo "Process is started for productions server"
  aws cloudformation create-stack --stack-name "$project-$branch-proddeploy" --template-body file://tempJson/proddeploy.json --parameters ParameterKey=CodeDeployApplication,ParameterValue="$project-$branch-prod"  ParameterKey=DeploymentGroupName,ParameterValue="$project-$branch-prod" ParameterKey=ArnforDeploymentGroup,ParameterValue=$arnDeployGroup ParameterKey=KeyForDEploymentGroup,ParameterValue=Name ParameterKey=ValueForDeploymentGroup,ParameterValue=$valueLiveServer ParameterKey=CodePipelineName,ParameterValue="$project-$branch-prod" ParameterKey=S3BucketName,ParameterValue="$project-onprintshop" ParameterKey=S3ObjectKeys,ParameterValue="$branch/Prod/prod.zip" ParameterKey=ArnforCodePipeline,ParameterValue=$arnCodePipeline --capabilities CAPABILITY_NAMED_IAM
  sleep 15s
  aws codepipeline get-pipeline-state --name $project-$branch-prod >temp.json
  status=$(jq ".stageStates[-1].latestExecution.status" temp.json)
  status=`echo "$status" | tr -d '"'`

  if [ "$status" != "Succeeded" ]; then
      while [ "$status" != "Succeeded" ] 
      do
          sleep 60s
          aws codepipeline get-pipeline-state --name $project-$branch-prod >temp.json
          status=$(jq ".stageStates[-1].latestExecution.status" temp.json)
          status=`echo "$status" | tr -d '"'`
          echo "Please wait prod pipeline is in process.It will take time."
          if [ "$status" = "Failed" ]; then
            echo "$(tput setaf 1)"
            echo "Your prod pipeline is failed. Please contact administrator."
            echo "$(tput sgr0)"
            exit
          fi
      done
      rm temp.json
  fi
  }
if aws cloudformation describe-stacks --stack-name "$project-$branch-proddeploy" --query 'Stacks[*].[StackStatus]' --output text 2>&1 | grep -q 'ValidationError'
then
  prodDeploy  
else
  prodPipeState=`aws codepipeline get-pipeline-state --name $project-$branch-prod --query [stageStates[-1].latestExecution.status] --output text`
  if [ $prodPipeState != "Succeeded" ]; then 
    aws cloudformation delete-stack --stack-name "$project-$branch-proddeploy"
    sleep 30s
    prodDeploy
  fi
fi


####################################################### git push pipeline created: ############################
if aws codepipeline get-pipeline-state --name $project-$branch-gitPush 2>&1 | grep -q 'PipelineNotFoundException'
then 
  aws s3 cp s3://masterops/gitPush/ . --recursive
  filePush=commit.sh
  sed -i "s|#project|$project|g" $filePush
  sed -i "s|#repo|$repo|g" $filePush
  sed -i "s|#branch|$branch|g" $filePush
  sed -i "s|#livepath|$livesServerPath|g" $filePush

  template='{"version":0.0,"os":"linux","hooks":{"ApplicationStart":[{"location":"commit.sh","timeout":300,"runas":%s}]}}'
  json_string=$(printf "$template" $produser)
  echo $json_string > fileName.json
  yq eval -P fileName.json > appspec.yml
  rm fileName.json

  # it will create the zip and send to the bucket
  zip gitPush.zip appspec.yml commit.sh
  aws s3 cp gitPush.zip "s3://$project-onprintshop/$branch/GitPush/"
  sleep 1s

  rm appspec.yml
  rm commit.sh 
  rm -rf gitPush.zip
fi

gitPush(){
  echo "gitPush pipeline is running please wait"
  aws cloudformation create-stack --stack-name "$project-$branch-gitPush" --template-body file://tempJson/gitPush.json --parameters ParameterKey=CodeDeployApplication,ParameterValue="$project-$branch-gitPush"  ParameterKey=DeploymentGroupName,ParameterValue="$project-$branch-gitPush" ParameterKey=ArnforDeploymentGroup,ParameterValue=$arnDeployGroup ParameterKey=KeyForDEploymentGroup,ParameterValue=Name ParameterKey=ValueForDeploymentGroup,ParameterValue=$valueLiveServer ParameterKey=CodePipelineName,ParameterValue="$project-$branch-gitPush" ParameterKey=S3BucketName,ParameterValue="$project-onprintshop" ParameterKey=S3ObjectKeys,ParameterValue="$branch/GitPush/gitPush.zip" ParameterKey=ArnforCodePipeline,ParameterValue=$arnCodePipeline --capabilities CAPABILITY_NAMED_IAM
  sleep 13s
  deployId=`aws deploy list-deployments --application-name $project-$branch-gitPush --deployment-group-name $project-$branch-gitPush --query 'deployments[0]' --output text`
  echo $deployId
  aws deploy stop-deployment --deployment-id $deployId
}
if aws cloudformation describe-stacks --stack-name "$project-$branch-gitPush" --query 'Stacks[*].[StackStatus]' --output text 2>&1 | grep -q 'ValidationError'
then 
  gitPush
else
  gitPushPipeState=`aws codepipeline get-pipeline-state --name $project-$branch-gitPush --query [stageStates[-1].latestExecution.status] --output text`
  if [ $gitPushPipeState != "Failed" ]; then
    aws cloudformation delete-stack --stack-name "$project-$branch-gitPush"
    sleep 30s
    gitPush
  fi
fi

############################################################### rollback stack create from here #########
if aws cloudformation describe-stacks --stack-name "$project-$branch-rollback" --query 'Stacks[*].[StackStatus]' --output text 2>&1 | grep -q 'ValidationError'
then 
  echo "Rollback is creating:"
  aws cloudformation create-stack --stack-name "$project-$branch-rollback" --template-body file://tempJson/rollback.json --parameters ParameterKey=CodeDeployApplication,ParameterValue="$project-$branch-rollback"  ParameterKey=DeploymentGroupName,ParameterValue="$project-$branch-rollback" ParameterKey=ArnforDeploymentGroup,ParameterValue=$arnDeployGroup ParameterKey=KeyForDEploymentGroup,ParameterValue=Name ParameterKey=ValueForDeploymentGroup,ParameterValue=$valueLiveServer --capabilities CAPABILITY_NAMED_IAM
  
fi
rm -rf tempJson
#################### stack of new project deleted through here ########################################
aws cloudformation delete-stack --stack-name "$project-$branch-new"
echo "Your project stack is deleting please wait"


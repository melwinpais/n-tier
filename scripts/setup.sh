#!/bin/bash
set +o xtrace

function deploy {
    echo "Deploying $1"
    aws cloudformation deploy --stack-name $1 --template-file $2 --capabilities CAPABILITY_IAM
    echo "Deployed $1"
} 
function delete {
    echo "Deleting $1"
    aws cloudformation delete-stack --stack-name $1
    aws cloudformation wait stack-delete-complete --stack-name $1
    echo "Deleted $1"
} 


echo "Setting up the VPC"

cd ../cloudformation
# deploy dod-cnc-base cluster-fargate-private-vpc.yml
## deploy dod-cnc-alb alb-external.yml



# delete web-tier web-tier.yml
deploy web-tier web-tier.yml


# delete app-tier app-tier.yml
deploy app-tier app-tier.yml



# delete db-tier db-tier.yml
# deploy db-tier db-tier.yml



# delete bastion bastion.yml
# deploy bastion bastion.yml
# aws cloudformation deploy --stack-name bastion --template-file bastion.yml --parameters ParameterKey=RemoteAccessCIDR,ParameterValue=54.240.193.129/0

echo "Set up Completed"


#!/bin/bash
set -o xtrace

cd ../cnc-web-tier
ecs-cli compose --project-name cnc-webapp service down

export AWS_ACCOUNT=$(aws sts get-caller-identity --query 'Account' --output text)
export AWS_REGION='ap-southeast-2'
export clustername=$(aws cloudformation describe-stacks --stack-name dod-cnc-base --query 'Stacks[0].Outputs[?OutputKey==`ClusterName`].OutputValue' --output text)
export target_group_arn=$(aws cloudformation describe-stack-resources --stack-name dod-cnc-alb | jq -r '.[][] | select(.ResourceType=="AWS::ElasticLoadBalancingV2::TargetGroup").PhysicalResourceId')
export vpc=$(aws cloudformation describe-stacks --stack-name dod-cnc-base --query 'Stacks[0].Outputs[?OutputKey==`VpcId`].OutputValue' --output text)
export ecsTaskExecutionRole=$(aws cloudformation describe-stacks --stack-name dod-cnc-base --query 'Stacks[0].Outputs[?OutputKey==`ECSTaskExecutionRole`].OutputValue' --output text)
export subnet_1=$(aws cloudformation describe-stacks --stack-name dod-cnc-base --query 'Stacks[0].Outputs[?OutputKey==`WebSubnetOne`].OutputValue' --output text)
export subnet_2=$(aws cloudformation describe-stacks --stack-name dod-cnc-base --query 'Stacks[0].Outputs[?OutputKey==`WebSubnetTwo`].OutputValue' --output text)
export subnet_3=$(aws cloudformation describe-stacks --stack-name dod-cnc-base --query 'Stacks[0].Outputs[?OutputKey==`WebSubnetThree`].OutputValue' --output text)
export security_group=$(aws cloudformation describe-stacks --stack-name dod-cnc-base --query 'Stacks[0].Outputs[?OutputKey==`ContainerSecurityGroup`].OutputValue' --output text)

# Configure ecs-cli to talk to the cluster
ecs-cli configure --region $AWS_REGION --cluster $clustername --default-launch-type FARGATE --config-name dod-cnc

# Our containers talk on port 3000, so authorize that traffic on our security group
aws ec2 authorize-security-group-ingress --group-id "$security_group" --protocol tcp --port 3000 --source-group "$security_group"

envsubst < ecs-params.yml.template >ecs-params.yml

docker build -t dod-cnc/cnc-webapp .
ecs-cli push dod-cnc/cnc-webapp:latest

ecs-cli compose --project-name cnc-webapp service up \
    --create-log-groups \
    --target-group-arn $target_group_arn \
    --private-dns-namespace service \
    --enable-service-discovery \
    --container-name cnc-webapp \
    --container-port 3000 \
    --cluster-config dod-cnc \
    --vpc $vpc &
    
ecs-cli compose --project-name cnc-webapp service ps \
    --cluster-config dod-cnc

task_id=$(ecs-cli compose --project-name cnc-webapp service ps --cluster-config dod-cnc | awk -F \/ 'FNR == 2 {print $1}')

# Referencing task id from above ps command
ecs-cli logs --task-id $task_id \
    --follow --cluster-config dod-cnc


alb_url=$(aws cloudformation describe-stacks --stack-name dod-cnc-alb --query 'Stacks[0].Outputs[?OutputKey==`ExternalUrl`].OutputValue' --output text)
curl -v http://$alb_url
echo "Open $alb_url in your browser"



docker build . -t 362430232425.dkr.ecr.ap-southeast-2.amazonaws.com/dod-cnc/cnc-webapp:latest

aws ecr create-repository --repository-name dod-cnc/cnc-webapp
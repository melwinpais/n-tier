#!/bin/bash
set -o xtrace

cd ../cnc-app-tier
ecs-cli compose --project-name cnc-geoserver service down

#!/usr/bin/env bash

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

docker build -t dod-cnc/cnc-geoserver .
ecs-cli push dod-cnc/cnc-geoserver:latest

ecs-cli compose --project-name cnc-geoserver service up \
    --create-log-groups \
    --private-dns-namespace service \
    --enable-service-discovery \
    --container-name cnc-geoserver \
    --cluster-config dod-cnc \
    --vpc $vpc 
    # --target-group-arn $target_group_arn \
    

ecs-cli compose --project-name cnc-geoserver service ps \
    --cluster-config dod-cnc

task_id=$(ecs-cli compose --project-name cnc-geoserver service ps --cluster-config dod-cnc | awk -F \/ 'FNR == 2 {print $1}')

# Referencing task id from above ps command
ecs-cli logs --task-id $task_id \
    --follow --cluster-config dod-cnc

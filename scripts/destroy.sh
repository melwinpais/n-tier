#!/bin/bash

function delete {
    echo "Deleting $1"
    aws cloudformation delete-stack --stack-name $1
    aws cloudformation wait stack-delete-complete --stack-name $1
    echo "Deleted $1"
} 


echo "Cleaning up up the VPC"

cd ../cloudformation

delete dod-cnc-alb 
delete dod-cnc-base 

echo "Clean up completed"

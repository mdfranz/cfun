#!/bin/bash

regions=$(aws ec2 describe-regions --query 'Regions[*].RegionName' --output text)

for region in $regions
do
    echo "=== $region"
    aws cloudformation list-stacks --region $region --output json | jq '.StackSummaries[]|select(.StackStatus != "DELETE_COMPLETE")|.StackId'
done

#!/bin/bash 

usage() {
    echo "Usage: $0 create|update|delete STACK_NAME TEMPLATE_FILE [CAPABILITIES] [ADDITIONAL_ARGS]"
    exit 1
}

if [ $# -lt 1 ]; then
    usage
fi

ACTION=$1
STACK_NAME=$2
TEMPLATE_FILE=$3
CAPABILITIES=$4
shift 4

case $ACTION in
    create)
        aws cloudformation create-stack --stack-name $STACK_NAME --template-body file://$TEMPLATE_FILE --capabilities $CAPABILITIES "$@"
        ;;
    update)
        aws cloudformation update-stack --stack-name $STACK_NAME --template-body file://$TEMPLATE_FILE --capabilities $CAPABILITIES "$@"
        ;;
    list)
        aws cloudformation list-stacks | jq -r '.StackSummaries[] | select(.StackStatus != "DELETE_COMPLETE")| [.CreationTime, .StackName, .StackStatus ]|@csv'
        ;;
    delete)
        aws cloudformation delete-stack --stack-name $STACK_NAME
        ;;
    *)
        usage
        ;;
esac

if [[ "$ACTION" != "list" ]]
then
  aws cloudformation describe-stack-events --stack-name $STACK_NAME | jq -r '.StackEvents[]|[.ResourceType,.ResourceStatus,.Timestamp]| @csv'
fi

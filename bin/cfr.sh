#!/bin/bash 

#
# A simple wrapper for aws cli cloudformation to save some typing when developing and testing CF Templates
#
# Dependencies 
# - https://github.com/mikefarah/yq
# - https://jqlang.github.io/jq/
# - https://docs.aws.amazon.com/cli/
#

usage() {
    echo "Usage: $0 <create|update|delete> <STACK_NAME> <TEMPLATE_FILE> [CAPABILITIES] [ADDITIONAL_ARGS]"
    echo "or "
    echo "       $0 list "
    echo "       $0 show <TEMPLATE_FILE>"
    echo
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

# Build prefix to handle Service Role

if [ -z "$CFN_EXEC_ARN" ]
then
  echo "WARN: CFN_EXEC_ARN is not set, this may fail"
  CMD_PREFIX=" --stack-name $STACK_NAME"
else
  CMD_PREFIX=" --role-arn $CFN_EXEC_ARN --stack-name $STACK_NAME"
fi

case $ACTION in
    create)
        aws cloudformation create-stack $CMD_PREFIX --template-body file://$TEMPLATE_FILE --capabilities $CAPABILITIES "$@"
        ;;
    update)
        aws cloudformation update-stack $CMD_PREFIX --template-body file://$TEMPLATE_FILE --capabilities $CAPABILITIES "$@"
        ;;
    list)
        aws cloudformation list-stacks | jq -r '.StackSummaries[] | select(.StackStatus != "DELETE_COMPLETE")| [.CreationTime, .StackName, .StackStatus ]|@csv'
        ;;
    delete)
        aws cloudformation delete-stack $CMD_PREFIX
        ;;
    show)
        echo "Showing resources..." ; cat $STACK_NAME | yq '.Resources|keys'; exit 1
        ;;
    *)
        usage
        ;;
esac

if [[ "$ACTION" != "list" ]]
then
  for i in {1..5}
  do
    aws cloudformation describe-stack-events --no-paginate --stack-name $STACK_NAME | jq -r '.StackEvents[]|[.Timestamp, .ResourceType,.ResourceStatus]| @csv'
    echo "Loop $i - You can break at any time, trust me!"
    echo
    sleep 3
    clear
    aws cloudformation describe-stack-events --no-paginate --stack-name $STACK_NAME | jq -r '.StackEvents[]|[.Timestamp, .ResourceType,.ResourceStatus]| @csv'
  done
fi

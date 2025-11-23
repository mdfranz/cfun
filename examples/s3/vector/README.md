# S3-SQS Vector Example

This example demonstrates how to use Vector to monitor an existing S3 bucket for new objects and print their contents to the console. It uses CloudFormation to create the necessary AWS resources.

## Files

- `s3-sqs.yaml`: A CloudFormation template that creates an SQS queue, an IAM user with limited permissions, and the necessary policies for Vector to receive notifications and access S3 objects.
- `s3_events.py`: A Python script to configure an existing S3 bucket to send `s3:ObjectCreated:*` events to the SQS queue.
- `s3sqs-console.yaml`: A Vector configuration file that defines a `aws_s3` source and a `console` sink.

## Prerequisites

- An existing S3 bucket.
- AWS CLI configured with credentials that have permissions to create CloudFormation stacks, IAM users, and SQS queues.
- Python 3 and `boto3` installed (`pip install boto3`).
- [Vector](https://vector.dev/) installed.

## Steps to Run

### 1. Deploy the CloudFormation Stack

This will create the SQS queue and the IAM user for Vector.

```bash
aws cloudformation deploy \
  --template-file s3-sqs.yaml \
  --stack-name vector-s3-sqs-stack \
  --parameter-overrides ExistingS3BucketName=<YOUR_S3_BUCKET_NAME> \
  --capabilities CAPABILITY_NAMED_IAM
```

Replace `<YOUR_S3_BUCKET_NAME>` with the name of your existing S3 bucket.

After the stack is created, take note of the outputs: `QueueUrl`, `QueueArn`, and `AccessKey`. You will also need the Secret Access Key from the AWS Systems Manager Parameter Store.

### 2. Configure Environment Variables

The following environment variables are required to run the `s3_events.py` script and Vector.

- `AWS_ACCESS_KEY_ID`: The `AccessKey` from the CloudFormation stack output.
- `AWS_SECRET_ACCESS_KEY`: The secret access key for the created IAM user. You can retrieve it from the AWS Systems Manager (SSM) Parameter Store. The parameter name will be in the format `<YOUR_S3_BUCKET_NAME>-S3ReaderSQSWriter`.
- `VECTOR_SQS`: The `QueueUrl` from the CloudFormation stack output.
- `QUEUE_ARN`: The `QueueArn` from the CloudFormation stack output.

You can retrieve the secret key from SSM with the following command:

```bash
aws ssm get-parameter --name "<YOUR_S3_BUCKET_NAME>-S3ReaderSQSWriter" --with-decryption --query "Parameter.Value" --output text
```

### 3. Configure S3 Bucket Notifications

Run the `s3_events.py` script to configure your S3 bucket to send notifications to the SQS queue.

```bash
python s3_events.py --bucket <YOUR_S3_BUCKET_NAME> --queue-arn $QUEUE_ARN
```

### 4. Run Vector

Now you can run Vector with the provided configuration file.

```bash
vector --config s3sqs-console.yaml
```

### 5. Test

Upload a new object to your S3 bucket. You should see the content of the object printed to your console where Vector is running.

## Cleanup

To delete the resources created by this example, delete the CloudFormation stack:

```bash
aws cloudformation delete-stack --stack-name vector-s3-sqs-stack
```

**Note:** This will not remove the notification configuration from your S3 bucket. You will need to remove that manually in the AWS console.

import boto3
import sys
import argparse

def configure_bucket_notification(bucket_name, queue_arn):
    s3 = boto3.client('s3')
    
    print(f"Configuring bucket '{bucket_name}' to notify queue '{queue_arn}'...")
    
    try:
        # Define the notification configuration
        notification_config = {
            'QueueConfigurations': [
                {
                    'Id': 'VectorS3Event',
                    'QueueArn': queue_arn,
                    'Events': ['s3:ObjectCreated:*'] 
                }
            ]
        }
        
        # Apply the configuration
        s3.put_bucket_notification_configuration(
            Bucket=bucket_name,
            NotificationConfiguration=notification_config
        )
        print("✅ Success! S3 bucket notifications updated.")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Link S3 events to SQS for Vector.")
    parser.add_argument("--bucket", required=True, help="The name of your S3 bucket")
    parser.add_argument("--queue-arn", required=True, help="The ARN of the SQS queue (from CFN outputs)")
    
    args = parser.parse_args()
    
    configure_bucket_notification(args.bucket, args.queue_arn)

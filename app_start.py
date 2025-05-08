import boto3

def lambda_handler(event, context):
    ec2_client = boto3.client('ec2')
    
    # EC2 instance ID passed from CloudWatch Event
    instance_id = event['instance_id']
    
    response = ec2_client.start_instances(InstanceIds=[instance_id])
    print(f"Started EC2 instance: {instance_id}")
    
    return {
        'statusCode': 200,
        'body': f"Started EC2 instance {instance_id}"
    }

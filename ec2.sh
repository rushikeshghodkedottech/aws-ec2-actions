#!/bin/bash -x

# Function to check if AWS CLI is installed
function check_awscli_is_installed(){
    if aws --version &> /dev/null
    then 
        echo 'AWS CLI is installed.'
    else 
        echo 'Installing AWS CLI...'
        sudo apt-get install awscli
    fi
}

# AWS Configuration is skipped because we are using GitHub Actions environment variables for AWS credentials
function aws_configuration(){
    echo "AWS CLI has been configured using GitHub Actions secrets."
    aws configure list
}

# Key Pair function - modified for environment variables instead of interactive input
function key_pair() {
    if [ -z "$AWS_KEY_PAIR_NAME" ]; then
        echo "Key Pair name not provided. Exiting."
        exit 1
    else
        echo "Using key pair: $AWS_KEY_PAIR_NAME"
        KEY_PAIR_NAME="$AWS_KEY_PAIR_NAME"
    fi
}

# Security Group function - no interactive prompts, use environment variables or defaults
function security_group(){
    if [ -z "$AWS_SECURITY_GROUP_ID" ]; then
        echo "Using default security group (omitting --security-group-ids)"
        SECURITY_GROUP_ARG=""
    else
        echo "Using security group with ID: $AWS_SECURITY_GROUP_ID"
        SECURITY_GROUP_ARG="--security-group-ids $AWS_SECURITY_GROUP_ID"
    fi
}

# EC2 Instance Creation function
function create_instance(){
    echo "Started Creation of an EC2 instance..."

    local AMI_ID="${AMI_ID:-ami-01f23391a59163da9}"  # Use environment variable or fallback to default
    local INSTANCE_TYPE="${INSTANCE_TYPE:-t2.micro}"  # Use environment variable or fallback to default
    local SUBNET_ID="${}"  # Use environment variable or fallback to default

    INSTANCE_INFO=$(aws ec2 run-instances \
        --image-id "$AMI_ID" \
        --count 1 \
        --instance-type "$INSTANCE_TYPE" \
        --key-name "$KEY_PAIR_NAME" \
        $SECURITY_GROUP_ARG \
        --subnet-id "$SUBNET_ID" \
        --query 'Instances[0].InstanceId' \
        --output text 2>&1)

    if [[ $? -ne 0 ]]; then
        echo "Failed to create EC2 instance: $INSTANCE_INFO"
        return 1
    fi

    echo "EC2 instance created successfully. Instance ID: $INSTANCE_INFO"
}

# Main script execution
if check_awscli_is_installed; then
    aws_configuration
    key_pair
    security_group
    create_instance
else 
    exit 1
fi

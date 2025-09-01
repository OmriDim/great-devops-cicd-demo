#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Check if the required arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <commit-message> <tag>"
    exit 1
fi

# Arguments
COMMIT_MESSAGE=$1
NEW_TAG=$2

# AWS and ECS variables
CLUSTER_NAME="cicd-demo"  # Replace with your ECS cluster name
SERVICE_NAME="mentee-robot"  # Replace with your ECS service name
ECR_REPOSITORY="485701710361.dkr.ecr.eu-north-1.amazonaws.com/mentee-robot"  # Replace with your ECR repository URL
AWS_REGION="eu-north-1"  # Replace with your AWS region

# Step 1: Commit changes
echo "Committing changes..."
git add .
git commit -m "$COMMIT_MESSAGE"

# Step 2: Tag the commit
echo "Tagging the commit with $NEW_TAG..."
git tag -a "$NEW_TAG" -m "$COMMIT_MESSAGE"

# Step 3: Push the commit and tag
echo "Pushing the commit and tag to the remote repository..."
git push origin main
git push origin "$NEW_TAG"

# Step 4: Update ECS task definition
echo "Updating ECS task definition with the new tag: $NEW_TAG..."

# Get the current task definition
echo "CURRENT_TASK_DEF=$(aws ecs describe-services \
  --cluster $CLUSTER_NAME \
  --services $SERVICE_NAME \
  --query ""services[0].taskDefinition"" \
  --output text)"
CURRENT_TASK_DEF=$(aws ecs describe-services \
  --cluster $CLUSTER_NAME \
  --services $SERVICE_NAME \
  --query "services[0].taskDefinition" \
  --output text)

# Get the container definitions from the current task definition
CONTAINER_DEFINITIONS=$(aws ecs describe-task-definition \
  --task-definition $CURRENT_TASK_DEF \
  --query "taskDefinition.containerDefinitions" \
  --output json)

# Update the container image in the container definitions
UPDATED_CONTAINER_DEFINITIONS=$(echo $CONTAINER_DEFINITIONS | jq \
  --arg IMAGE "$ECR_REPOSITORY:$NEW_TAG" \
  '.[0].image = $IMAGE | [.]')

# Register a new task definition with the updated container image
NEW_TASK_DEF=$(aws ecs register-task-definition \
  --family $(echo $CURRENT_TASK_DEF | cut -d'/' -f2 | cut -d':' -f1) \
  --container-definitions "$UPDATED_CONTAINER_DEFINITIONS" \
  --query "taskDefinition.taskDefinitionArn" \
  --output text)

# Update the ECS service to use the new task definition
aws ecs update-service \
  --cluster $CLUSTER_NAME \
  --service $SERVICE_NAME \
  --task-definition $NEW_TASK_DEF \
  --force-new-deployment

echo "ECS task definition updated successfully with the new tag: $NEW_TAG"
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

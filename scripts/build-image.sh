#!/bin/bash
set -e

# Configuration
REGION="${AWS_REGION:-eu-west-1}"
REPO_NAME="${ECR_REPO_NAME:-batch-demo-selenium}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
APP_DIR="${APP_DIR:-./app}"
PLATFORM="${PLATFORM:-linux/amd64}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Docker Image Build & Push Script ===${NC}"

# Get AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URI="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}"

echo "Region:     ${REGION}"
echo "Repository: ${REPO_NAME}"
echo "ECR URI:    ${ECR_URI}"
echo "Tag:        ${IMAGE_TAG}"
echo "Platform:   ${PLATFORM}"
echo ""

# Check if ECR repository exists
echo -e "${YELLOW}Checking ECR repository...${NC}"
if ! aws ecr describe-repositories --repository-names "${REPO_NAME}" --region "${REGION}" &>/dev/null; then
    echo -e "${RED}Error: ECR repository '${REPO_NAME}' does not exist.${NC}"
    echo "Run 'terraform apply' first to create the infrastructure."
    exit 1
fi
echo -e "${GREEN}Repository exists.${NC}"

# Login to ECR
echo -e "${YELLOW}Logging in to ECR...${NC}"
aws ecr get-login-password --region "${REGION}" | docker login --username AWS --password-stdin "${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
echo -e "${GREEN}Login successful.${NC}"

# Build the image
echo -e "${YELLOW}Building image...${NC}"
docker build --platform "${PLATFORM}" -t "${ECR_URI}:${IMAGE_TAG}" "${APP_DIR}"
echo -e "${GREEN}Build complete.${NC}"

# Get local image digest
LOCAL_DIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' "${ECR_URI}:${IMAGE_TAG}" 2>/dev/null | cut -d'@' -f2 || echo "")

# Get remote image digest (if exists)
REMOTE_DIGEST=$(aws ecr describe-images \
    --repository-name "${REPO_NAME}" \
    --image-ids imageTag="${IMAGE_TAG}" \
    --region "${REGION}" \
    --query 'imageDetails[0].imageDigest' \
    --output text 2>/dev/null || echo "None")

echo ""
echo "Local digest:  ${LOCAL_DIGEST:-not yet pushed}"
echo "Remote digest: ${REMOTE_DIGEST}"

# Push the image
echo -e "${YELLOW}Pushing image to ECR...${NC}"
docker push "${ECR_URI}:${IMAGE_TAG}"
echo -e "${GREEN}Push complete.${NC}"

# Get new remote digest
NEW_DIGEST=$(aws ecr describe-images \
    --repository-name "${REPO_NAME}" \
    --image-ids imageTag="${IMAGE_TAG}" \
    --region "${REGION}" \
    --query 'imageDetails[0].imageDigest' \
    --output text)

echo ""
echo -e "${GREEN}=== Success ===${NC}"
echo "Image URI: ${ECR_URI}:${IMAGE_TAG}"
echo "Digest:    ${NEW_DIGEST}"

if [ "${REMOTE_DIGEST}" = "${NEW_DIGEST}" ] && [ "${REMOTE_DIGEST}" != "None" ]; then
    echo -e "${YELLOW}Note: Image unchanged (same digest).${NC}"
else
    echo -e "${GREEN}New image pushed successfully.${NC}"
fi

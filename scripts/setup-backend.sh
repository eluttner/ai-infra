#!/bin/bash

set -e

# Usage: ./scripts/setup-backend.sh <account-id>
# Example: ./scripts/setup-backend.sh 123456789012

ACCOUNT_ID=$1

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

if [ -z "$ACCOUNT_ID" ]; then
    echo -e "${RED}Usage: $0 <account-id>${NC}"
    echo -e "${YELLOW}Example: $0 123456789012${NC}"
    exit 1
fi

# Validate account ID format
if ! [[ "$ACCOUNT_ID" =~ ^[0-9]{12}$ ]]; then
    echo -e "${RED}❌ Invalid account ID format. Must be 12 digits.${NC}"
    exit 1
fi

echo -e "${BLUE}🏗️  Setting up Terraform backend infrastructure...${NC}"
echo -e "${YELLOW}Account ID: $ACCOUNT_ID${NC}"

# Function to create backend resources
create_backend() {
    local region=$1
    local env=$2
    
    echo -e "${YELLOW}📦 Creating backend resources for $env in $region...${NC}"
    
    # S3 bucket for state
    local bucket_name="${ACCOUNT_ID}-terraform-states-${region}"
    echo "  🗂️  Creating S3 bucket: $bucket_name"
    
    aws s3api create-bucket \
        --bucket "$bucket_name" \
        --region "$region" \
        --create-bucket-configuration LocationConstraint="$region" \
        --no-cli-pager || echo "    Bucket may already exist"
    
    # Enable versioning
    aws s3api put-bucket-versioning \
        --bucket "$bucket_name" \
        --versioning-configuration Status=Enabled \
        --no-cli-pager
    
    # Enable encryption
    aws s3api put-bucket-encryption \
        --bucket "$bucket_name" \
        --server-side-encryption-configuration '{
            "Rules": [{
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }]
        }' \
        --no-cli-pager
    
    # Block public access
    aws s3api put-public-access-block \
        --bucket "$bucket_name" \
        --public-access-block-configuration \
            BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true \
        --no-cli-pager
    
    # DynamoDB table for locking
    local table_name="terraform-lock-${ACCOUNT_ID}-macaozinho-${env}"
    echo "  🔒 Creating DynamoDB table: $table_name"
    
    aws dynamodb create-table \
        --table-name "$table_name" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region "$region" \
        --no-cli-pager || echo "    Table may already exist"
    
    echo -e "  ${GREEN}✅ Backend resources created for $env${NC}"
}

# Create backend for dev (us-east-1)
create_backend "us-east-1" "dev"

# Create backend for prod (us-east-2)
create_backend "us-east-2" "prod"

echo -e "${GREEN}🎉 Backend infrastructure setup complete!${NC}"
echo -e "${YELLOW}📝 Next steps:${NC}"
echo -e "${YELLOW}  1. Update the backend configurations in environment files${NC}"
echo -e "${YELLOW}  2. Replace 'ACCOUNT_ID' with '$ACCOUNT_ID' in all backend.tf files${NC}"
echo -e "${YELLOW}  3. Run 'make validate' to check configurations${NC}"
echo -e "${YELLOW}  4. Run 'make plan-dev' to plan dev environment${NC}"
#!/bin/bash

set -e

# Usage: ./scripts/deploy.sh <environment> <component> [action]
# Example: ./scripts/deploy.sh dev vpc plan
# Example: ./scripts/deploy.sh prod app apply

ENVIRONMENT=$1
COMPONENT=$2
ACTION=${3:-plan}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

if [ -z "$ENVIRONMENT" ] || [ -z "$COMPONENT" ]; then
    echo -e "${RED}Usage: $0 <environment> <component> [action]${NC}"
    echo -e "${YELLOW}Environments: dev, prod${NC}"
    echo -e "${YELLOW}Components: vpc, app${NC}"
    echo -e "${YELLOW}Actions: plan, apply, destroy${NC}"
    exit 1
fi

# Validate inputs
if [[ ! "$ENVIRONMENT" =~ ^(dev|prod)$ ]]; then
    echo -e "${RED}❌ Invalid environment: $ENVIRONMENT. Must be 'dev' or 'prod'${NC}"
    exit 1
fi

if [[ ! "$COMPONENT" =~ ^(vpc|app)$ ]]; then
    echo -e "${RED}❌ Invalid component: $COMPONENT. Must be 'vpc' or 'app'${NC}"
    exit 1
fi

if [[ ! "$ACTION" =~ ^(plan|apply|destroy)$ ]]; then
    echo -e "${RED}❌ Invalid action: $ACTION. Must be 'plan', 'apply', or 'destroy'${NC}"
    exit 1
fi

WORK_DIR="environments/$ENVIRONMENT/$COMPONENT"

if [ ! -d "$WORK_DIR" ]; then
    echo -e "${RED}❌ Directory $WORK_DIR does not exist${NC}"
    exit 1
fi

echo -e "${BLUE}🚀 Deploying $COMPONENT to $ENVIRONMENT environment...${NC}"
echo -e "${YELLOW}Working directory: $WORK_DIR${NC}"
echo -e "${YELLOW}Action: $ACTION${NC}"

cd "$WORK_DIR"

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo -e "${RED}❌ terraform.tfvars not found in $WORK_DIR${NC}"
    exit 1
fi

# Warning for production
if [ "$ENVIRONMENT" = "prod" ] && [ "$ACTION" = "apply" ]; then
    echo -e "${YELLOW}⚠️  WARNING: You are about to apply changes to PRODUCTION!${NC}"
    read -p "Are you sure you want to continue? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo -e "${YELLOW}🛑 Deployment cancelled${NC}"
        exit 0
    fi
fi

# Warning for destroy
if [ "$ACTION" = "destroy" ]; then
    echo -e "${RED}🔥 WARNING: You are about to DESTROY resources in $ENVIRONMENT!${NC}"
    read -p "Are you sure you want to continue? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo -e "${YELLOW}🛑 Destroy cancelled${NC}"
        exit 0
    fi
fi

echo -e "${YELLOW}🔧 Initializing Terraform...${NC}"
terraform init

echo -e "${YELLOW}📋 Running terraform $ACTION...${NC}"
case $ACTION in
    plan)
        terraform plan -var-file=terraform.tfvars
        ;;
    apply)
        terraform apply -var-file=terraform.tfvars
        ;;
    destroy)
        terraform destroy -var-file=terraform.tfvars
        ;;
esac

echo -e "${GREEN}✅ $ACTION completed successfully for $COMPONENT in $ENVIRONMENT!${NC}"
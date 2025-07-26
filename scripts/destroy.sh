#!/bin/bash

set -e

# Usage: ./scripts/destroy.sh <environment>
# Example: ./scripts/destroy.sh dev

ENVIRONMENT=$1

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

if [ -z "$ENVIRONMENT" ]; then
    echo -e "${RED}Usage: $0 <environment>${NC}"
    echo -e "${YELLOW}Environments: dev, prod${NC}"
    exit 1
fi

# Validate inputs
if [[ ! "$ENVIRONMENT" =~ ^(dev|prod)$ ]]; then
    echo -e "${RED}❌ Invalid environment: $ENVIRONMENT. Must be 'dev' or 'prod'${NC}"
    exit 1
fi

echo -e "${RED}🔥 WARNING: This will destroy ALL resources in the $ENVIRONMENT environment!${NC}"
echo -e "${RED}This includes:${NC}"
echo -e "${RED}  - ECR repositories and images${NC}"
echo -e "${RED}  - IAM roles and policies${NC}"
echo -e "${RED}  - VPC, subnets, and networking${NC}"
echo -e "${RED}  - Route53 hosted zones${NC}"
echo ""
read -p "Type 'destroy-$ENVIRONMENT' to confirm: " confirm

if [ "$confirm" != "destroy-$ENVIRONMENT" ]; then
    echo -e "${YELLOW}🛑 Destruction cancelled${NC}"
    exit 0
fi

echo -e "${BLUE}🚀 Destroying $ENVIRONMENT environment...${NC}"

# Destroy in reverse order (app first, then vpc)
echo -e "${YELLOW}📦 Destroying application infrastructure...${NC}"
./scripts/deploy.sh "$ENVIRONMENT" app destroy

echo -e "${YELLOW}🌐 Destroying VPC infrastructure...${NC}"
./scripts/deploy.sh "$ENVIRONMENT" vpc destroy

echo -e "${GREEN}💀 $ENVIRONMENT environment destroyed successfully!${NC}"
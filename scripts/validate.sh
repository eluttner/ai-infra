#!/bin/bash

set -e

echo "🔍 Validating Terraform configurations..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to validate a directory
validate_directory() {
    local dir=$1
    echo -e "${YELLOW}Validating $dir...${NC}"
    
    cd "$dir"
    
    # Format check
    echo "  📝 Checking format..."
    if ! terraform fmt -check=true -diff=true; then
        echo -e "  ${RED}❌ Format check failed in $dir${NC}"
        return 1
    fi
    
    # Initialize
    echo "  🔧 Initializing..."
    if ! terraform init -backend=false > /dev/null 2>&1; then
        echo -e "  ${RED}❌ Init failed in $dir${NC}"
        return 1
    fi
    
    # Validate
    echo "  ✅ Validating..."
    if ! terraform validate; then
        echo -e "  ${RED}❌ Validation failed in $dir${NC}"
        return 1
    fi
    
    echo -e "  ${GREEN}✅ $dir validated successfully${NC}"
    cd - > /dev/null
}

# Validate modules
echo -e "${YELLOW}📦 Validating modules...${NC}"
for module in modules/*/; do
    if [ -d "$module" ]; then
        validate_directory "$module"
    fi
done

# Validate environments
echo -e "${YELLOW}🌍 Validating environments...${NC}"
for env_dir in environments/*/*/; do
    if [ -d "$env_dir" ] && [ -f "$env_dir/main.tf" ]; then
        validate_directory "$env_dir"
    fi
done

echo -e "${GREEN}🎉 All validations passed!${NC}"
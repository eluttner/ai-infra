.PHONY: help validate fmt plan-dev plan-prod apply-dev apply-prod destroy-dev destroy-prod

help:
	@echo "Available commands:"
	@echo "  help        - Show this help message"
	@echo "  validate    - Validate all Terraform configurations"
	@echo "  fmt         - Format all Terraform files"
	@echo "  plan-dev    - Plan dev environment (vpc and app)"
	@echo "  plan-prod   - Plan prod environment (vpc and app)"
	@echo "  apply-dev   - Apply dev environment (vpc and app)"
	@echo "  apply-prod  - Apply prod environment (vpc and app)"
	@echo "  destroy-dev - Destroy dev environment"
	@echo "  destroy-prod- Destroy prod environment"

validate:
	@./scripts/validate.sh

fmt:
	@echo "🎨 Formatting Terraform files..."
	@terraform fmt -recursive

plan-dev:
	@echo "📋 Planning dev environment..."
	@./scripts/deploy.sh dev vpc plan
	@./scripts/deploy.sh dev app plan

plan-prod:
	@echo "📋 Planning prod environment..."
	@./scripts/deploy.sh prod vpc plan
	@./scripts/deploy.sh prod app plan

apply-dev:
	@echo "🚀 Applying dev environment..."
	@./scripts/deploy.sh dev vpc apply
	@./scripts/deploy.sh dev app apply

apply-prod:
	@echo "🚀 Applying prod environment..."
	@./scripts/deploy.sh prod vpc apply
	@./scripts/deploy.sh prod app apply

destroy-dev:
	@./scripts/destroy.sh dev

destroy-prod:
	@./scripts/destroy.sh prod
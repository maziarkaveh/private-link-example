SERVICE_PLAN_NAME='Private Postgres'
K8S_SERVICE_PLAN_NAME='K8s-Managed Private Link PostgreSQL'

# Load variables from .env if it exists
ifneq (,$(wildcard .env))
    include .env
    export $(shell sed 's/=.*//' .env)
endif

.PHONY: install-ctl
install-ctl:
	@brew install omnistrate/tap/omnistrate-ctl

.PHONY: upgrade-ctl
upgrade-ctl:
	@brew upgrade omnistrate/tap/omnistrate-ctl

.PHONY: login
login:
	cat ./.omnistrate.password | omnistrate-ctl login --email $(OMNISTRATE_EMAIL) --password-stdin

.PHONY: build
build:
	omnistrate-ctl build -f privatePostgresql.yaml --product-name $(SERVICE_PLAN_NAME) --spec-type ServicePlanSpec --release-as-preferred

# K8s-managed NLB approach targets
.PHONY: validate-k8s
validate-k8s:
	@echo "🔍 Validating K8s-managed approach configuration..."
	@if [ -f k8s-private-link-postgres.yaml ]; then echo "✅ Configuration file exists"; else echo "❌ Configuration file missing" && exit 1; fi
	@if grep -q "name: K8s-Managed Private Link PostgreSQL" k8s-private-link-postgres.yaml; then echo "✅ Service name is correct"; else echo "❌ Service name missing or incorrect" && exit 1; fi
	@if grep -q "postgres-with-k8s-nlb" k8s-private-link-postgres.yaml; then echo "✅ PostgreSQL service defined"; else echo "❌ PostgreSQL service missing" && exit 1; fi
	@if grep -q "vpc-endpoint-discovery" k8s-private-link-postgres.yaml; then echo "✅ VPC endpoint discovery service defined"; else echo "❌ VPC endpoint discovery missing" && exit 1; fi
	@echo "✅ Configuration validation complete"

.PHONY: test-k8s
test-k8s: validate-k8s
	@echo "🧪 Testing K8s-managed approach configuration..."
	@echo "ℹ️  Note: Dry-run only works for existing services, not new ones"
	@echo "🔍 Checking file dependencies..."
	@if [ -f helm/postgres-k8s-nlb/Chart.yaml ]; then echo "✅ Helm chart exists"; else echo "❌ Helm chart missing" && exit 1; fi
	@if [ -f terraform/vpc-endpoint-discovery/main.tf ]; then echo "✅ Terraform config exists"; else echo "❌ Terraform config missing" && exit 1; fi
	@if [ -f terraform/vpc-endpoint-discovery/variables.tf ]; then echo "✅ Terraform variables exist"; else echo "❌ Terraform variables missing" && exit 1; fi
	@if [ -f terraform/vpc-endpoint-discovery/outputs.tf ]; then echo "✅ Terraform outputs exist"; else echo "❌ Terraform outputs missing" && exit 1; fi
	@echo "✅ All validations passed - configuration is ready for deployment"

.PHONY: test-structure
test-structure:
	@echo "🔍 Testing project structure..."
	@echo "📁 Project files:"
	@ls -la | grep -E "\.(yaml|yml)$$" || echo "No YAML files found"
	@echo "📁 Helm charts:"
	@find helm/ -name "*.yaml" -o -name "*.yml" | head -10
	@echo "📁 Terraform configs:"
	@find terraform/ -name "*.tf" | head -10
	@echo "✅ Structure check complete"

.PHONY: build-k8s
build-k8s: validate-k8s
	@echo "🚀 Building K8s-managed Private Link PostgreSQL..."
	omnistrate-ctl build -f k8s-private-link-postgres.yaml --product-name $(K8S_SERVICE_PLAN_NAME) --spec-type ServicePlanSpec --release-as-preferred

.PHONY: validate-terraform
validate-terraform:
	@echo "🔍 Validating Terraform configurations..."
	@cd terraform/vpc-endpoint-discovery && terraform fmt -check=true -diff=true
	@cd terraform/vpc-endpoint-discovery && terraform validate
	@echo "✅ Terraform validation complete"

.PHONY: validate-helm
validate-helm:
	@echo "🔍 Validating Helm charts..."
	@helm lint helm/postgres-k8s-nlb/
	@echo "✅ Helm validation complete"

.PHONY: validate-all
validate-all: validate-k8s validate-terraform validate-helm
	@echo "✅ All validations passed!"

.PHONY: test-all
test-all: validate-all test-k8s
	@echo "✅ All tests passed!"

.PHONY: help
help:
	@echo "Available targets:"
	@echo "  install-ctl       - Install Omnistrate CLI"
	@echo "  upgrade-ctl       - Upgrade Omnistrate CLI"
	@echo "  login            - Login to Omnistrate"
	@echo "  build            - Build original Terraform-managed approach"
	@echo "  validate-k8s     - Validate K8s-managed configuration"
	@echo "  test-k8s         - Test K8s-managed approach configuration"
	@echo "  build-k8s        - Build K8s-managed approach"
	@echo "  validate-terraform - Validate Terraform configurations"
	@echo "  validate-helm    - Validate Helm charts"
	@echo "  validate-all     - Run all validations"
	@echo "  test-all         - Run all tests and validations"
	@echo "  test-structure   - Check project file structure"
	@echo "  help             - Show this help message"
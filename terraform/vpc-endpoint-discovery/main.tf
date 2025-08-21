# Terraform configuration that discovers Kubernetes-created NLB and creates VPC Endpoint Service
# This approach relies on deterministic tags set by the Kubernetes Service

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "{{ $sys.deploymentCell.region }}"
}

locals {
  instance_id      = "{{ $sys.id }}"
  service_name     = var.serviceName
  connectAccountID = var.connectAccountID
  # Split comma-separated account IDs and filter out empty values
  connectAccountIDs = compact(split(",", replace(local.connectAccountID, " ", "")))
}

# Discover the NLB created by Kubernetes Service with deterministic tags
data "aws_lb" "k8s_created_nlb" {
  tags = {
    # Tags that are deterministically set by the Kubernetes Service
    "omnistrate-instance"   = local.instance_id
    "omnistrate-service"    = "postgres-nlb"
    "service.k8s.aws/stack" = "${local.instance_id}/postgres-nlb"
    "elbv2.k8s.aws/cluster" = "{{ $sys.deployment.kubernetesClusterID }}"
  }
}

# Create VPC Endpoint Service using the Kubernetes-created NLB
resource "aws_vpc_endpoint_service" "postgres_vpce_service" {
  acceptance_required        = false # Auto-approve endpoint connections
  network_load_balancer_arns = [data.aws_lb.k8s_created_nlb.arn]

  # Optional: Specify allowed principals during creation
  allowed_principals = length(local.connectAccountIDs) > 0 ? [
    for account_id in local.connectAccountIDs : "arn:aws:iam::${account_id}:root"
  ] : []

  tags = {
    Name                = "${local.instance_id}-postgres-vpce-service"
    omnistrate-instance = local.instance_id
    omnistrate-service  = "postgres-private-link"
    environment         = "production"
    managed-by          = "terraform"
    k8s-nlb-source      = data.aws_lb.k8s_created_nlb.name
  }
}

# Manage VPC endpoint service permissions (alternative to allowed_principals)
resource "aws_vpc_endpoint_service_allowed_principal" "postgres_connect_accounts" {
  count                   = length(local.connectAccountIDs)
  vpc_endpoint_service_id = aws_vpc_endpoint_service.postgres_vpce_service.id
  principal_arn           = "arn:aws:iam::${local.connectAccountIDs[count.index]}:root"
}



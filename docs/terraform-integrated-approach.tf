# Enhanced Terraform Configuration for Private Link with Integrated Target Group Binding
# This approach consolidates both infrastructure and Kubernetes resources in Terraform

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = "{{ $sys.deploymentCell.region }}"
}

# Configure Kubernetes provider to connect to the current cluster
provider "kubernetes" {
  host                   = "{{ $sys.deployment.kubernetesClusterEndpoint }}"
  cluster_ca_certificate = base64decode("{{ $sys.deployment.kubernetesClusterCACertificate }}")
  token                  = "{{ $sys.deployment.kubernetesServiceAccountToken }}"
}

locals {
  name = "{{ $sys.id }}"
  connectAccountID = "{{ $var.connectAccountID }}"
  # Split comma-separated account IDs and filter out empty values
  connectAccountIDs = compact(split(",", replace(local.connectAccountID, " ", "")))
  namespace = "{{ $sys.id }}"
}

# Data source to get the existing ingress controller NLB using deterministic K8s tags
data "aws_lb" "ingress_nlb" {
  tags = {
    "service.k8s.aws/stack" = "${local.name}/nginx-ingress"
    "elbv2.k8s.aws/cluster" = "{{ $sys.deployment.kubernetesClusterID }}"
  }
}

# Create target group specifically for datarobot-nginx
resource "aws_lb_target_group" "datarobot_nginx_tg" {
  name        = "${local.name}-nginx-tg"
  port        = 8080 # datarobot-nginx pod port (targetPort)
  protocol    = "TCP"
  vpc_id      = "{{ $sys.deploymentCell.cloudProviderNetworkID }}"
  target_type = "ip"

  health_check {
    port                = "traffic-port"
    protocol            = "HTTP"
    path                = "/"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = {
    Name        = "${local.name}-nginx-target-group"
    application = local.name
    environment = "production"
    managed-by  = "terraform"
  }
}

# Add listener to existing ingress NLB for VPC endpoint access
resource "aws_lb_listener" "datarobot_vpce_listener" {
  load_balancer_arn = data.aws_lb.ingress_nlb.arn
  port              = 8080  # Use port 8080 for VPC endpoint access
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.datarobot_nginx_tg.arn
  }

  tags = {
    Name        = "${local.name}-vpce-listener"
    application = local.name
    environment = "production"
    managed-by  = "terraform"
  }
}

# Data source for existing NLB security groups
data "aws_security_group" "nlb_security_groups" {
  count = length(data.aws_lb.ingress_nlb.security_groups)
  id    = tolist(data.aws_lb.ingress_nlb.security_groups)[count.index]
}

# Add security group rule to allow port 8080 access
resource "aws_security_group_rule" "nlb_port_8080_ingress" {
  count             = length(data.aws_lb.ingress_nlb.security_groups)
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  description       = "Allow VPC endpoint access to DataRobot on port 8080"
  security_group_id = tolist(data.aws_lb.ingress_nlb.security_groups)[count.index]
}

# Create the VPC Endpoint Service using existing ingress NLB
resource "aws_vpc_endpoint_service" "datarobot_vpce_service" {
  acceptance_required        = false # Auto-approve endpoint connections
  network_load_balancer_arns = [data.aws_lb.ingress_nlb.arn]

  tags = {
    Name        = "${local.name}-vpce-service"
    application = local.name
    environment = "production"
    managed-by  = "terraform"
  }
}

# Manage VPC endpoint service permissions
resource "aws_vpc_endpoint_service_allowed_principal" "datarobot_connect_account" {
  count                   = length(local.connectAccountIDs)
  vpc_endpoint_service_id = aws_vpc_endpoint_service.datarobot_vpce_service.id
  principal_arn          = "arn:aws:iam::${local.connectAccountIDs[count.index]}:root"
}

# INTEGRATED TARGET GROUP BINDING - Replaces the Kustomize approach
# This creates the Target Group Binding directly in Terraform
resource "kubernetes_manifest" "datarobot_nginx_vpce_tgb" {
  manifest = {
    apiVersion = "elbv2.k8s.aws/v1beta1"
    kind       = "TargetGroupBinding"
    
    metadata = {
      name      = "datarobot-nginx-vpce-tgb"
      namespace = local.namespace
    }
    
    spec = {
      serviceRef = {
        name = "datarobot-nginx"
        port = 80
      }
      targetGroupARN = aws_lb_target_group.datarobot_nginx_tg.arn
      networking = {
        ingress = [
          {
            from = [
              {
                ipBlock = {
                  cidr = "10.0.0.0/16"  # Customer VPC CIDR - allows VPC endpoint ENI traffic
                }
              }
            ]
            ports = [
              {
                port     = 8080
                protocol = "TCP"
              }
            ]
          }
        ]
      }
    }
  }

  # Ensure the target group is created before the binding
  depends_on = [
    aws_lb_target_group.datarobot_nginx_tg
  ]
}

# Optional: Create NetworkPolicy for additional security (if using CNI that supports it)
resource "kubernetes_network_policy" "datarobot_vpce_access" {
  metadata {
    name      = "datarobot-vpce-access"
    namespace = local.namespace
  }

  spec {
    pod_selector {
      match_labels = {
        app = "datarobot-nginx"
      }
    }

    policy_types = ["Ingress"]

    ingress {
      from {
        ip_block {
          cidr = "10.0.0.0/16"  # Customer VPC CIDR
        }
      }
      
      ports {
        port     = "8080"
        protocol = "TCP"
      }
    }
  }
}

# Outputs
output "vpc_endpoint_service_name" {
  description = "The service name of the VPC endpoint service"
  value       = aws_vpc_endpoint_service.datarobot_vpce_service.service_name
}

output "vpc_endpoint_service_dns_name" {
  description = "The DNS name of the VPC endpoint service"
  value       = aws_vpc_endpoint_service.datarobot_vpce_service.service_name
}

output "target_group_arn_datarobot_nginx" {
  description = "The ARN of the DataRobot nginx target group"
  value       = aws_lb_target_group.datarobot_nginx_tg.arn
}

output "allowed_account_ids" {
  description = "The account IDs allowed to connect to the VPC endpoint service"
  value       = local.connectAccountIDs
}

output "target_group_binding_name" {
  description = "The name of the Target Group Binding"
  value       = kubernetes_manifest.datarobot_nginx_vpce_tgb.manifest.metadata.name
}

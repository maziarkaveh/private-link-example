# Network Flow Diagram

### Network Flow Diagram

```text
[Client VPC] → [VPC Endpoint] → [VPC Endpoint Service] → [NLB] → [DataRobot Pods]
```

### Detailed Flow


1. **Client Request** → VPC Endpoint (port 8080)
2. **VPC Endpoint** → VPC Endpoint Service
3. **VPC Endpoint Service** → Ingress NLB Listener (port 8080)
4. **NLB Listener** → Target Group
5. **Target Group** → datarobot-nginx Pods
6. **datarobot-nginx** → DataRobot Application

### Service Plan Configuration

Add the VPC endpoint services(will b e replace by datarobot-infra) to your Omnistrate service plan:

```yaml

services:
  - name: vpc-endpoint
    internal: true
    terraformConfigurations:
      configurationPerCloudProvider:
        aws:
          terraformPath: /terraform/vpc-endpoint-example
    apiParameters:
      - key: connectAccountID
        description: "Comma-separated AWS account IDs for VPC endpoint access"
        required: true
    requiredOutputs:
      - key: "vpc_endpoint_service_name"
        exported: true
      - key: "allowed_account_ids"
        exported: true 
      - key: "target_group_arn_datarobot_nginx"
        exported: false

  - name: vpc-endpoint-kubernetes
    internal: true
    dependsOn:
      - vpc-endpoint
    kustomizeConfigurations:
      configurationPerCloudProvider:
        aws:
          kustomizePath: /kustomize/vpc-endpoint
```

## Configuration Details

### Terraform Implementation

#### Provider and Variables Configuration

```hcl

provider "aws" {
  region = "{{ $sys.deploymentCell.region }}"
}

locals {
  name = "{{ $sys.id }}"
  connectAccountID = "{{ $var.connectAccountID }}"
  # Split comma-separated account IDs and filter out empty values
  connectAccountIDs = compact(split(",", replace(local.connectAccountID, " ", "")))
}
```

#### Existing NLB Discovery

```hcl
# Data source to get the existing ingress controller NLB using deterministic K8s tags

data "aws_lb" "ingress_nlb" {
  tags = {
    "service.k8s.aws/stack" = "${local.name}/nginx-ingress"
    "elbv2.k8s.aws/cluster" = "{{ $sys.deployment.kubernetesClusterID }}"
  }
}
```

#### Target Group Creation

```hcl
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
```

#### NLB Listener Configuration

```hcl
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
```

#### Security Group Configuration

```hcl
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
```

#### 6. VPC Endpoint Service

```hcl
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
```

#### 7. Output Configuration

```hcl

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
```

### Kubernetes Configuration

#### Target Group Binding

```yaml

apiVersion: elbv2.k8s.aws/v1beta1

kind: TargetGroupBinding

metadata:
  name: datarobot-nginx-vpce-tgb
  namespace: "{{ $sys.id }}"
spec:
  serviceRef:
    name: datarobot-nginx
    port: 80
  targetGroupARN: "{{ $vpc-endpoint.out.target_group_arn_datarobot_nginx }}"
```


---

## Security Requirements

### IAM Policy Configuration

The following IAM policy must be attached to the service role:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowVPCEndpointServiceActions",
      "Effect": "Allow",
      "Action": [
        "ec2:CreateVpcEndpointService",
        "ec2:CreateVpcEndpointServiceConfiguration",
        "ec2:DescribeVpcEndpointServices",
        "ec2:DescribeVpcEndpointServiceConfigurations",
        "ec2:DescribeVpcEndpointServicePermissions",
        "ec2:DeleteVpcEndpointService",
        "ec2:DeleteVpcEndpointServiceConfigurations",
        "ec2:ModifyVpcEndpointService",
        "ec2:ModifyVpcEndpointServiceConfigurations",
        "ec2:ModifyVpcEndpointServicePermissions"
      ],
      "Resource": "*"
    },
    {
      "Sid": "AllowLoadBalancerActions",
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:DescribeLoadBalancers",
        "elasticloadbalancing:DescribeListeners",
        "elasticloadbalancing:DescribeTargetGroups",
        "elasticloadbalancing:CreateListener",
        "elasticloadbalancing:CreateTargetGroup",
        "elasticloadbalancing:ModifyListener",
        "elasticloadbalancing:ModifyTargetGroup",
        "elasticloadbalancing:DeleteListener",
        "elasticloadbalancing:DeleteTargetGroup"
      ],
      "Resource": "*"
    },
    {
      "Sid": "AllowSecurityGroupActions",
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeSecurityGroups",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupIngress"
      ],
      "Resource": "*"
    }
  ]
}
```
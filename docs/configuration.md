# Configuration Reference

This document provides detailed configuration options for the Private Link PostgreSQL example.

## Service Configuration Overview

The Private Link PostgreSQL example is configured through the `privatePostgresql.yaml` file, which defines:

- Service deployment settings
- Infrastructure components
- API parameters
- Network configuration
- Security settings

## Service Plan Structure

### Deployment Configuration

```yaml
name: Private Postgresql Service
deployment:
  hostedDeployment:
    AwsAccountId: '<service-provider-account-id>'
    AwsBootstrapRoleAccountArn: 'arn:aws:iam::<service-provider-account-id>:role/omnistrate-bootstrap-role'
```

| Parameter | Description | Required |
|-----------|-------------|----------|
| `AwsAccountId` | Your AWS account ID where services will be deployed | Yes |
| `AwsBootstrapRoleAccountArn` | IAM role ARN for Omnistrate platform access | Yes |

## Service Definitions

### 1. Terraform Service (Infrastructure)

The Terraform service manages the underlying AWS infrastructure:

```yaml
- name: terraform
  internal: true
  terraformConfigurations:
    configurationPerCloudProvider:
      aws:
        terraformPath: /terraform
        gitConfiguration:
          reference: refs/tags/v0.0.10
          repositoryUrl: https://github.com/omnistrate-community/private-link-example.git
        terraformExecutionIdentity: "arn:aws:iam::<service-provider-account-id>:role/omnistrate-custom-terraform-execution-role"
```

#### Configuration Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `terraformPath` | Path to Terraform files in repository | `/terraform` |
| `reference` | Git tag or branch to use | `refs/tags/v0.0.10` |
| `repositoryUrl` | Git repository containing Terraform code | GitHub URL |
| `terraformExecutionIdentity` | IAM role for Terraform execution | Custom role ARN |

#### Required Outputs

The Terraform service must provide these outputs:

| Output | Description | Exported |
|--------|-------------|----------|
| `vpc_endpoint_service_name` | VPC Endpoint Service name for private connectivity | Yes |
| `vpc_endpoint_service_dns_name` | DNS name for the VPC Endpoint Service | Yes |
| `target_group_arn` | Load balancer target group ARN | No |

### 2. Helm Service (Database)

The Helm service deploys PostgreSQL using the Bitnami chart:

```yaml
- name: helm
  internal: true
  dependsOn:
    - terraform
  compute:
    instanceTypes:
      - apiParam: instanceType
        cloudProvider: aws
      - apiParam: instanceType
        cloudProvider: gcp
```

#### Network Configuration

```yaml
  network:
    ports:
      - 5432
  capabilities:
    networkType: "INTERNAL"
```

#### Helm Chart Settings

| Setting | Value | Description |
|---------|-------|-------------|
| `chartName` | `postgresql` | Bitnami PostgreSQL chart |
| `chartVersion` | `16.3.2` | Chart version |
| `chartRepoURL` | `https://charts.bitnami.com/bitnami` | Bitnami repository |

#### PostgreSQL Configuration

```yaml
global:
  postgresql:
    auth:
      postgresPassword: "{{ $var.password }}"
      password: "{{ $var.password }}"
      username: "{{ $var.username }}"
      database: "postgres"
```

#### Resource Limits

```yaml
primary:
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 150m
      memory: 256Mi
```

#### Node Affinity Rules

The service uses specific node affinity rules:

```yaml
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
        - matchExpressions:
            - key: omnistrate.com/managed-by
              operator: In
              values:
                - omnistrate
            - key: topology.kubernetes.io/region
              operator: In
              values:
                - $sys.deploymentCell.region
```

### 3. Private PostgreSQL Service (Endpoint)

The private PostgreSQL service provides the customer-facing endpoint:

```yaml
- name: privatePostgres
  dependsOn:
    - terraform
    - helm
  passive: true
  endpointConfiguration:
    postgres:
      host: "{{ $terraform.out.vpc_endpoint_service_name }}"
      ports:
        - 5432
      primary: true
      networkingType: PRIVATE
```

#### Kustomize Configuration

```yaml
kustomizeConfiguration:
  kustomizePath: /kustomize
  gitConfiguration:
    reference: refs/tags/v0.0.10
    repositoryUrl: https://github.com/omnistrate-community/private-link-example.git
```

## API Parameters

### Service-Level Parameters

#### Connect Account ID

```yaml
- key: connectAccountID
  description: Account ID to connect to
  name: Connect Account ID
  type: String
  modifiable: true
  required: true
  export: true
```

Customer AWS account ID that will be allowed to create VPC endpoints.

#### Instance Type

```yaml
- key: instanceType
  description: Instance Type
  name: Instance Type
  type: String
  modifiable: true
  required: false
  export: true
  defaultValue: t4g.small
```

EC2 instance type for the PostgreSQL container.

**Supported Instance Types:**

- `t4g.nano` - 2 vCPU, 0.5 GB RAM
- `t4g.micro` - 2 vCPU, 1 GB RAM
- `t4g.small` - 2 vCPU, 2 GB RAM (default)
- `t4g.medium` - 2 vCPU, 4 GB RAM
- `t4g.large` - 2 vCPU, 8 GB RAM

#### Database Credentials

```yaml
- key: username
  description: Username
  name: Username
  type: String
  modifiable: true
  required: false
  export: true
  defaultValue: username

- key: password
  description: Default DB Password
  name: Password
  type: String
  modifiable: false
  required: false
  export: false
  defaultValue: postgres
```

### Parameter Dependencies

Parameters use dependency mapping to pass values between services:

```yaml
parameterDependencyMap:
  terraform: connectAccountID
  helm: username
```

This ensures the same parameter values are used across all services.

## Infrastructure Components

### AWS Network Load Balancer

Created by Terraform with the following configuration:

```terraform
resource "aws_lb" "ps_lb" {
  name               = "postgres-nlb"
  internal           = false
  load_balancer_type = "network"
  security_groups    = [aws_security_group.nlb_sg.id, "{{ $sys.deploymentCell.securityGroupID }}"]
  enable_cross_zone_load_balancing = true
}
```

### Security Group

```terraform
resource "aws_security_group" "nlb_sg" {
  name        = "nlb-security-group"
  description = "Security group for NLB"
  vpc_id      = "{{ $sys.deploymentCell.cloudProviderNetworkID }}"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["{{ $sys.deploymentCell.cidrRange }}"]
  }
}
```

### Target Group

```terraform
resource "aws_lb_target_group" "ps_target_group" {
  name     = "postgres-target-group"
  port     = 5432
  protocol = "TCP"
  vpc_id   = "{{ $sys.deploymentCell.cloudProviderNetworkID }}"
  target_type = "ip"

  health_check {
    port                = "traffic-port"
    protocol            = "TCP"
    interval            = 30
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}
```

### VPC Endpoint Service

```terraform
resource "aws_vpc_endpoint_service" "pg_vpc_endpoint_service" {
  acceptance_required         = false
  network_load_balancer_arns  = [aws_lb.ps_lb.arn]
  allowed_principals          = ["arn:aws:iam::{{ $var.connectAccountID }}:root"]
}
```

## Kustomize Resources

### Target Group Binding

The Target Group Binding connects the Kubernetes service to the AWS load balancer:

```yaml
apiVersion: elbv2.k8s.aws/v1beta1
kind: TargetGroupBinding
metadata:
  name: postgres-targetgroup-binding
  namespace: "{{ $sys.id }}"
spec:
  serviceRef:
    name: helm-postgresql
    port: 5432
  targetGroupARN: "{{ $terraform.out.target_group_arn }}"
```

## System Variables

The configuration uses several Omnistrate system variables:

| Variable | Description |
|----------|-------------|
| `$sys.deploymentCell.region` | AWS region for deployment |
| `$sys.deploymentCell.cloudProviderNetworkID` | VPC ID |
| `$sys.deploymentCell.cidrRange` | VPC CIDR range |
| `$sys.deploymentCell.securityGroupID` | Default security group |
| `$sys.deploymentCell.privateSubnetIDs` | Private subnet IDs |
| `$sys.id` | Unique system identifier |
| `$sys.compute.node.instanceType` | Node instance type |
| `$sys.deployment.resourceID` | Resource identifier |

## Environment-Specific Configuration

### Development Environment

For development environments, consider:

- Smaller instance types (`t4g.nano`, `t4g.micro`)
- Reduced resource limits
- Extended health check intervals

### Production Environment

For production environments, use:

- Larger instance types (`t4g.large` or higher)
- Increased resource limits
- Multiple availability zones
- Enhanced monitoring

## Customization Options

### Custom PostgreSQL Configuration

To add custom PostgreSQL configuration:

1. **Modify Helm Values**: Add custom configuration to the `chartValues` section
2. **ConfigMaps**: Create ConfigMaps with custom postgresql.conf
3. **Init Scripts**: Add initialization scripts for schema setup

### Custom Security Groups

To add custom security group rules:

1. **Modify Terraform**: Update the security group resource
2. **Additional Rules**: Add ingress/egress rules as needed
3. **Source CIDR**: Customize allowed IP ranges

### Multi-Region Deployment

For multi-region deployments:

1. **Region Parameters**: Add region-specific parameters
2. **Cross-Region Replication**: Configure read replicas
3. **DNS Configuration**: Set up Route 53 for failover

## Validation and Testing

### Configuration Validation

```bash
# Validate YAML syntax
yamllint privatePostgresql.yaml

# Validate with Omnistrate CLI
omnistrate-ctl validate -f privatePostgresql.yaml
```

### Testing Parameters

Test different parameter combinations:

1. **Instance Types**: Test various EC2 instance types
2. **Credentials**: Verify custom username/password combinations
3. **Account IDs**: Test with different customer account IDs

## Best Practices

1. **Security**: Never commit sensitive values to version control
2. **Validation**: Always validate configuration before deployment
3. **Documentation**: Document any custom modifications
4. **Testing**: Test configuration changes in development first
5. **Monitoring**: Implement comprehensive monitoring and alerting

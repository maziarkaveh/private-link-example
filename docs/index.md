# Private Link PostgreSQL Example

This example demonstrates how to build a private PostgreSQL SaaS using AWS VPC Endpoint Services (Private Link) with the Omnistrate platform. It showcases advanced networking features that enable secure, private connectivity between your service and customer environments.

## Overview

The Private Link PostgreSQL example implements a secure database-as-a-service solution that leverages AWS Private Link technology to provide:

- **Private Network Connectivity**: Direct, secure connections between customer VPCs and your PostgreSQL service without internet exposure
- **Multi-Cloud Support**: Ready for AWS with GCP configuration template included
- **Enterprise Security**: Traffic never traverses the public internet
- **Scalable Architecture**: Network Load Balancer with Target Group binding for high availability
- **Automated Infrastructure**: Complete infrastructure-as-code setup using Terraform

## Architecture

The example consists of three main services working together:

### 1. Terraform Service (Infrastructure)

- Creates AWS Network Load Balancer (NLB) with security groups
- Sets up Target Groups for PostgreSQL traffic on port 5432
- Provisions VPC Endpoint Service for private connectivity
- Configures allowed principals for customer account access

### 2. Helm Service (Database)

- Deploys PostgreSQL using Bitnami Helm chart
- Configures PostgreSQL with custom authentication
- Sets up resource limits and node affinity rules
- Implements exclusive scheduling for performance isolation

### 3. Private PostgreSQL Service (Endpoint)

- Exposes PostgreSQL through private networking
- Binds database service to load balancer target group
- Provides secure endpoint configuration for customers

## Key Features

- **VPC Endpoint Service**: Enables AWS Private Link connectivity
- **Network Load Balancer**: High-performance load balancing for database traffic
- **Target Group Binding**: Automatic service discovery and load balancer integration
- **Security Groups**: Fine-grained network access control
- **Parameter Management**: Configurable database credentials and connection settings
- **Multi-Environment Support**: Development, staging, and production configurations

## Prerequisites

Before using this example, ensure you have:

1. **Omnistrate Account**: Sign up at [omnistrate.cloud](https://omnistrate.cloud)
2. **AWS Account**: Service provider account with proper IAM roles
3. **Omnistrate CLI**: Download from [ctl.omnistrate.cloud](https://ctl.omnistrate.cloud/install/)
4. **Customer AWS Account**: For testing private endpoint connections

## Quick Start

1. **Clone and Configure**:

   ```bash
   git clone https://github.com/omnistrate-community/private-link-example.git
   cd private-link-example
   ```

2. **Set Up Environment**:

   ```bash
   cp .env.template .env
   # Edit .env with your Omnistrate email
   
   cp .omnistrate.password.template .omnistrate.password
   # Add your Omnistrate password to .omnistrate.password
   ```

3. **Update Service Configuration**:

   ```bash
   # Replace <service-provider-account-id> in privatePostgresql.yaml
   # with your actual AWS account ID
   sed -i 's/<service-provider-account-id>/123456789012/g' privatePostgresql.yaml
   ```

4. **Build and Deploy**:

   ```bash
   make login
   make build
   ```

## What Gets Created

When you deploy this example, Omnistrate creates:

### AWS Infrastructure

- **Network Load Balancer**: High-performance TCP load balancer for PostgreSQL traffic
- **Security Group**: Network access control for port 5432
- **Target Group**: Health-checked backend targets for the load balancer
- **VPC Endpoint Service**: Private Link service for customer connections

### Kubernetes Resources

- **PostgreSQL Pod**: Bitnami PostgreSQL container with custom configuration
- **Service**: Kubernetes service for internal cluster access
- **Target Group Binding**: AWS Load Balancer Controller resource linking Kubernetes service to ALB target group
- **Config Maps**: PostgreSQL configuration and initialization scripts

### Omnistrate Resources

- **Service Plan**: Complete SaaS offering definition
- **API Parameters**: Customer-configurable settings
- **Endpoints**: Private network endpoint for customer connections
- **Deployment Configurations**: Multi-cloud deployment settings

## Configuration Parameters

The example exposes several configurable parameters:

| Parameter | Description | Type | Default | Required |
|-----------|-------------|------|---------|----------|
| `username` | PostgreSQL username | String | `username` | No |
| `password` | PostgreSQL password | String | `postgres` | No |
| `connectAccountID` | Customer AWS account ID | String | - | Yes |
| `instanceType` | EC2 instance type | String | `t4g.small` | No |

## Advanced Features

### Private Link Integration

The example demonstrates advanced Private Link features:

- **Auto-approval**: Endpoint connections are automatically approved
- **Cross-account Access**: Secure connections from customer accounts
- **DNS Resolution**: Automatic DNS name generation for private endpoints

### Load Balancer Configuration

- **Cross-zone Load Balancing**: Enabled for high availability
- **Health Checks**: TCP health checks on port 5432
- **Internal Architecture**: Private subnet deployment for security

### Kubernetes Integration

- **Target Group Binding**: Automatic integration with AWS Load Balancer Controller
- **Affinity Rules**: Node and pod affinity for performance optimization
- **Resource Management**: CPU and memory limits for predictable performance

## Testing Private Connectivity

To test the private connection from a customer account:

1. **Create VPC Endpoint in Customer Account**:

   ```bash
   aws ec2 create-vpc-endpoint \
     --vpc-id vpc-customer-123 \
     --service-name com.amazonaws.vpce.region.vpce-svc-xyz \
     --vpc-endpoint-type Interface \
     --subnet-ids subnet-abc123
   ```

2. **Connect to PostgreSQL**:

   ```bash
   psql -h vpce-xyz.region.vpce.amazonaws.com -p 5432 -U username -d postgres
   ```

## Security Considerations

- **Network Isolation**: All traffic remains within AWS backbone
- **Account Separation**: Each customer uses their own VPC endpoint
- **Access Control**: IAM-based access control for endpoint creation
- **Encryption**: PostgreSQL SSL/TLS encryption for data in transit

## Monitoring and Observability

The example includes built-in monitoring capabilities:

- **Health Checks**: Load balancer health monitoring
- **Metrics**: CloudWatch metrics for load balancer and target groups
- **Logs**: PostgreSQL logs accessible through Kubernetes
- **Omnistrate Monitoring**: Platform-level monitoring and alerting

## Troubleshooting

Common issues and solutions:

1. **Connection Timeouts**: Verify security group rules and VPC endpoint configuration
2. **Authentication Failures**: Check PostgreSQL credentials and user permissions
3. **Health Check Failures**: Ensure PostgreSQL is accepting connections on port 5432
4. **DNS Resolution**: Verify VPC endpoint DNS configuration

## Related Examples

- [Vector Database (PostgreSQL with pgvector)](../dbaas/index.md): PostgreSQL with vector search capabilities
- [MySQL Master-Replica](../mysql-master-replica-serverless/index.md): MySQL high availability setup
- [Prometheus BYOC](../prometheus-byoc/index.md): Monitoring in customer cloud

## Next Steps

1. **Customize Database Configuration**: Modify PostgreSQL settings for your use case
2. **Add Backup Solutions**: Implement automated backup and restore procedures
3. **Implement Monitoring**: Add custom metrics and alerting
4. **Scale Architecture**: Configure read replicas and connection pooling
5. **Security Hardening**: Implement additional security measures

## Blog Post

For more detailed information about this example, see our [blog post](https://blog.omnistrate.com/posts/115) on private link implementation.

## Support

For questions or issues with this example:

- Check the [troubleshooting section](#troubleshooting)
- Review the [Omnistrate documentation](https://docs.omnistrate.cloud)
- Contact support through the Omnistrate platform

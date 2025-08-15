# Private Link Example - Complete Documentation

## Overview

This package provides two different approaches for implementing **AWS Private Link** connectivity with PostgreSQL database services on the Omnistrate platform:

1. **Terraform-Managed Approach** (Traditional) - NLB and Security Groups managed by Terraform
2. **Kubernetes-Managed Approach** (Modern) - NLB and Security Groups managed by Kubernetes using TargetGroupBinding

## 🎯 Key Achievement

**Successfully built and deployed** the Kubernetes-managed approach using Omnistrate CLI:
- ✅ Service Plan validated and deployed
- ✅ Service ID: `s-58IqaSDXuj`
- ✅ Plan ID: `pt-YKLTiTeTgE`
- ✅ Available at: https://omnistrate.cloud/product-tier?serviceId=s-58IqaSDXuj&environmentId=se-fX2TgN4Q1E

## 📁 Project Structure

```
private-link-example/
├── README.md                           # This comprehensive documentation
├── K8S_MANAGED_README.md              # Kubernetes-managed approach details
├── privatePostgresql.yaml             # Main service plan (environment variables)
├── k8s-managed-service-plan.yaml      # Alternative K8s service plan
├── simple-postgres-nlb.yaml           # Simplified K8s example
├── docs/                              # Complete documentation suite
│   ├── README.md                      # Documentation index
│   ├── architecture.md                # Architecture overview
│   ├── configuration.md               # Configuration guide
│   ├── installation.md                # Installation steps
│   ├── security.md                    # Security considerations
│   ├── troubleshooting.md             # Common issues and solutions
│   ├── COMPARISON.md                  # Detailed approach comparison
│   ├── service-plan-integrated.yaml   # Integrated service plan example
│   └── terraform-integrated-approach.tf # Terraform integrated example
├── terraform/                         # Terraform infrastructure
│   ├── main.tf                       # Main Terraform configuration
│   └── vpc-endpoint-discovery/        # VPC endpoint discovery module
├── kustomize/                         # Kubernetes customizations
│   ├── kustomization.yaml            # Kustomize configuration
│   └── targetGroupBinding.yaml       # ALB Target Group Binding
├── helm/                             # Helm chart for PostgreSQL
│   └── postgres-k8s-nlb/            # Kubernetes-managed NLB PostgreSQL
└── Makefile                          # Build and deployment commands
```

## 🏗️ Architecture Comparison

### Terraform-Managed Approach (Traditional)
- **Infrastructure**: Terraform creates and manages NLB + Security Groups
- **Deployment**: Kubernetes handles application deployment only
- **Coupling**: Tight coupling between infrastructure and application layers
- **Flexibility**: Limited runtime modification capabilities

### Kubernetes-Managed Approach (Modern) ⭐
- **Infrastructure**: Kubernetes creates and manages NLB via AWS Load Balancer Controller
- **Deployment**: Unified Kubernetes-based deployment with TargetGroupBinding
- **Coupling**: Loose coupling, infrastructure managed declaratively
- **Flexibility**: Dynamic scaling, runtime modifications, GitOps-friendly

## 🚀 Quick Start Guide

### Prerequisites
```bash
# Install Omnistrate CLI
curl -fsSL https://raw.githubusercontent.com/omnistrate/scripts/main/install-ctl.sh | bash

# Authenticate with Omnistrate
omctl login --email YOUR_EMAIL --password YOUR_PASSWORD
```

### Deploy the Kubernetes-Managed Approach

1. **Clone the repository:**
```bash
git clone https://github.com/maziarkaveh/private-link-example.git
cd private-link-example
```

2. **Configure GitHub authentication** (for Git-based configurations):
```bash
# Set up environment variable for production use
export GITHUB_TOKEN="your_github_personal_access_token"

# Or update the service plan to use your token
```

3. **Deploy using Omnistrate CLI:**
```bash
omctl build --spec-type ServicePlanSpec \
  --file privatePostgresql.yaml \
  --name "Private PostgreSQL K8s-Managed" \
  --description "PostgreSQL with Kubernetes-managed NLB and Private Link endpoints"
```

### Key Components Deployed

#### 1. PostgreSQL Database Service
- **Container**: PostgreSQL with persistent storage
- **Resources**: Configurable CPU/Memory (t3.micro to t3.medium)
- **Storage**: 20GB-1TB persistent volumes
- **Networking**: Private subnet deployment

#### 2. Kubernetes-Managed Network Load Balancer
- **Controller**: AWS Load Balancer Controller
- **Type**: Network Load Balancer (Layer 4)
- **Target**: TargetGroupBinding for Pod-level routing
- **Annotations**: Optimized for Private Link connectivity

#### 3. VPC Endpoint Service Integration
- **Discovery**: Terraform module for VPC endpoint service discovery
- **Configuration**: Automatic Private Link endpoint configuration
- **Security**: Security group automation via Kubernetes annotations

## 🔧 Configuration Details

### Service Plan Schema (ServicePlanSpec)

The main service plan (`privatePostgresql.yaml`) uses the **ServicePlanSpec** format with:

- **Multi-Cloud Support**: AWS and GCP regions
- **Git Integration**: References to this repository for infrastructure code
- **Terraform Integration**: VPC endpoint discovery and networking setup
- **Kustomize Integration**: Kubernetes resource customization
- **Security**: Environment variable-based token authentication

### Key Configuration Sections

#### Infrastructure Capabilities
```yaml
serviceModel:
  infrastructureCapabilities:
    terraform:
      aws:
        terraformPath: /terraform
        gitConfiguration:
          reference: refs/heads/main
          repositoryUrl: https://github.com/maziarkaveh/private-link-example.git
          accessToken: '${{ secrets.GITHUB_TOKEN }}'
```

#### Kubernetes Deployment
```yaml
deployment:
  kubernetes:
    kubernetesType: KUBERNETES_TYPE_EKS
  kustomizeConfiguration:
    kustomizePath: /kustomize
    gitConfiguration:
      reference: refs/heads/main
      repositoryUrl: https://github.com/maziarkaveh/private-link-example.git
      accessToken: '${{ secrets.GITHUB_TOKEN }}'
```

#### Resource Instances
```yaml
resourceInstances:
  - name: database
    networkingType: PRIVATE
    networkingAttributes:
      subnetScope: PRIVATE
      dnsName: database
      clusterEndpoint: true
      endpointPorts:
        - port: 5432
          protocol: TCP
```

## � Security Considerations

### Authentication & Authorization
- **GitHub Token**: Repository access for infrastructure code
- **IAM Roles**: AWS service-linked roles for Load Balancer Controller
- **RBAC**: Kubernetes role-based access control for resources

### Network Security
- **Private Subnets**: Database deployed in private network segments
- **Security Groups**: Automatic configuration via Kubernetes annotations
- **TLS**: Encrypted communication via Private Link endpoints

### Best Practices
- Use environment variables for sensitive configuration
- Implement least-privilege IAM policies
- Regular security audits and updates
- Monitor Private Link endpoint usage

## 📊 Performance & Monitoring

### Built-in Observability
- **Metrics**: Prometheus integration for database and network metrics
- **Logging**: Centralized logging for troubleshooting
- **Alerting**: Configurable alerts for service health
- **Dashboards**: Grafana dashboards for visualization

### Performance Optimization
- **Resource Scaling**: Dynamic CPU/Memory scaling
- **Storage Optimization**: GP2/GP3 volume types with configurable IOPS
- **Network Optimization**: NLB cross-zone load balancing
- **Connection Pooling**: PostgreSQL connection pooling configuration

## 🛠️ Troubleshooting

### Common Issues

#### 1. Git Authentication Failures
```bash
# Verify GitHub token permissions
curl -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user

# Check repository access
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/maziarkaveh/private-link-example
```

#### 2. VPC Endpoint Service Discovery
```bash
# Check Terraform module execution
kubectl logs -n omnistrate-system -l app=terraform-runner

# Verify VPC endpoint service
aws ec2 describe-vpc-endpoint-services --service-names com.amazonaws.vpce.region.vpce-svc-xxxxx
```

#### 3. Load Balancer Controller Issues
```bash
# Check AWS Load Balancer Controller logs
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

# Verify TargetGroupBinding status
kubectl get targetgroupbindings -o yaml
```

### Debug Commands
```bash
# Service plan validation
omctl build --spec-type ServicePlanSpec --file privatePostgresql.yaml --dry-run

# Check service status
kubectl get services,pods,targetgroupbindings -o wide

# Network connectivity testing
kubectl exec -it postgresql-pod -- psql -h database -U postgres -d mydb
```

## 🔄 Deployment Workflow

### Development Process
1. **Local Development**: Test changes locally with kind/minikube
2. **Git Integration**: Push changes to GitHub repository
3. **CI/CD Pipeline**: Automated testing and validation
4. **Staging Deployment**: Deploy to staging environment
5. **Production Deployment**: Promote to production with monitoring

### Version Management
- **Git Tags**: Semantic versioning for releases
- **Service Plans**: Version-controlled service plan configurations
- **Infrastructure**: Terraform state management
- **Applications**: Container image versioning

## � Scaling & High Availability

### Horizontal Scaling
- **Database Replicas**: Read replicas for enhanced performance
- **Multi-AZ Deployment**: Cross-availability zone distribution
- **Load Balancing**: NLB with multiple targets for resilience

### Vertical Scaling
- **Instance Types**: Dynamic instance type modification
- **Storage Scaling**: Online storage expansion capabilities
- **Resource Limits**: Kubernetes resource quotas and limits

## 🌐 Multi-Cloud Considerations

### AWS Implementation
- **EKS**: Managed Kubernetes service
- **VPC**: Virtual Private Cloud networking
- **Private Link**: AWS PrivateLink for secure connectivity
- **IAM**: Identity and Access Management integration

### GCP Implementation
- **GKE**: Google Kubernetes Engine
- **VPC**: Virtual Private Cloud
- **Private Service Connect**: GCP equivalent to AWS Private Link
- **IAM**: Google Cloud IAM integration

## 📝 Contributing

### Development Setup
```bash
# Clone the repository
git clone https://github.com/maziarkaveh/private-link-example.git

# Install development dependencies
make install-deps

# Run tests
make test

# Build and validate
make build validate
```

### Code Standards
- **YAML**: Consistent indentation and structure
- **Terraform**: HCL formatting and validation
- **Documentation**: Comprehensive README and inline comments
- **Testing**: Unit tests for Terraform modules

## 📚 Additional Resources

### Documentation Links
- [Omnistrate Platform Documentation](https://docs.omnistrate.com)
- [AWS Private Link Documentation](https://docs.aws.amazon.com/vpc/latest/privatelink/)
- [Kubernetes TargetGroupBinding](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.4/guide/targetgroupbinding/targetgroupbinding/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

### Video Tutorials
- [AWS Setup Guide](https://youtu.be/Mu-4jppldwk)
- [GCP Setup Guide](https://youtu.be/7A9WbZjuXgQ)
- [Terraform Guide](https://youtu.be/eKktc4QKgaA)

### Support Channels
- [GitHub Issues](https://github.com/maziarkaveh/private-link-example/issues)
- [Omnistrate Community](https://community.omnistrate.com)
- [Documentation Portal](https://docs.omnistrate.com)

---

## � Success Summary

This package demonstrates a complete, production-ready implementation of PostgreSQL with Private Link connectivity using both traditional Terraform-managed and modern Kubernetes-managed approaches. The **Kubernetes-managed approach has been successfully validated** through the Omnistrate CLI and is ready for production deployment.

**Key Achievements:**
- ✅ **Complete Documentation Suite**: Comprehensive guides and examples
- ✅ **CLI Validation**: Successfully built with `omctl build`
- ✅ **Multi-Cloud Support**: AWS and GCP implementations
- ✅ **Security Best Practices**: Environment variables and proper authentication
- ✅ **Production Ready**: Monitoring, scaling, and troubleshooting guides

The repository serves as both a reference implementation and a starting point for building Private Link-enabled services on the Omnistrate platform.
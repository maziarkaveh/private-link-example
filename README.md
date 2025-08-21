# Private Link PostgreSQL Example

A comprehensive example demonstrating how to build a secure PostgreSQL SaaS using AWS VPC Endpoint Services (Private Link) with the Omnistrate platform.

## 🚀 Quick Start

1. **Onboard your AWS account** on [omnistrate.cloud](https://omnistrate.cloud) to host your SaaS offering
2. **Replace `<service-provider-account-id>`** in `privatePostgresql.yaml` with your AWS account ID
3. **Download the Omnistrate CLI** from [ctl.omnistrate.cloud](https://ctl.omnistrate.cloud/install/)
4. **Set email account** in `.env.template` and rename to `.env`
5. **Create `.omnistrate.password`** file with your Omnistrate account password
6. **Run `make build`** to deploy your private PostgreSQL service

## 📚 Complete Documentation

For comprehensive documentation, see the [**docs/**](docs/) directory:

- [**📖 Complete Guide & Overview**](docs/index.md) - Start here for full understanding
- [**⚙️ Installation Instructions**](docs/installation.md) - Step-by-step deployment guide
- [**🔧 Configuration Reference**](docs/configuration.md) - All parameters and options
- [**🏗️ Architecture Deep Dive**](docs/architecture.md) - Technical architecture details
- [**🔒 Security Guidelines**](docs/security.md) - Security best practices
- [**🛠️ Troubleshooting Guide**](docs/troubleshooting.md) - Common issues and solutions

## 🔗 Key Features

- **🔐 Private Connectivity**: Secure VPC-to-VPC connections via AWS Private Link
- **⚡ High Performance**: Network Load Balancer with health-checked targets
- **🛡️ Enterprise Security**: Zero internet exposure, encrypted connections
- **📊 Multi-Cloud Ready**: AWS implementation with GCP template included
- **🎛️ Automated Infrastructure**: Complete IaC using Terraform and Kubernetes
- **📈 Scalable Architecture**: Load balancing and auto-scaling capabilities

## 🏗️ What This Example Demonstrates

This example showcases **two different approaches** for implementing AWS Private Link:

### 🔧 Terraform-Managed Approach (main branch)

- **AWS VPC Endpoint Services** for private network connectivity
- **Network Load Balancer** configuration managed by Terraform
- **Kubernetes Target Group Binding** for automatic service discovery
- **PostgreSQL deployment** using Bitnami Helm charts
- **Security group configuration** for network access control
- **Multi-service orchestration** with parameter dependencies

### ☸️ Kubernetes-Managed Approach (k8s-managed-nlb-approach branch)

- **AWS Load Balancer Controller** creates NLB automatically
- **Service annotations** for Private Link configuration
- **Tag-based discovery** for Terraform resource identification
- **Simplified Helm charts** with NLB annotations
- **Deterministic tagging** for infrastructure coordination

## 🔀 Choosing an Approach

**Use Terraform-managed** when you need:

- Full control over NLB configuration
- Complex networking setups
- Custom target group settings

**Use Kubernetes-managed** when you prefer:

- Simplified Helm charts
- Automatic NLB creation
- Standard Service-based networking

## 📋 Prerequisites

- [Omnistrate account](https://omnistrate.cloud) (sign up free)
- AWS account with administrative access
- [Omnistrate CLI](https://ctl.omnistrate.cloud/install/) installed
- Basic familiarity with AWS VPC concepts

## 🌐 Blog Post

**Learn More**: [Building Private Database Services with AWS Private Link](https://blog.omnistrate.com/posts/115)

## 🆘 Need Help?

- 📖 **Full Documentation**: [docs/](docs/) directory contains comprehensive guides
- 🛠️ **Issues?** Check the [troubleshooting guide](docs/troubleshooting.md)
- 💬 **Support**: Contact through [Omnistrate platform](https://omnistrate.cloud)
- 📚 **Platform Docs**: [docs.omnistrate.cloud](https://docs.omnistrate.cloud)

---

**🎯 Ready to build your own private database service?** Start with the [complete documentation](docs/) or jump directly to [installation instructions](docs/installation.md)!# Build validation

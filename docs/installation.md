# Installation Guide

This guide provides step-by-step instructions for setting up and deploying the Private Link PostgreSQL example.

## Prerequisites

Before you begin, ensure you have the following:

### Required Accounts and Access

1. **Omnistrate Account**
   - Sign up at [omnistrate.cloud](https://omnistrate.cloud)
   - Verify your email address
   - Note your login credentials

2. **AWS Service Provider Account**
   - AWS account where your service will be hosted
   - Administrative access to create IAM roles
   - Access to create VPC resources

3. **AWS Customer Account** (for testing)
   - Separate AWS account to test private connectivity
   - Ability to create VPC endpoints

### Required Tools

1. **Omnistrate CLI**
   - Download from [ctl.omnistrate.cloud](https://ctl.omnistrate.cloud/install/)
   - Or install via Homebrew: `brew install omnistrate/tap/omnistrate-ctl`

2. **Git**
   - Required to clone the example repository
   - Available at [git-scm.com](https://git-scm.com)

3. **Text Editor**
   - Any text editor to modify configuration files
   - VS Code, vim, nano, etc.

## Step 1: Environment Setup

### Clone the Repository

```bash
git clone https://github.com/omnistrate-community/private-link-example.git
cd private-link-example
```

### Configure Environment Variables

1. **Create Environment File**:
   ```bash
   cp .env.template .env
   ```

2. **Edit the .env File**:
   ```bash
   # Edit .env file with your preferred editor
   nano .env
   ```

   Update the file with your Omnistrate email:
   ```bash
   OMNISTRATE_EMAIL=your-email@example.com
   ```

### Set Up Password File

1. **Create Password File**:
   ```bash
   cp .omnistrate.password.template .omnistrate.password
   ```

2. **Add Your Password**:
   ```bash
   # Edit the password file
   nano .omnistrate.password
   ```

   Replace the template content with your actual Omnistrate password:
   ```plaintext
   your-omnistrate-password
   ```

!!! warning "Security Note"
    The `.omnistrate.password` file contains sensitive information. It's included in `.gitignore` to prevent accidental commits.

## Step 2: AWS Account Configuration

### Get Your AWS Account ID

Find your AWS account ID using one of these methods:

1. **AWS Console**: Available in the top-right corner of the AWS console
2. **AWS CLI**: Run `aws sts get-caller-identity --query Account --output text`
3. **IAM Console**: Listed under "Account details"

### Update Service Configuration

Edit the `privatePostgresql.yaml` file to include your AWS account ID:

```bash
# Replace <service-provider-account-id> with your actual AWS account ID
sed -i 's/<service-provider-account-id>/123456789012/g' privatePostgresql.yaml
```

Or manually edit the file and replace all occurrences of `<service-provider-account-id>` with your AWS account ID.

## Step 3: Omnistrate CLI Setup

### Install CLI (if not already installed)

**Using Homebrew (macOS/Linux)**:
```bash
brew install omnistrate/tap/omnistrate-ctl
```

**Manual Installation**:
```bash
# Download the CLI from https://ctl.omnistrate.cloud/install/
# Follow the installation instructions for your platform
```

### Login to Omnistrate

```bash
make login
```

This command will:
- Read your email from `.env`
- Read your password from `.omnistrate.password`
- Authenticate with the Omnistrate platform

### Verify Login

```bash
omnistrate-ctl auth whoami
```

This should display your logged-in user information.

## Step 4: AWS Prerequisites Setup

Before deploying, ensure your AWS account has the required IAM roles:

### Bootstrap Role

The Omnistrate platform requires a bootstrap role in your AWS account:

1. **Role Name**: `omnistrate-bootstrap-role`
2. **Trust Policy**: Allows Omnistrate to assume the role
3. **Permissions**: Ability to create and manage AWS resources

### Terraform Execution Role

For Terraform-based infrastructure:

1. **Role Name**: `omnistrate-custom-terraform-execution-role`
2. **Permissions**: Ability to create VPCs, load balancers, and VPC endpoint services

!!! note "Role Setup"
    Detailed IAM role setup instructions are available in the [Omnistrate documentation](https://docs.omnistrate.cloud).

## Step 5: Build and Deploy

### Build the Service Plan

```bash
make build
```

This command will:
- Validate the `privatePostgresql.yaml` configuration
- Upload the service plan to Omnistrate
- Create the service plan with the name "Private Postgres"
- Set it as the preferred release

### Verify Deployment

1. **Check Build Status**:
   ```bash
   omnistrate-ctl get service-plans
   ```

2. **View Service Plan Details**:
   ```bash
   omnistrate-ctl describe service-plan "Private Postgres"
   ```

## Step 6: Testing the Deployment

### Create a Service Instance

Through the Omnistrate UI or CLI:

1. Navigate to your service plan
2. Create a new instance
3. Provide required parameters:
   - `connectAccountID`: Customer AWS account ID for testing
   - `instanceType`: EC2 instance type (default: t4g.small)
   - `username`: PostgreSQL username (optional)

### Monitor Deployment

Track the deployment progress:

```bash
omnistrate-ctl get instances --service-plan "Private Postgres"
```

## Step 7: Network Connectivity Testing

### From Customer Account

Once the instance is running, test private connectivity from your customer AWS account:

1. **Get VPC Endpoint Service Name**:
   - Available in instance details in Omnistrate UI
   - Or via CLI: `omnistrate-ctl describe instance <instance-id>`

2. **Create VPC Endpoint**:
   ```bash
   aws ec2 create-vpc-endpoint \
     --vpc-id vpc-customer-123 \
     --service-name com.amazonaws.vpce.us-east-1.vpce-svc-xyz \
     --vpc-endpoint-type Interface \
     --subnet-ids subnet-abc123
   ```

3. **Test Database Connection**:
   ```bash
   psql -h vpce-xyz.us-east-1.vpce.amazonaws.com -p 5432 -U username -d postgres
   ```

## Troubleshooting Installation

### Common Issues

1. **Authentication Failed**
   - Verify credentials in `.env` and `.omnistrate.password`
   - Check for extra spaces or newlines in password file

2. **AWS Account ID Not Found**
   - Ensure AWS account ID is correctly replaced in `privatePostgresql.yaml`
   - Use 12-digit AWS account ID without hyphens

3. **Service Plan Build Failed**
   - Check YAML syntax in `privatePostgresql.yaml`
   - Verify all required fields are properly filled

4. **CLI Not Found**
   - Ensure Omnistrate CLI is properly installed
   - Add CLI to PATH if installed manually

### Getting Help

- Check the [troubleshooting section](index.md#troubleshooting) in the main documentation
- Review [Omnistrate documentation](https://docs.omnistrate.cloud)
- Contact support through the Omnistrate platform

## Next Steps

After successful installation:

1. [Configure advanced settings](configuration.md)
2. [Set up monitoring](monitoring.md)
3. [Implement security best practices](security.md)
4. [Scale your deployment](scaling.md)

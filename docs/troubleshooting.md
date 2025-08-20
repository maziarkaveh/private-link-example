# Troubleshooting Guide

This guide helps you diagnose and resolve common issues with the Private Link PostgreSQL example.

## Common Issues and Solutions

### 1. Authentication and Access Issues

#### CLI Authentication Failed

**Symptoms:**
- Unable to login with `make login`
- "Invalid credentials" error messages
- Authentication timeout errors

**Causes and Solutions:**

**Incorrect Email Format:**

```bash
# Check .env file format
cat .env
# Should contain: OMNISTRATE_EMAIL=your-email@example.com
```

**Password File Issues:**

```bash
# Check password file exists and has content
ls -la .omnistrate.password
cat .omnistrate.password
# File should contain only your password, no extra spaces or newlines
```

**Solution Steps:**
1. Verify email in `.env` file is correct
2. Ensure password file contains only the password
3. Check for hidden characters: `hexdump -C .omnistrate.password`
4. Recreate password file if needed:
   ```bash
   echo -n "your-password" > .omnistrate.password
   ```

#### AWS Account Access Issues

**Symptoms:**
- Service plan build fails with IAM errors
- "Access denied" when creating infrastructure
- Terraform execution failures

**Required IAM Roles:**

Check these roles exist in your AWS account:

```bash
# Check bootstrap role
aws iam get-role --role-name omnistrate-bootstrap-role

# Check terraform execution role
aws iam get-role --role-name omnistrate-custom-terraform-execution-role
```

**Solution:**
1. Create required IAM roles following [Omnistrate documentation](https://docs.omnistrate.cloud)
2. Verify trust relationships are configured correctly
3. Ensure roles have necessary permissions

### 2. Service Plan Build Issues

#### YAML Validation Errors

**Symptoms:**
- Build command fails immediately
- YAML parsing error messages
- Invalid configuration warnings

**Common YAML Issues:**

**Indentation Problems:**

```yaml
# Incorrect (mixed spaces and tabs)
services:
	- name: terraform
  internal: true

# Correct (consistent spaces)
services:
  - name: terraform
    internal: true
```

**Missing Required Fields:**

```bash
# Validate YAML syntax
yamllint privatePostgresql.yaml

# Check for required fields
grep -n "service-provider-account-id" privatePostgresql.yaml
```

**Solution Steps:**
1. Use consistent indentation (2 spaces recommended)
2. Replace all placeholders with actual values
3. Validate YAML syntax before building

#### AWS Account ID Configuration

**Symptoms:**
- Build succeeds but deployment fails
- Infrastructure creation errors
- Invalid account ID messages

**Check Account ID Replacement:**

```bash
# Search for unreplaced placeholders
grep -n "service-provider-account-id" privatePostgresql.yaml

# Should return no results if properly replaced
```

**Get Your AWS Account ID:**

```bash
# Using AWS CLI
aws sts get-caller-identity --query Account --output text

# Or check AWS Console (top-right corner)
```

**Solution:**
```bash
# Replace with your actual account ID
sed -i 's/<service-provider-account-id>/123456789012/g' privatePostgresql.yaml
```

### 3. Deployment and Infrastructure Issues

#### Network Load Balancer Creation Fails

**Symptoms:**
- Terraform apply fails on NLB resource
- Subnet or security group errors
- VPC configuration issues

**Diagnostic Steps:**

```bash
# Check VPC and subnet configuration
aws ec2 describe-vpcs --filters "Name=is-default,Values=true"
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-xxxxx"
```

**Common Causes:**
1. **Insufficient Subnets**: NLB requires multiple AZs
2. **Security Group Limits**: Too many security groups attached
3. **Resource Limits**: AWS service limits exceeded

**Solutions:**
1. Ensure VPC has subnets in at least 2 AZs
2. Check AWS service limits and request increases if needed
3. Verify security group rules allow required traffic

#### Target Group Health Check Failures

**Symptoms:**
- PostgreSQL pods start but show unhealthy
- Connection timeouts from load balancer
- Health check failures in AWS console

**Diagnostic Commands:**

```bash
# Check pod status
kubectl get pods -n <namespace>
kubectl describe pod <postgresql-pod-name> -n <namespace>

# Check service endpoints
kubectl get endpoints -n <namespace>
kubectl describe service helm-postgresql -n <namespace>

# Check target group binding
kubectl get targetgroupbindings -n <namespace>
kubectl describe targetgroupbinding postgres-targetgroup-binding -n <namespace>
```

**Common Causes:**
1. **PostgreSQL Not Ready**: Database still starting up
2. **Network Policies**: Kubernetes network policies blocking traffic
3. **Resource Constraints**: Insufficient CPU/memory
4. **Port Configuration**: Mismatched port numbers

**Solutions:**
1. Wait for PostgreSQL to fully initialize (can take 2-3 minutes)
2. Check resource limits and increase if necessary
3. Verify port configuration matches across all components
4. Check network policies allow traffic from load balancer

### 4. Connectivity Issues

#### VPC Endpoint Creation Fails

**Symptoms:**
- Customer cannot create VPC endpoints
- "Service not found" errors
- Permission denied when creating endpoints

**Diagnostic Steps:**

```bash
# Check VPC endpoint service status
aws ec2 describe-vpc-endpoint-services --service-names com.amazonaws.vpce.region.vpce-svc-xxxxx

# Verify service configuration
aws ec2 describe-vpc-endpoint-service-configurations
```

**Common Issues:**
1. **Service Not Available**: VPC endpoint service not properly created
2. **Wrong Region**: Service created in different region than customer
3. **Principal Not Allowed**: Customer account not in allowed principals

**Solutions:**
1. Verify VPC endpoint service is created and available
2. Ensure customer and service are in same region
3. Check `connectAccountID` parameter matches customer account

#### Database Connection Timeouts

**Symptoms:**
- VPC endpoint created but cannot connect to database
- Connection timeouts or refused connections
- DNS resolution issues

**Diagnostic Steps:**

```bash
# Test DNS resolution from customer VPC
nslookup vpce-xxxxx.us-east-1.vpce.amazonaws.com

# Test TCP connectivity
telnet vpce-xxxxx.us-east-1.vpce.amazonaws.com 5432

# Check PostgreSQL logs
kubectl logs <postgresql-pod-name> -n <namespace>
```

**Common Causes:**
1. **Security Group Rules**: Blocking traffic on port 5432
2. **PostgreSQL Configuration**: Not accepting connections
3. **DNS Propagation**: DNS changes not yet propagated
4. **Network ACLs**: Subnet-level blocking

**Solutions:**
1. Verify security groups allow port 5432 from customer subnets
2. Check PostgreSQL configuration allows remote connections
3. Wait for DNS propagation (up to 5 minutes)
4. Review network ACLs on customer subnets

### 5. Performance Issues

#### Slow Database Connections

**Symptoms:**
- High connection establishment times
- Slow query performance
- Intermittent timeouts

**Diagnostic Commands:**

```bash
# Check pod resource usage
kubectl top pod <postgresql-pod-name> -n <namespace>

# Check load balancer metrics in AWS console
# Monitor target response times

# Check PostgreSQL performance
psql -h <endpoint> -c "SELECT * FROM pg_stat_activity;"
```

**Solutions:**
1. **Scale Resources**: Increase CPU/memory limits
2. **Optimize Queries**: Review slow query logs
3. **Connection Pooling**: Implement connection pooling
4. **Instance Type**: Use larger EC2 instance types

#### High Memory Usage

**Symptoms:**
- Pod restarts due to memory limits
- Out of memory errors in logs
- Performance degradation

**Diagnostic Steps:**

```bash
# Check memory usage
kubectl describe pod <postgresql-pod-name> -n <namespace>
kubectl top pod <postgresql-pod-name> -n <namespace>

# Check PostgreSQL memory settings
psql -h <endpoint> -c "SHOW shared_buffers; SHOW work_mem;"
```

**Solutions:**
1. Increase memory limits in Helm configuration
2. Optimize PostgreSQL memory settings
3. Use larger instance types
4. Implement memory monitoring and alerting

### 6. Security Issues

#### SSL/TLS Connection Issues

**Symptoms:**
- SSL connection errors
- Certificate validation failures
- Insecure connection warnings

**Diagnostic Steps:**

```bash
# Test SSL connection
psql "sslmode=require host=<endpoint> port=5432 user=<username> dbname=postgres"

# Check PostgreSQL SSL configuration
psql -h <endpoint> -c "SHOW ssl;"
```

**Solutions:**
1. Configure PostgreSQL SSL properly
2. Provide proper SSL certificates
3. Update client connection strings
4. Check firewall rules for SSL traffic

### 7. Monitoring and Alerting Issues

#### Missing Metrics

**Symptoms:**
- No metrics in monitoring dashboards
- Missing CloudWatch metrics
- Incomplete observability

**Check Metric Sources:**

```bash
# AWS CloudWatch metrics
aws cloudwatch list-metrics --namespace AWS/NetworkELB
aws cloudwatch list-metrics --namespace AWS/VpcEndpointService

# Kubernetes metrics
kubectl get --raw /metrics
```

**Solutions:**
1. Verify CloudWatch agent configuration
2. Check metric collection permissions
3. Ensure proper tagging on AWS resources
4. Configure application-level metrics

## Debugging Commands Reference

### AWS CLI Commands

```bash
# VPC Endpoint Service
aws ec2 describe-vpc-endpoint-services
aws ec2 describe-vpc-endpoint-service-configurations

# Load Balancer
aws elbv2 describe-load-balancers
aws elbv2 describe-target-groups
aws elbv2 describe-target-health --target-group-arn <arn>

# Security Groups
aws ec2 describe-security-groups --group-ids <sg-id>
```

### Kubernetes Commands

```bash
# Pods and Services
kubectl get pods,services,endpoints -n <namespace>
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace> --follow

# Target Group Bindings
kubectl get targetgroupbindings -n <namespace>
kubectl describe targetgroupbinding <name> -n <namespace>

# Events
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
```

### PostgreSQL Commands

```bash
# Connection testing
psql -h <endpoint> -p 5432 -U <username> -d postgres -c "SELECT version();"

# Performance monitoring
psql -h <endpoint> -c "SELECT * FROM pg_stat_activity;"
psql -h <endpoint> -c "SELECT * FROM pg_stat_database;"
```

## Getting Help

### Log Collection

Before contacting support, collect these logs:

1. **Omnistrate CLI Logs:**
   ```bash
   omnistrate-ctl build -f privatePostgresql.yaml --debug
   ```

2. **Kubernetes Logs:**
   ```bash
   kubectl logs <postgresql-pod> -n <namespace> > postgresql.log
   kubectl get events -n <namespace> > events.log
   ```

3. **AWS CloudWatch Logs:**
   - VPC Flow Logs
   - Load Balancer Access Logs
   - CloudTrail Events

### Support Channels

1. **Documentation**: [docs.omnistrate.cloud](https://docs.omnistrate.cloud)
2. **Community**: Check GitHub issues and discussions
3. **Support**: Contact through Omnistrate platform
4. **Professional Services**: Available for complex deployments

### Escalation Process

For critical issues:

1. **Gather Evidence**: Collect logs and error messages
2. **Document Steps**: List reproduction steps
3. **Check Status**: Verify service status pages
4. **Contact Support**: Provide detailed information
5. **Follow Up**: Monitor ticket progress

This troubleshooting guide should help resolve most common issues. For complex problems or when multiple issues occur together, consider engaging professional support services.

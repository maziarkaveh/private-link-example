# Kubernetes-Managed Private Link Example

This example demonstrates a Private Link implementation where:
- **NLB is created by Kubernetes** (AWS Load Balancer Controller) with Service annotations
- **Security Groups are managed by Kubernetes** based on tags and annotations
- **Terraform only discovers existing resources** using deterministic tags
- **VPC Endpoint Service creation** is handled by Terraform using the discovered NLB

## Architecture Pattern

```text
[Kubernetes Service] → [AWS Load Balancer Controller] → [NLB + SG Creation]
         ↓
[Terraform discovers NLB via tags] → [Creates VPC Endpoint Service]
```

## Key Differences from Traditional Approach

| Component | Traditional Approach | K8s-Managed Approach |
|-----------|---------------------|---------------------|
| NLB Creation | Terraform creates NLB | K8s Service with annotations creates NLB |
| Security Groups | Terraform creates SG rules | K8s manages SG via controller |
| Service Discovery | Direct resource creation | Tag-based discovery |
| Target Group Binding | Separate TGB resource | Automatic via Service |

## Project Structure

```
k8s-managed-private-link-example/
├── README.md
├── service-plan.yaml
├── helm/
│   └── postgres-k8s-nlb/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│           ├── service.yaml
│           ├── deployment.yaml
│           └── configmap.yaml
└── terraform/
    └── vpc-endpoint-discovery/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## Benefits

1. **Kubernetes-Native**: NLB lifecycle managed by K8s controllers
2. **Automatic Target Management**: No manual Target Group Binding needed
3. **Simplified Infrastructure**: Terraform focuses only on VPC Endpoint Service
4. **Tag-Based Discovery**: Deterministic resource identification
5. **Controller-Managed Security**: AWS Load Balancer Controller handles security groups

## Use Cases

- Applications that prefer Kubernetes-native load balancing
- Environments with strict Kubernetes resource management policies  
- Services that need automatic target registration/deregistration
- Teams that want to minimize Terraform infrastructure management

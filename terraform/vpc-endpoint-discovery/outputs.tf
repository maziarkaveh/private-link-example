output "vpc_endpoint_service_name" {
  description = "The service name of the VPC endpoint service"
  value       = aws_vpc_endpoint_service.postgres_vpce_service.service_name
}

output "vpc_endpoint_service_dns_name" {
  description = "The DNS name of the VPC endpoint service"
  value       = aws_vpc_endpoint_service.postgres_vpce_service.service_name
}

output "vpc_endpoint_service_id" {
  description = "The ID of the VPC endpoint service"
  value       = aws_vpc_endpoint_service.postgres_vpce_service.id
}

output "nlb_dns_name" {
  description = "The DNS name of the discovered Kubernetes-created NLB"
  value       = data.aws_lb.k8s_created_nlb.dns_name
}

output "nlb_arn" {
  description = "The ARN of the discovered Kubernetes-created NLB"
  value       = data.aws_lb.k8s_created_nlb.arn
}

output "nlb_zone_id" {
  description = "The hosted zone ID of the discovered NLB"
  value       = data.aws_lb.k8s_created_nlb.zone_id
}

output "allowed_account_ids" {
  description = "The account IDs allowed to connect to the VPC endpoint service"
  value       = local.connectAccountIDs
}

output "k8s_service_tags" {
  description = "Tags used to discover the Kubernetes-created NLB"
  value = {
    "omnistrate-instance"   = local.instance_id
    "omnistrate-service"    = "postgres-nlb"
    "service.k8s.aws/stack" = "${local.instance_id}/postgres-nlb"
    "elbv2.k8s.aws/cluster" = "{{ $sys.deployment.kubernetesClusterID }}"
  }
}

variable "serviceName" {
  description = "Name of the Kubernetes service that created the NLB"
  type        = string
  default     = "postgres-k8s-nlb"
}

variable "connectAccountID" {
  description = "Comma-separated AWS account IDs for VPC endpoint access"
  type        = string
  default     = ""
}

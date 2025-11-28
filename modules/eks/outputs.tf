# ============================================================================
# EKS MODULE - modules/eks/outputs.tf
# ============================================================================

output "cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.main.id
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_version" {
  description = "EKS cluster version"
  value       = aws_eks_cluster.main.version
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = aws_eks_cluster.main.arn
}

# Fix these three outputs to handle count
output "node_group_id" {
  description = "EKS node group IDs"
  value       = aws_eks_node_group.main[*].id
}

output "node_group_arn" {
  description = "ARN of the EKS node groups"
  value       = aws_eks_node_group.main[*].arn
}

output "node_group_status" {
  description = "Status of the EKS node groups"
  value       = aws_eks_node_group.main[*].status
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider for EKS"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

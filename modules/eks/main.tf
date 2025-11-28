# ============================================================================
# EKS MODULE - modules/eks/main.tf
# ============================================================================

# KMS key for EKS encryption
resource "aws_kms_key" "eks" {
  count                   = var.enable_cluster_encryption ? 1 : 0
  description             = "KMS key for EKS cluster encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-eks-kms"
    }
  )
}

resource "aws_kms_alias" "eks" {
  count         = var.enable_cluster_encryption ? 1 : 0
  name          = "alias/${var.project_name}-${var.environment}-eks"
  target_key_id = aws_kms_key.eks[0].key_id
}

# CloudWatch Log Group for EKS
resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/${var.project_name}-${var.environment}-cluster/cluster"
  retention_in_days = 7

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-eks-logs"
    }
  )
}

# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = "${var.project_name}-${var.environment}-cluster"
  role_arn = var.cluster_role_arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = concat(var.private_subnet_ids, var.public_subnet_ids)
    endpoint_private_access = true
    endpoint_public_access  = true
    security_group_ids      = [var.cluster_security_group_id]
  }

  dynamic "encryption_config" {
    for_each = var.enable_cluster_encryption ? [1] : []
    content {
      provider {
        key_arn = aws_kms_key.eks[0].arn
      }
      resources = ["secrets"]
    }
  }

  enabled_cluster_log_types = var.cluster_log_types

  depends_on = [
    aws_cloudwatch_log_group.eks_cluster
  ]

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-cluster"
    }
  )
}

# EKS Node Groups - One per Availability Zone for HA
resource "aws_eks_node_group" "main" {
  count           = length(var.private_subnet_ids)
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-${var.environment}-node-group-${count.index + 1}"
  node_role_arn   = var.node_role_arn
  subnet_ids      = [var.private_subnet_ids[count.index]]
  version         = var.cluster_version

  scaling_config {
    desired_size = ceil(var.node_group_desired_size / length(var.private_subnet_ids))
    max_size     = ceil(var.node_group_max_size / length(var.private_subnet_ids))
    min_size     = ceil(var.node_group_min_size / length(var.private_subnet_ids))
  }

  update_config {
    max_unavailable = 1
  }

  instance_types = var.node_instance_types
  disk_size      = var.node_disk_size
  capacity_type  = "ON_DEMAND"

  labels = {
    role        = "worker"
    environment = var.environment
    az          = element(split("/", var.private_subnet_ids[count.index]), 1)
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-node-group-${count.index + 1}"
      "kubernetes.io/cluster/${var.project_name}-${var.environment}-cluster" = "owned"
    }
  )

  depends_on = [
    aws_eks_cluster.main
  ]

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [scaling_config[0].desired_size]
  }
}

# Create the EKS Cluster
resource "aws_eks_cluster" "eks_cluster" {
  name     = "${var.prefix}-eks-cluster"
  role_arn = aws_iam_role.eks_role.arn
  version  = "1.30"
  # Kubernetes version is 1.30 (as of 12 Sep 2024) 
  # Current Kubernetes version is 1.31 (11 Sep 2024)

  vpc_config {
    subnet_ids = aws_subnet.public_subnet[*].id
  }

  depends_on = [aws_iam_role_policy_attachment.eks_policy]
}

# output "eks_cluster_name" {
#   value = aws_eks_cluster.eks_cluster.name
# }

# output "eks_cluster_endpoint" {
#   value = aws_eks_cluster.eks_cluster.endpoint
# }

# output "eks_cluster_certificate_authority" {
#   value = aws_eks_cluster.eks_cluster.certificate_authority[0].data
# }

# Create Worker Nodes

resource "aws_eks_node_group" "worker_nodes" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "eks-worker-group"
  node_role_arn   = aws_iam_role.worker_node_role.arn
  subnet_ids      = aws_subnet.public_subnet[*].id

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  instance_types = ["t3.medium"]

  remote_access {
    ec2_ssh_key = aws_key_pair.main.key_name
  }

  tags = {
    Name = "eks-worker-nodes"
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_secret" "db_secrets" {
  metadata {
    name = "db-connection-secrets"
    namespace = "default"                                                                   
}

  data = {
    FQDN     = aws_instance.database.private_ip                            # FQDN for the host
    DB_NAME  = "postgres"                                                  # Database name
    DB_USER  = "postgres"                                                  # Database user
    DB_PASS  = aws_secretsmanager_secret_version.database.secret_string    # Database password
  }
}

resource "kubernetes_secret" "s3_secrets" {
  metadata {
    name = "s3-identity-secrets"
    namespace = "default"                                                                   
}

  data = {
    PREFIX   = var.prefix                     # To retreive the S3 bucket with assets
    POSTFIX  = random_id.secret_postfix.hex   # To retreive the S3 bucket with assets
  }
}


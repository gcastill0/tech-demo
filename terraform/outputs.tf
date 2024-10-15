output "ssh_access" {
  value = "ssh -i ${var.prefix}-ssh-key.pem ubuntu@${aws_instance.database.public_ip}"
}

output "terraform-mirror-url" {
  value = format("https://%s/", aws_s3_bucket.mirror.bucket_domain_name)
}

output "eks_cluster_name" {
  value = aws_eks_cluster.eks_cluster.name
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.eks_cluster.endpoint
}

output "eks_cluster_certificate_authority" {
  value = aws_eks_cluster.eks_cluster.certificate_authority[0].data
}

output "ec2_fddn" {
  value = aws_instance.database.private_dns
}
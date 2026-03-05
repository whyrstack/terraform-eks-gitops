output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_version" {
  description = "EKS cluster Kubernetes version"
  value       = module.eks.cluster_version
}

# Region
output "region" {
  description = "AWS region"
  value       = var.aws_region
}

# VPC Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnets
}

output "public_subnets_enabled" {
  description = "Whether public subnets are created"
  value       = local.enable_public_ng
}

# Node Group Outputs
output "node_group_ng1_status" {
  description = "Node group 1 configuration"
  value       = "NG1: ${var.ng1_desired_size} x ${var.ng1_node_instance_type} nodes in private subnet"
}

output "node_group_ng2_status" {
  description = "Node group 2 configuration"
  value       = local.enable_public_ng ? "NG2: ${var.ng2_desired_size} x ${var.ng2_node_instance_type} nodes in public subnet" : "NG2: Disabled (0 nodes)"
}

output "configure_kubectl_on_bastion" {
  description = "Commands to run on bastion to access the cluster"
  value       = <<-EOT
    # SSH to bastion
    ssh -i ~/.ssh/${var.ssh_key_name}.pem ec2-user@${aws_eip.bastion.public_ip}
    
    # On bastion, configure kubectl
    aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}
    
    # Verify access
    kubectl get nodes
  EOT
}
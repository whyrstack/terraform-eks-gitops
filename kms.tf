##########################################################################
# KMS
##########################################################################

resource "aws_kms_key" "eks" {
  description             = "KMS key for EKS cluster ${var.cluster_name} secrets encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  multi_region            = false

  tags = {
    Name        = "${var.cluster_name}-eks-key"
    AutoDelete  = "true"
    Environment = var.environment
  }
}

resource "aws_kms_alias" "eks" {
  name          = "alias/${var.cluster_name}-eks"
  target_key_id = aws_kms_key.eks.key_id
}

# KMS Policy for EKS from template
data "template_file" "kms_eks_policy" {
  template = file("${path.module}/templates/policies/kms-eks-policy.json.tpl")

  vars = {
    account_id   = data.aws_caller_identity.current.account_id
    region       = var.aws_region
    cluster_name = var.cluster_name
  }
}

resource "aws_kms_key_policy" "eks" {
  key_id = aws_kms_key.eks.id
  policy = data.template_file.kms_eks_policy.rendered
}
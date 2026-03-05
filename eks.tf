##########################################################################
# EKS
##########################################################################

locals {
  enable_public_ng = var.ng2_desired_size > 0
  nodegroups = merge(
    {
      ng1 = {
        name = "${var.cluster_name}-ng1"

        instance_types = [var.ng1_node_instance_type]
        capacity_type  = "ON_DEMAND"

        min_size     = var.ng1_min_size
        max_size     = var.ng1_max_size
        desired_size = var.ng1_desired_size

        subnet_ids = [module.vpc.private_subnets[0], module.vpc.private_subnets[1]]

        iam_role_use_name_prefix = false
        use_name_prefix          = false

        labels = {
          node-group = "ng-1"
          subnet     = "private"
        }

        iam_role_additional_policies = {
          AmazonEKSWorkerNodePolicy          = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
          AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
          CloudWatchAgentServerPolicy        = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
          AmazonSSMManagedInstanceCore       = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
        }

        block_device_mappings = {
          xvda = {
            device_name = "/dev/xvda"
            ebs = {
              volume_size           = 20
              volume_type           = "gp3"
              iops                  = 3000
              throughput            = 150
              encrypted             = true
              delete_on_termination = true
            }
          }
        }

        tags = {
          Name = "${var.cluster_name}-ng1"
        }
      }
    },
    local.enable_public_ng ? {
      ng2 = {
        name = "${var.cluster_name}-ng2"

        instance_types = [var.ng2_node_instance_type]
        capacity_type  = "ON_DEMAND"

        min_size     = var.ng2_min_size
        max_size     = var.ng2_max_size
        desired_size = var.ng2_desired_size

        subnet_ids = [module.vpc.public_subnets[0], module.vpc.public_subnets[1]]

        iam_role_use_name_prefix = false
        use_name_prefix          = false

        labels = {
          node-group = "ng-2"
          subnet     = "public"
        }

        iam_role_additional_policies = {
          AmazonEKSWorkerNodePolicy          = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
          AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
          CloudWatchAgentServerPolicy        = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
          AmazonSSMManagedInstanceCore       = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
        }

        block_device_mappings = {
          xvda = {
            device_name = "/dev/xvda"
            ebs = {
              volume_size           = 20
              volume_type           = "gp3"
              iops                  = 3000
              throughput            = 150
              encrypted             = true
              delete_on_termination = true
            }
          }
        }

        tags = {
          Name = "${var.cluster_name}-ng2"
        }
      }
    } : {}
  )
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.15"

  # Cluster configuration
  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  upgrade_policy = {
    support_type = "STANDARD"
  }

  # VPC and networking
  vpc_id     = module.vpc.vpc_id
  subnet_ids = !local.enable_public_ng ? module.vpc.private_subnets : concat(module.vpc.public_subnets, module.vpc.private_subnets)

  control_plane_subnet_ids = module.vpc.private_subnets

  # Cluster endpoint access
  endpoint_private_access      = true
  endpoint_public_access       = var.endpoint_public_access
  endpoint_public_access_cidrs = [var.your_ip]

  # Cluster encryption
  encryption_config = {
    provider_key_arn = aws_kms_key.eks.arn
    resources        = ["secrets"]
  }

  # Cluster logging
  enabled_log_types = [
    "api",
    "audit",
    "authenticator"
    # "controllerManager", 
    # "scheduler"
  ]
  create_cloudwatch_log_group = true
  #cloudwatch_log_group_kms_key_id        = aws_kms_key.eks.arn
  cloudwatch_log_group_retention_in_days = 7

  # EKS Addons
  addons = {

    vpc-cni = {
      most_recent    = true
      before_compute = true
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }

    eks-pod-identity-agent = {
      most_recent    = true
      before_compute = true
    }

    coredns = {
      most_recent = true
    }

    kube-proxy = {
      most_recent = true

    }

    aws-ebs-csi-driver = {
      most_recent = true
      configuration_values = jsonencode({
        controller = {
          replicaCount = min(var.ng1_desired_size + var.ng2_desired_size, 2)
        }
      })
    }

  }

  # IRSA (IAM Roles for Service Accounts) not used, using pod identity instead
  # enable_irsa              = false
  # openid_connect_audiences = ["sts.amazonaws.com"]

  access_entries = {
    bastion = {
      principal_arn = aws_iam_role.bastion.arn
      policy_associations = {
        cluster_admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  # Node Groups
  create_node_security_group                   = true
  node_security_group_name                     = "${var.cluster_name}-node-sg"
  node_security_group_use_name_prefix          = false
  node_security_group_enable_recommended_rules = true
  node_security_group_description              = "Security group for EKS worker nodes"
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all traffic"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }

    egress_all = {
      description      = "All outbound"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  node_security_group_tags = {
    Name = "${var.cluster_name}-node-sg"
  }

  eks_managed_node_groups = local.nodegroups

  # Authentication
  authentication_mode = "API_AND_CONFIG_MAP"

  # Access entries
  enable_cluster_creator_admin_permissions = true

  tags = {
    Environment = var.environment
  }
}

##########################################################################
# Pod Identity - VPC CNI
##########################################################################
module "vpc_cni_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.0"

  name = "${var.cluster_name}-vpc-cni"

  attach_aws_vpc_cni_policy = true
  aws_vpc_cni_enable_ipv4   = true

  associations = {
    this = {
      cluster_name    = module.eks.cluster_name
      namespace       = "kube-system"
      service_account = "aws-node"
    }
  }

  tags = {
    Environment = var.environment
  }
}

##########################################################################
# Pod Identity - EBS CSI Driver
##########################################################################
module "ebs_csi_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.0"

  name = "${var.cluster_name}-ebs-csi"

  attach_aws_ebs_csi_policy = true
  aws_ebs_csi_kms_arns      = [aws_kms_key.eks.arn]

  associations = {
    this = {
      cluster_name    = module.eks.cluster_name
      namespace       = "kube-system"
      service_account = "ebs-csi-controller-sa"
    }
  }

  tags = {
    Environment = var.environment
  }
}

##########################################################################
# Pod Identity - Custom policies are found in apps-flux.tf
##########################################################################
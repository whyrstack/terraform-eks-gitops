##########################################################################
# VPC
##########################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  public_subnets = [
    cidrsubnet(var.vpc_cidr, 8, 10),
    cidrsubnet(var.vpc_cidr, 8, 11)
  ]

  private_subnets = [
    cidrsubnet(var.vpc_cidr, 8, 0),
    cidrsubnet(var.vpc_cidr, 8, 1)
  ]

  enable_dns_hostnames = true
  enable_dns_support   = true

  # Only create NAT gateway if private subnets exist
  enable_nat_gateway = true
  single_nat_gateway = true

  map_public_ip_on_launch                        = true
  private_subnet_assign_ipv6_address_on_creation = false

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "Type"                                      = "private"
    "karpenter.sh/discovery"                    = var.cluster_name
  }

  public_subnet_tags = local.enable_public_ng ? {
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "Type"                                      = "public"
  } : {}

  tags = {
    Name        = "${var.cluster_name}-vpc"
    Environment = var.environment
  }
}
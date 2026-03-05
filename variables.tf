variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "aws_profile" {
  description = "AWS Profile"
  type        = string
  default     = "default"
}


variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "microservices-cluster"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "your_ip" {
  description = "Your IP address for EKS API access (CIDR format, e.g., 1.2.3.4/32)"
  type        = string
}

# Node Group 1 (Public Subnet)
variable "ng1_node_instance_type" {
  description = "EC2 instance type for EKS nodes nodegroup 1"
  type        = string
  default     = "t3.micro"
}

variable "ng1_min_size" {
  description = "Minimum size for node group 1"
  type        = number
  default     = 1
}

variable "ng1_max_size" {
  description = "Maximum size for node group 1"
  type        = number
  default     = 1
}

variable "ng1_desired_size" {
  description = "Desired size for node group 1"
  type        = number
  default     = 1
}

# Node Group 2 (Private Subnet)
variable "ng2_node_instance_type" {
  description = "EC2 instance type for EKS nodes nodegroup 2"
  type        = string
  default     = "t3.micro"
}

variable "ng2_min_size" {
  description = "Minimum size for node group 2 (set to 0 to disable)"
  type        = number
  default     = 1
}

variable "ng2_max_size" {
  description = "Maximum size for node group 2 (set to 0 to disable)"
  type        = number
  default     = 1
}

variable "ng2_desired_size" {
  description = "Desired size for node group 2 (set to 0 to disable)"
  type        = number
  default     = 1
}

variable "kubernetes_version" {
  description = "kubernetes engine version"
  type        = string
  default     = "1.32"
}

variable "ssh_key_name" {}

variable "bastion_instance_type" {
  description = "EC2 instance type for Bastion node"
  type        = string
  default     = "t3.micro"
}

variable "endpoint_public_access" {
  description = "Set endpoint_public_access to true if you want to run kubernetes and helm providers"
  type        = bool
  default     = false
}

variable "flux_apps" {
  description = "List of apps to deploy via Flux"
  type = list(object({
    app_name           = string
    create_namespace   = optional(bool, true)
    app_namespace      = string
    service_account    = optional(string, "")
    app_github_project = string
    app_github_token   = string
    chart_path         = optional(string, "charts")
  }))
}

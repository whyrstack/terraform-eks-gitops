variable "cluster_name" {
  type = string
}

variable "app_name" {
  type = string
}

variable "namespace" {
  type = string
}

variable "service_account" {
  type = string
  default = ""
}

variable "github_project" {
  type = string
}

variable "github_token" {
  type      = string
  sensitive = true
}

variable "chart_path" {
  type    = string
  default = "charts"
}

variable "node_group" {
  type    = string
  default = ""
}

variable "create_namespace" {
  type    = bool
  default = true
}

variable "policy_statements" {
  type    = any
  default = []
}

variable "environment" {
  type = string
}
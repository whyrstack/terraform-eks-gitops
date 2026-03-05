resource "kubernetes_namespace_v1" "this" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name = var.namespace
  }
}

resource "kubernetes_service_account_v1" "this" {
  count = var.service_account != "" ? 1 : 0
  depends_on = [kubernetes_namespace_v1.this]

  metadata {
    name      = var.service_account
    namespace = var.namespace
  }
}

resource "kubernetes_secret_v1" "git" {
  metadata {
    name      = "${var.app_name}-git-credentials"
    namespace = "flux-system"
  }

  data = {
    username = "git"
    password = var.github_token
  }
}

resource "kubernetes_manifest" "git_repo" {
  depends_on = [kubernetes_secret_v1.git]

  manifest = {
    apiVersion = "source.toolkit.fluxcd.io/v1"
    kind       = "GitRepository"
    metadata = {
      name      = var.app_name
      namespace = "flux-system"
    }
    spec = {
      interval = "1m"
      url      = "https://github.com/${var.github_project}.git"
      ref = {
        branch = "main"
      }
      secretRef = {
        name = "${var.app_name}-git-credentials"
      }
    }
  }
}


resource "kubernetes_manifest" "helm_release" {
  depends_on = [kubernetes_manifest.git_repo, kubernetes_namespace_v1.this]

  computed_fields = ["spec.values"]

  manifest = {
    apiVersion = "helm.toolkit.fluxcd.io/v2"
    kind       = "HelmRelease"
    metadata = {
      name      = var.app_name
      namespace = var.namespace
    }
    spec = {
      interval = "1m"
      chart = {
        spec = {
          chart = var.chart_path
          sourceRef = {
            kind      = "GitRepository"
            name      = var.app_name
            namespace = "flux-system"
          }
          interval          = "1m"
          reconcileStrategy = "Revision"
        }
      }
    }
  }
}

module "pod_identity" {
  count   = length(var.policy_statements) > 0 ? 1 : 0
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.0"

  name = "${var.cluster_name}-${var.app_name}"

  attach_custom_policy = true
  policy_statements    = var.policy_statements

  associations = {
    this = {
      cluster_name    = var.cluster_name
      namespace       = var.namespace
      service_account = var.service_account
    }
  }

  tags = {
    Environment = var.environment
  }
}
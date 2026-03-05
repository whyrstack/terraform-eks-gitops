##########################################################################
# Flux GITOPS
##########################################################################

locals {
  flux_apps_map = { for app in var.flux_apps : app.app_name => app }

  app_policies = {
    # key must match the name of the application 'app_name' in tfvars
    auth-service = [
      {
        sid       = "SecretsManager"
        actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
        resources = ["arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.cluster_name}/auth-service/*"]
      },
      {
        sid       = "DynamoDB"
        actions   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:Query"]
        resources = ["arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.cluster_name}-auth-*"]
      }
    ]

    payment-service = [
      {
        sid       = "SecretsManager"
        actions   = ["secretsmanager:GetSecretValue"]
        resources = ["arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.cluster_name}/payment-service/*"]
      },
      {
        sid       = "SQS"
        actions   = ["sqs:SendMessage", "sqs:ReceiveMessage", "sqs:DeleteMessage"]
        resources = ["arn:aws:sqs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${var.cluster_name}-payments"]
      },
      {
        sid       = "S3"
        actions   = ["s3:GetObject", "s3:PutObject"]
        resources = ["arn:aws:s3:::${var.cluster_name}-invoices/*"]
      }
    ]
  }
}

resource "helm_release" "flux" {
  depends_on = [module.eks]
  count      = var.endpoint_public_access ? 1 : 0

  name             = "flux2"
  repository       = "https://fluxcd-community.github.io/helm-charts"
  chart            = "flux2"
  namespace        = "flux-system"
  create_namespace = true
}


module "app" {
  source   = "./modules/app"
  depends_on = [helm_release.flux]

  for_each = var.endpoint_public_access ? local.flux_apps_map : {}

  cluster_name    = module.eks.cluster_name
  app_name        = each.key
  namespace       = each.value.app_namespace
  service_account = each.value.service_account
  github_project  = each.value.app_github_project
  github_token    = each.value.app_github_token
  chart_path      = each.value.chart_path
  create_namespace = each.value.create_namespace
  policy_statements = lookup(local.app_policies, each.key, [])
  environment     = var.environment
}

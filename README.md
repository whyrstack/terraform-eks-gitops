## Project purpose
Deploy an EKS cluster with bastion host for test and development.

## Project notes
- Privately accessible eks controlplane accessible via bastion host
- Cannot use terraform's kubernetes or helm providers due to publically accessible = false
- NodeGroup 1 creates worker node(s) in a private a private subnet.
- NodeGroup 2 creates worker node(s) in a public subnet (optional) and may be useful if deploying load balancers
- Pod Identities (irsa not used)
- Fluxcd gitops added
- Optionally add git project with helm charts to intergrate and deploy with fluxcd

## Project usage
1) create a ssh key in the aws console (to be used for bastion host)
2) create and update terraform.tfvars
```hcl
# Example
aws_region  = "eu-central-1"
aws_profile = "production"
environment = "dev"

# VPC network
vpc_cidr = "10.1.0.0/16"

# bastion
bastion_instance_type = "t3.small"
ssh_key_name          = "bastion"
your_ip               = "X.X.X.X/32" # allow your public IP for ssh'ing to Bastion host

# EKS
endpoint_public_access = true
cluster_name           = "whyrstack-cluster"
kubernetes_version     = "1.32"

## nodegroup 1 - deployed in private subnet (w NAT GW)
ng1_node_instance_type = "t3.medium"
ng1_min_size           = 1
ng1_max_size           = 2
ng1_desired_size       = 1

## nodegroup 2 - deployed in public subnet (w Internet GW)
ng2_node_instance_type = "t3.medium"
ng2_min_size           = 0
ng2_max_size           = 1
ng2_desired_size       = 0

# Flux application (helm only, no Kustomization)
flux_apps = [
  {
    app_name           = "auth-service"
    create_namespace   = true
    app_namespace      = "auth-service-ns"
    service_account    = "sa-auth-service" # no service_account — defaults to "" but is required for pod identities
    app_github_project = "whyrstack/fast-api-login-api-app"
    app_github_token   = "github_pat_XYZ"
    chart_path         = "./charts/my-chart"
  }
]
```
3) Update apps-fluxcd.tf pod identity; add policies your specific app needs
3) tofu init
4) tofu plan
5) tofu apply
6) tofu destroy # when done

The terraform outputs will note steps on how to connect to the cluster.

## Flux
### Verify flux
```bash
kubectl get gitrepositories -n flux-system
kubectl get helmreleases -n flux-system
kubectl logs -n flux-system -l app=source-controller --tail=50
kubectl logs -n flux-system -l app=helm-controller --tail=50
kubectl describe gitrepository auth-service -n flux-system
kubectl describe helmrelease auth-service -n auth-service-ns
```

## References
- https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest
- https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest
- https://registry.terraform.io/modules/terraform-aws-modules/eks-pod-identity/aws/latest

## Usage

If you're using the `terraform-aws-modules/eks/aws` and `terraform-aws-modules/vpc/aws` community modules

```hcl
module "efs-csi-driver" {
  source = "./modules/efs-csi-driver"
  cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url
  cluster_name = local.cluster_name
  worker_security_group_id = module.eks.worker_security_group_id
  vpc_id = module.vpc.vpc_id
  vpc_private_subnets = module.vpc.private_subnets
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the EKS cluster. Also used as a prefix in names of related resources. | `string` | `""` | yes |
| <a name="input_cluster_oidc_issuer_url"></a> [cluster\_oidc\_issuer\_url](#input\_cluster\_oidc\_issuer\_url) | The URL on the EKS cluster OIDC Issuer | `string` | `""` | yes |
| <a name="input_worker_security_group_id"></a> [worker\_security\_group\_id](#input\_worker\_security\_group\_id) | The id of the EKS cluster's worker SG for EFS access | `string` | `""` | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The ID of the Default VPC | `string` | `""` | yes |
| <a name="input_vpc_private_subnets"></a> [vpc\_private\_subnets](#input\_private\_subnets) | A list of private subnets inside the VPC | `list(string)` | `[]` | yes |
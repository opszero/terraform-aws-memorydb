# Terraform-aws-memorydb

# Terraform AWS Cloud MemoryDB Module

## Table of Contents
- [Introduction](#introduction)
- [Usage](#usage)
- [Examples](#Examples)
- [Author](#Author)
- [License](#license)
- [Inputs](#inputs)
- [Outputs](#outputs)

## Introduction
This Terraform module creates an AWS memorydb along with additional configuration options.
## Usage
To use this module, you can include it in your Terraform configuration. Here's an example of how to use it:

## Example: memorydb

```hcl
module "memorydb" {
  source                     = "git::https://github.com/opszero/terraform-aws-memorydb.git?ref=v1.0.1"
  name                       = "memorydb"
  engine_version             = "6.2"
  auto_minor_version_upgrade = true
  node_type                  = "db.t4g.medium"
  num_shards                 = 1
  num_replicas_per_shard     = 1
  data_tiering               = false

  tls_enabled              = true
  security_group_ids       = [module.security_group.security_group_id]
  maintenance_window       = "sun:23:00-mon:01:30"
  snapshot_retention_limit = 7
  snapshot_window          = "05:00-09:00"
  password                 = ""

  # Users
  users = {
    admin = {
      user_name     = "admin-user"
      access_string = "on ~* &* +@all"
      tags          = { user = "admin" }
    }
    readonly = {
      user_name     = "readonly-user"
      access_string = "on ~* &* -@all +@read"
      tags          = { user = "readonly" }
    }
  }

  # ACL
  acl_name = "memorydb-acl"
  # Parameter group
  parameter_group_name        = "memorydb-param-group"
  parameter_group_description = "Example MemoryDB parameter group"
  parameter_group_family      = "memorydb_redis6"
  parameter_group_parameters = [
    {
      name  = "activedefrag"
      value = "yes"
    }
  ]
  parameter_group_tags = {
    parameter_group = "custom"
  }

  # Subnet group
  subnet_group_name = "memorydb-subnet-group"
  subnet_ids        = module.subnets.public_subnet_id
  subnet_group_tags = {
    subnet_group = "custom"
  }

}
```

## Examples
For detailed examples on how to use this module, please refer to the [Examples](https://github.com/opszero/terraform-aws-memorydb/tree/main/example) directory within this repository.

## Author
Your Name Replace **MIT** and **opsZero** with the appropriate license and your information. Feel free to expand this README with additional details or usage instructions as needed for your specific use case.

## License
This project is licensed under the **MIT** License - see the [LICENSE](https://github.com/opszero/terraform-aws-memorydb/blob/main/LICENSE) file for details.

<!-- BEGIN_TF_DOCS -->

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.47 |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_acl_use_name_prefix"></a> [acl\_use\_name\_prefix](#input\_acl\_use\_name\_prefix) | Determines whether `acl_name` is used as a prefix | `bool` | `false` | no |
| <a name="input_acl_user_names"></a> [acl\_user\_names](#input\_acl\_user\_names) | List of externally created user names to associate with the ACL | `list(string)` | `[]` | no |
| <a name="input_auto_minor_version_upgrade"></a> [auto\_minor\_version\_upgrade](#input\_auto\_minor\_version\_upgrade) | When set to `true`, the cluster will automatically receive minor engine version upgrades after launch. Defaults to `true` | `bool` | `null` | no |
| <a name="input_create_users"></a> [create\_users](#input\_create\_users) | Determines whether to create users specified | `bool` | `true` | no |
| <a name="input_data_tiering"></a> [data\_tiering](#input\_data\_tiering) | Must be set to `true` when using a data tiering node type | `bool` | `null` | no |
| <a name="input_description"></a> [description](#input\_description) | Description for the cluster. Defaults to `Managed by Terraform` | `string` | `null` | no |
| <a name="input_engine_version"></a> [engine\_version](#input\_engine\_version) | Version number of the Redis engine to be used for the cluster. Downgrades are not supported | `string` | `null` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | ARN of the KMS key used to encrypt the cluster at rest | `string` | `null` | no |
| <a name="input_maintenance_window"></a> [maintenance\_window](#input\_maintenance\_window) | Specifies the weekly time range during which maintenance on the cluster is performed. It is specified as a range in the format `ddd:hh24:mi-ddd:hh24:mi` | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Cluster name - also default name used on all resources if more specific resource names are not provided | `string` | `""` | no |
| <a name="input_node_type"></a> [node\_type](#input\_node\_type) | The compute and memory capacity of the nodes in the cluster. See AWS documentation on [supported node types](https://docs.aws.amazon.com/memorydb/latest/devguide/nodes.supportedtypes.html) as well as [vertical scaling](https://docs.aws.amazon.com/memorydb/latest/devguide/cluster-vertical-scaling.html) | `string` | `null` | no |
| <a name="input_num_replicas_per_shard"></a> [num\_replicas\_per\_shard](#input\_num\_replicas\_per\_shard) | The number of replicas to apply to each shard, up to a maximum of 5. Defaults to `1` (i.e. 2 nodes per shard) | `number` | `null` | no |
| <a name="input_num_shards"></a> [num\_shards](#input\_num\_shards) | The number of shards in the cluster. Defaults to `1` | `number` | `null` | no |
| <a name="input_parameter_group_family"></a> [parameter\_group\_family](#input\_parameter\_group\_family) | The engine version that the parameter group can be used with | `string` | `null` | no |
| <a name="input_parameter_group_parameters"></a> [parameter\_group\_parameters](#input\_parameter\_group\_parameters) | A list of parameter maps to apply | `list(map(string))` | `[]` | no |
| <a name="input_password"></a> [password](#input\_password) | The password for the AWS MemoryDB user. Leave empty to generate a random password. | `string` | `""` | no |
| <a name="input_port"></a> [port](#input\_port) | The port number on which each of the nodes accepts connections. Defaults to `6379` | `number` | `null` | no |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | Set of VPC Security Group ID-s to associate with this cluster | `list(string)` | `null` | no |
| <a name="input_snapshot_arns"></a> [snapshot\_arns](#input\_snapshot\_arns) | List of ARN-s that uniquely identify RDB snapshot files stored in S3. The snapshot files will be used to populate the new cluster | `list(string)` | `null` | no |
| <a name="input_snapshot_name"></a> [snapshot\_name](#input\_snapshot\_name) | The name of a snapshot from which to restore data into the new cluster | `string` | `null` | no |
| <a name="input_snapshot_retention_limit"></a> [snapshot\_retention\_limit](#input\_snapshot\_retention\_limit) | The number of days for which MemoryDB retains automatic snapshots before deleting them. When set to `0`, automatic backups are disabled. Defaults to `0` | `number` | `null` | no |
| <a name="input_snapshot_window"></a> [snapshot\_window](#input\_snapshot\_window) | The daily time range (in UTC) during which MemoryDB begins taking a daily snapshot of your shard. Example: `05:00-09:00` | `string` | `null` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | Set of VPC Subnet ID-s for the subnet group. At least one subnet must be provided | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to use on all resources | `map(string)` | `{}` | no |
| <a name="input_tls_enabled"></a> [tls\_enabled](#input\_tls\_enabled) | A flag to enable in-transit encryption on the cluster. When set to `false`, the `acl_name` must be `open-access`. Defaults to `true` | `bool` | `null` | no |
| <a name="input_users"></a> [users](#input\_users) | A map of user definitions (maps) to be created | `any` | `{}` | no |
## Resources

| Name | Type |
|------|------|
| [aws_memorydb_acl.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/memorydb_acl) | resource |
| [aws_memorydb_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/memorydb_cluster) | resource |
| [aws_memorydb_parameter_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/memorydb_parameter_group) | resource |
| [aws_memorydb_subnet_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/memorydb_subnet_group) | resource |
| [aws_memorydb_user.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/memorydb_user) | resource |
| [aws_sns_topic.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_ssm_parameter.memorydb_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [random_password.main](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_acl_arn"></a> [acl\_arn](#output\_acl\_arn) | The ARN of the ACL |
| <a name="output_acl_id"></a> [acl\_id](#output\_acl\_id) | Name of the ACL |
| <a name="output_acl_minimum_engine_version"></a> [acl\_minimum\_engine\_version](#output\_acl\_minimum\_engine\_version) | The minimum engine version supported by the ACL |
| <a name="output_cluster_arn"></a> [cluster\_arn](#output\_cluster\_arn) | The ARN of the cluster |
| <a name="output_cluster_endpoint_address"></a> [cluster\_endpoint\_address](#output\_cluster\_endpoint\_address) | DNS hostname of the cluster configuration endpoint |
| <a name="output_cluster_endpoint_port"></a> [cluster\_endpoint\_port](#output\_cluster\_endpoint\_port) | Port number that the cluster configuration endpoint is listening on |
| <a name="output_cluster_engine_patch_version"></a> [cluster\_engine\_patch\_version](#output\_cluster\_engine\_patch\_version) | Patch version number of the Redis engine used by the cluster |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | Cluster name |
| <a name="output_cluster_shards"></a> [cluster\_shards](#output\_cluster\_shards) | Set of shards in this cluster |
| <a name="output_parameter_group_arn"></a> [parameter\_group\_arn](#output\_parameter\_group\_arn) | The ARN of the parameter group |
| <a name="output_parameter_group_id"></a> [parameter\_group\_id](#output\_parameter\_group\_id) | Name of the parameter group |
| <a name="output_subnet_group_arn"></a> [subnet\_group\_arn](#output\_subnet\_group\_arn) | ARN of the subnet group |
| <a name="output_subnet_group_id"></a> [subnet\_group\_id](#output\_subnet\_group\_id) | Name of the subnet group |
| <a name="output_subnet_group_vpc_id"></a> [subnet\_group\_vpc\_id](#output\_subnet\_group\_vpc\_id) | The VPC in which the subnet group exists |
| <a name="output_users"></a> [users](#output\_users) | Map of attributes for the users created |
# 🚀 Built by opsZero!

<a href="https://opszero.com"><img src="https://opszero.com/wp-content/uploads/2024/07/opsZero_logo_svg.svg" width="300px"/></a>

Since 2016 [opsZero](https://opszero.com) has been providing Kubernetes
expertise to companies of all sizes on any Cloud. With a focus on AI and
Compliance we can say we seen it all whether SOC2, HIPAA, PCI-DSS, ITAR,
FedRAMP, CMMC we have you and your customers covered.

We provide support to organizations in the following ways:

- [Modernize or Migrate to Kubernetes](https://opszero.com/solutions/modernization/)
- [Cloud Infrastructure with Kubernetes on AWS, Azure, Google Cloud, or Bare Metal](https://opszero.com/solutions/cloud-infrastructure/)
- [Building AI and Data Pipelines on Kubernetes](https://opszero.com/solutions/ai/)
- [Optimizing Existing Kubernetes Workloads](https://opszero.com/solutions/optimized-workloads/)

We do this with a high-touch support model where you:

- Get access to us on Slack, Microsoft Teams or Email
- Get 24/7 coverage of your infrastructure
- Get an accelerated migration to Kubernetes

Please [schedule a call](https://calendly.com/opszero-llc/discovery) if you need support.

<br/><br/>

<div style="display: block">
  <img src="https://opszero.com/wp-content/uploads/2024/07/aws-advanced.png" width="150px" />
  <img src="https://opszero.com/wp-content/uploads/2024/07/AWS-public-sector.png" width="150px" />
  <img src="https://opszero.com/wp-content/uploads/2024/07/AWS-eks.png" width="150px" />
</div>
<!-- END_TF_DOCS -->
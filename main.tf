resource "random_password" "main" {
  length           = 16
  special          = true
  override_special = "_%@"
}
################################################################################
# Cluster
################################################################################

resource "aws_memorydb_cluster" "this" {
  name        = var.name
  description = var.parameter_group_description

  engine_version             = var.engine_version
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  port                       = var.port
  node_type                  = var.node_type
  num_shards                 = var.num_shards
  num_replicas_per_shard     = var.num_replicas_per_shard
  parameter_group_name       = var.parameter_group_name
  data_tiering               = var.data_tiering

  acl_name           = var.acl_name
  kms_key_arn        = var.kms_key_arn
  tls_enabled        = var.tls_enabled
  security_group_ids = var.security_group_ids
  subnet_group_name  = var.subnet_group_name

  maintenance_window = var.maintenance_window
  sns_topic_arn      = aws_sns_topic.main.arn

  snapshot_name            = var.snapshot_name
  snapshot_arns            = var.snapshot_arns
  snapshot_retention_limit = var.snapshot_retention_limit
  snapshot_window          = var.snapshot_window
  final_snapshot_name      = "${var.name}-final"

  tags = var.tags
}

#tfsec:ignore:aws-sns-topic-encryption-use-cmk
resource "aws_sns_topic" "main" {
  name              = var.name
  kms_master_key_id = "alias/aws/sns"

  tags = var.tags
}
#################### secretsmanager  ############

resource "aws_ssm_parameter" "memorydb_password" {
  for_each = { for k, v in var.users : k => v }

  type = "SecureString"

  name  = "/memorydb/${var.name}/${each.value.user_name}/password"
  value = var.password == "" ? random_password.main.result : var.password
}


################################################################################
# User(s)
################################################################################

resource "aws_memorydb_user" "this" {
  for_each = { for k, v in var.users : k => v }

  user_name     = each.value.user_name
  access_string = each.value.access_string

  authentication_mode {
    type      = "password"
    passwords = [var.password == "" ? random_password.main.result : var.password]
  }

  tags = var.tags
}


################################################################################
# ACL
################################################################################

resource "aws_memorydb_acl" "this" {
  name = var.name

  user_names = distinct(concat([for u in aws_memorydb_user.this : u.id], var.acl_user_names))

  lifecycle {
    create_before_destroy = true
  }

  tags = var.tags
}

################################################################################
# Parameter Group
################################################################################

resource "aws_memorydb_parameter_group" "this" {
  name        = var.name
  description = var.parameter_group_description
  family      = var.parameter_group_family

  dynamic "parameter" {
    for_each = var.parameter_group_parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = var.parameter_group_tags
}

################################################################################
# Subnet Group
################################################################################

resource "aws_memorydb_subnet_group" "this" {
  name        = var.name
  description = var.parameter_group_description
  subnet_ids  = var.subnet_ids

  lifecycle {
    create_before_destroy = true
  }

  tags = var.subnet_group_tags
}

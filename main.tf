locals {
  create_acl_name = coalesce(var.acl_name, var.name)
  acl_name        = var.create && var.create_acl ? aws_memorydb_acl.this[0].id : var.acl_name

  create_parameter_group_name = coalesce(var.parameter_group_name, var.name)
  parameter_group_name        = var.create && var.create_parameter_group ? aws_memorydb_parameter_group.this[0].id : var.parameter_group_name

  create_subnet_group_name = coalesce(var.subnet_group_name, var.name)
  subnet_group_name        = var.create && var.create_subnet_group ? aws_memorydb_subnet_group.this[0].id : var.subnet_group_name
}

module "labels" {
  source      = "cypik/labels/aws"
  version     = "1.0.1"
  name        = var.name
  environment = var.environment
  managedby   = var.managedby
  label_order = var.label_order
  repository  = var.repository
}

resource "random_password" "main" {
  length           = 16
  special          = true
  override_special = "_%@"
}
################################################################################
# Cluster
################################################################################

resource "aws_memorydb_cluster" "this" {
  count = var.create ? 1 : 0

  name        = var.use_name_prefix ? null : var.name
  name_prefix = var.use_name_prefix ? "${var.name}-" : null
  description = var.description

  engine_version             = var.engine_version
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  port                       = var.port
  node_type                  = var.node_type
  num_shards                 = var.num_shards
  num_replicas_per_shard     = var.num_replicas_per_shard
  parameter_group_name       = local.parameter_group_name
  data_tiering               = var.data_tiering

  acl_name           = local.acl_name
  kms_key_arn        = var.kms_key_arn
  tls_enabled        = var.tls_enabled
  security_group_ids = var.security_group_ids
  subnet_group_name  = local.subnet_group_name

  maintenance_window = var.maintenance_window
  sns_topic_arn      = aws_sns_topic.main.arn

  snapshot_name            = var.snapshot_name
  snapshot_arns            = var.snapshot_arns
  snapshot_retention_limit = var.snapshot_retention_limit
  snapshot_window          = var.snapshot_window
  final_snapshot_name      = var.final_snapshot_name

  tags = module.labels.tags
}


resource "aws_sns_topic" "main" {
  name              = var.sns_name
  kms_master_key_id = "alias/aws/sns"

  tags = module.labels.tags
}
#################### secretsmanager  ############

resource "aws_secretsmanager_secret" "memorydb_password" {
  for_each = { for k, v in var.users : k => v if var.create && var.create_users }

  name = "${each.value.user_name}_password"
}

resource "aws_secretsmanager_secret_version" "memorydb_password_version" {
  for_each = { for k, v in var.users : k => v if var.create && var.create_users }

  secret_id     = aws_secretsmanager_secret.memorydb_password[each.key].id
  secret_string = jsonencode({
    password = var.password == "" ? random_password.main.result : var.password
  })
}




################################################################################
# User(s)
################################################################################

resource "aws_memorydb_user" "this" {
  for_each = { for k, v in var.users : k => v if var.create && var.create_users }

  user_name     = each.value.user_name
  access_string = each.value.access_string

  authentication_mode {
    type      = "password"
    passwords = [aws_secretsmanager_secret_version.memorydb_password_version[each.key].secret_string]
  }

  tags = module.labels.tags
}


################################################################################
# ACL
################################################################################

resource "aws_memorydb_acl" "this" {
  count = var.create && var.create_acl ? 1 : 0

  name        = var.acl_use_name_prefix ? null : local.create_acl_name
  name_prefix = var.acl_use_name_prefix ? "${local.create_acl_name}-" : null

  user_names = distinct(concat([for u in aws_memorydb_user.this : u.id], var.acl_user_names))

  lifecycle {
    create_before_destroy = true
  }

  tags = module.labels.tags
}

################################################################################
# Parameter Group
################################################################################

resource "aws_memorydb_parameter_group" "this" {
  count = var.create && var.create_parameter_group ? 1 : 0

  name        = var.parameter_group_use_name_prefix ? null : local.create_parameter_group_name
  name_prefix = var.parameter_group_use_name_prefix ? "${local.create_parameter_group_name}-" : null
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

  tags = module.labels.tags
}

################################################################################
# Subnet Group
################################################################################

resource "aws_memorydb_subnet_group" "this" {
  count = var.create && var.create_subnet_group ? 1 : 0

  name        = var.subnet_group_use_name_prefix ? null : local.create_subnet_group_name
  name_prefix = var.subnet_group_use_name_prefix ? "${local.create_subnet_group_name}-" : null
  description = var.subnet_group_description
  subnet_ids  = var.subnet_ids

  lifecycle {
    create_before_destroy = true
  }

  tags = module.labels.tags
}
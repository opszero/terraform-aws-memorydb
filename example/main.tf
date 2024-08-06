provider "aws" {
  region = "ap-south-1"
}

module "vpc" {
  source          = "cypik/vpc/aws"
  version         = "1.0.1"
  name            = "vpc"
  environment     = "test"
  cidr_block      = "10.0.0.0/16"
  enable_flow_log = false
}


module "subnets" {
  source             = "cypik/subnet/aws"
  version            = "1.0.1"
  name               = "subnets"
  environment        = "test"
  availability_zones = ["ap-south-1a", "ap-south-1b"]
  vpc_id             = module.vpc.id
  type               = "public-private"
  igw_id             = module.vpc.igw_id
  cidr_block         = module.vpc.vpc_cidr_block
  ipv6_cidr_block    = module.vpc.ipv6_cidr_block
}

module "security_group" {
  source      = "cypik/security-group/aws"
  version     = "1.0.1"
  name        = "security-group"
  environment = "test"
  vpc_id      = module.vpc.id

  ## INGRESS Rules
  new_sg_ingress_rules_with_cidr_blocks = [
    {
      rule_count  = 1
      from_port   = 6379
      to_port     = 6379
      protocol    = "tcp"
      cidr_blocks = ["172.16.0.0/16"]
      description = "Allow ssh traffic."
    },
  ]

  ## EGRESS Rules
  new_sg_egress_rules_with_cidr_blocks = [
    {
      rule_count  = 1
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["172.16.0.0/16"]
      description = "Allow ssh outbound traffic."
    }
  ]
}



################################################################################
# MemoryDB Module
###############################################################################

module "memory_db" {
  source = ".."

  # Cluster
  name                       = "memorydb"
  environment                = "test"
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
      #      passwords     = [random_password.password.result]
      tags = { user = "readonly" }
    }
  }

  # ACL
  acl_name = "memorydb-acl"
  acl_tags = { acl = "custom" }

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



locals {
  dash_license = "arn:aws:secretsmanager:eu-central-1:754489498669:secret:DashTrialLicense-7EzdZh"
  mdcb_license = "arn:aws:secretsmanager:eu-central-1:754489498669:secret:MDCBTrialLicense-9BIRjv"
}

module "gateway-td-template" {
  source      = "../modules/fg-task-definition"
  # cluster     = aws_ecs_cluster.env.arn 	# For Service
  # cdt         = "templates/cd-awsvpc.tpl" # Default
  # public_ip   = true 											# For subnet 
  # sr          = aws_service_discovery_private_dns_namespace.internal.id 
  tearn       = aws_iam_role.gromit_ter.arn
  # env_name    = var.name									# For Service
  # vpc         = data.terraform_remote_state.infra.outputs.vpc_id # For Service
  # subnets     = data.aws_subnet_ids.public.ids	# For Service
  common_tags = local.common_tags
  volume_map  = { config = data.terraform_remote_state.base.outputs.config_efs }
  cd = {
    name      = "tyk-template",
    command   = ["--conf=/conf/tyk.conf"],
    port      = 8181,
    cpu	      = 256,
    memory    = 512,
    # To be Overrided
    log_group = "dev-env",
    # To be Overrided
    image     = join(":", [data.terraform_remote_state.base.outputs.tyk["ecr"], "master"])
    mounts = [
      { src = "config", dest = "/conf", readonly = true }
    ],
    env = [],
    secrets = [],
    region = data.terraform_remote_state.base.outputs.region
  }
}

module "redis-td-template" {
  source      = "../modules/fg-task-definition"
  tearn       = aws_iam_role.gromit_ter.arn
  common_tags = local.common_tags
  volume_map  = {}
  cd = {
    name      = "redis-template",
    command   = [],
    port      = 6379,
    cpu	      = 256,
    memory    = 512,
    log_group = "dev-env",
    image     = "redis"
    mounts = [],
    env = [],
    secrets = [],
    region = data.terraform_remote_state.base.outputs.region
  }
}

module "dashboard-td-template" {
  source      = "../modules/fg-task-definition"
  tearn       = aws_iam_role.gromit_ter.arn
  common_tags = local.common_tags
  volume_map  = { config = data.terraform_remote_state.base.outputs.config_efs }
  cd = {
    name      = "tyk-analytics-template",
    command   = ["--conf=/conf/tyk-analytics.conf"],
    port      = 3000,
    cpu	      = 256,
    memory    = 512,
    log_group = "dev-env",
    image     = join(":", [data.terraform_remote_state.base.outputs.tyk-analytics["ecr"], "master"])
    mounts = [
      { src = "config", dest = "/conf", readonly = true }
    ],
    env = [],
    secrets = [
      { name = "TYK_DB_LICENSEKEY", from = local.dash_license }
    ],
    region = data.terraform_remote_state.base.outputs.region
  }
}

module "pump-td-template" {
  source      = "../modules/fg-task-definition"
  tearn       = aws_iam_role.gromit_ter.arn
  common_tags = local.common_tags
  volume_map  = { config = data.terraform_remote_state.base.outputs.config_efs }
  cd = {
    name      = "tyk-pump-template",
    command   = ["--conf=/conf/tyk-pump.conf"],
    # pump doesn't listen, but the module expects a port
    port      = 443,
    cpu	      = 256,
    memory    = 512,
    log_group = "dev-env",
    image     = join(":", [data.terraform_remote_state.base.outputs.tyk-pump["ecr"], "master"])
    mounts = [
      { src = "config", dest = "/conf", readonly = true }
    ],
    env = [],
    secrets = [],
    region = data.terraform_remote_state.base.outputs.region
  }
}

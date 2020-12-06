# Used as a proxy for ECR registry ID
data "aws_caller_identity" "current" {}

data "aws_route53_zone" "dev_tyk_tech" {
  name         = "dev.tyk.technology"
  private_zone = false
}

# Processes env updates
module "gromit-run" {
  source = "../modules/fg-sched-task"

  cdt      = "templates/cd-awsvpc.tpl"
  schedule = "rate(37 minutes)"
  cluster  = aws_ecs_cluster.internal.arn
  # Container definition
  cd = {
    name      = "grun",
    log_group = "internal",
    image     = var.gromit_image,
    command   = ["cluster", "run", "/config"],
    mounts = [
      { src = "config", dest = "/config", readonly = false }
    ],
    env = [
      { name = "GROMIT_TABLENAME", value = local.gromit.table },
      { name = "GROMIT_REPOS", value = local.gromit.repos },
      { name = "GROMIT_REGISTRYID", value = data.aws_caller_identity.current.account_id },
      { name = "GROMIT_DOMAIN", value = data.aws_route53_zone.dev_tyk_tech.name },
      { name = "GROMIT_ZONEID", value = data.aws_route53_zone.dev_tyk_tech.zone_id }
    ],
    secrets = [
      { name = "TF_API_TOKEN", from = local.gromit.tfcloud }
    ],
    region = var.region
  }
  trarn       = aws_iam_role.gromit_tr.arn
  tearn       = aws_iam_role.gromit_ter.arn
  vpc         = module.vpc.vpc_id
  subnets     = module.vpc.private_subnets
  volume_map  = { config = data.terraform_remote_state.base.outputs.config_efs }
  common_tags = local.common_tags
}

# Listen for new builds
module "gromit-serve" {
  source = "../modules/fg-service"

  cluster = aws_ecs_cluster.internal.arn
  cdt     = "templates/cd-awsvpc.tpl"
  # Container definition
  cd = {
    name      = "gserve",
    port      = 443,
    log_group = "internal",
    image     = var.gromit_image,
    command   = ["serve", "--certpath=/cfssl/gromit/server"],
    mounts = [
      { src = "cfssl", dest = "/cfssl", readonly = true },
    ],
    env = [
      { name = "GROMIT_TABLENAME", value = local.gromit.table },
      { name = "GROMIT_REGISTRYID", value = data.aws_caller_identity.current.account_id },
      { name = "GROMIT_REPOS", value = local.gromit.repos }
    ],
    secrets = [],
    region  = var.region
  }
  trarn       = aws_iam_role.gromit_tr.arn
  tearn       = aws_iam_role.gromit_ter.arn
  vpc         = module.vpc.vpc_id
  subnets     = module.vpc.public_subnets
  volume_map  = { cfssl = data.terraform_remote_state.base.outputs.cfssl_efs }
  common_tags = local.common_tags
}

# Refresh license
module "licenser" {
  source = "../modules/fg-sched-task"

  schedule = "rate(25 days)"
  cluster  = aws_ecs_cluster.internal.arn
  cdt      = "templates/cd-awsvpc.tpl"
  # Container definition
  cd = {
    name      = "db-license",
    log_group = "internal",
    image     = var.gromit_image,
    command   = ["licenser", "dashboard-trial", "/config/dash.license"],
    mounts = [
      { src = "config", dest = "/config", readonly = false }
    ],
    env = [],
    secrets = [
      { name = "GROMIT_LICENSER_TOKEN", from = local.gromit.dashtrial_token }
    ],
    region = var.region
  }
  trarn       = aws_iam_role.gromit_tr.arn
  tearn       = aws_iam_role.gromit_ter.arn
  vpc         = module.vpc.vpc_id
  subnets     = module.vpc.private_subnets
  volume_map  = { config = data.terraform_remote_state.base.outputs.config_efs }
  common_tags = local.common_tags
}


# Keep DNS refreshed
module "chitragupta" {
  source = "../modules/fg-sched-task"

  schedule = "rate(13 minutes)"
  cluster  = aws_ecs_cluster.internal.arn
  cdt      = "templates/cd-awsvpc.tpl"
  # Container definition
  cd = {
    name      = "chitragupta",
    log_group = "internal",
    image     = var.gromit_image,
    command   = ["cluster", "expose", "-a"],
    mounts = [],
    env = [],
    secrets = [],
    region = var.region
  }
  trarn       = aws_iam_role.gromit_tr.arn
  tearn       = aws_iam_role.gromit_ter.arn
  vpc         = module.vpc.vpc_id
  subnets     = module.vpc.private_subnets
  volume_map  = { config = data.terraform_remote_state.base.outputs.config_efs }
  common_tags = local.common_tags
}

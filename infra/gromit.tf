# Used as a proxy for ECR registry ID
data "aws_caller_identity" "current" {}

data "aws_route53_zone" "dev_tyk_tech" {
  name         = "dev.tyk.technology"
  private_zone = false
}

# Processes env updates
module "sow" {
  source = "../modules/fg-sched-task"

  cdt      = "templates/cd-awsvpc.tpl"
  schedule = "rate(37 minutes)"
  cluster  = aws_ecs_cluster.internal.arn
  # Container definition
  cd = {
    name      = "sow",
    log_group = "internal",
    image     = var.gromit_image,
    command   = ["sow", "/config"],
    mounts = [
      { src = "config", dest = "/config", readonly = false }
    ],
    env = [
      { name = "GROMIT_TABLENAME", value = local.gromit.table },
      { name = "GROMIT_REPOS", value = local.gromit.repos },
      { name = "GROMIT_BASE", value = local.gromit.base },
      { name = "GROMIT_INFRA", value = local.gromit.infra },
      { name = "GROMIT_REGISTRYID", value = data.aws_caller_identity.current.account_id },
      { name = "GROMIT_CLUSTER_DOMAIN", value = data.aws_route53_zone.dev_tyk_tech.name },
      { name = "GROMIT_CLUSTER_ZONEID", value = data.aws_route53_zone.dev_tyk_tech.zone_id }
    ],
    secrets = [
      { name = "TF_API_TOKEN", from = "arn:aws:secretsmanager:eu-central-1:754489498669:secret:TFCloudAPI-1UnG8y" }
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
module "serve" {
  source = "../modules/fg-service"

  cluster = aws_ecs_cluster.internal.arn
  cdt     = "templates/cd-awsvpc.tpl"
  # Container definition
  cd = {
    name      = "gserve",
    port      = 443,
    log_group = "internal",
    image     = var.gromit_image,
    command   = ["serve"],
    mounts = [
      { src = "cfssl", dest = "/cfssl", readonly = true },
    ],
    env = [
      { name = "GROMIT_TABLENAME", value = local.gromit.table },
      { name = "GROMIT_REGISTRYID", value = data.aws_caller_identity.current.account_id },
      { name = "GROMIT_REPOS", value = local.gromit.repos },
      { name = "GROMIT_CA", value = local.gromit.ca },
      { name = "GROMIT_SERVE_CERT", value = local.gromit.serve_cert }
    ],
    secrets = [
      { name = "GROMIT_SERVE_KEY", from = aws_secretsmanager_secret.gromit_serve_key.arn }
    ],
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
      { name = "GROMIT_LICENSER_TOKEN", from = aws_secretsmanager_secret.dash_token.arn }
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
    mounts    = [],
    env       = [
      { name = "GROMIT_CLUSTER_DOMAIN", value = data.aws_route53_zone.dev_tyk_tech.name },
      { name = "GROMIT_CLUSTER_ZONEID", value = data.aws_route53_zone.dev_tyk_tech.zone_id }
    ],
    secrets   = [],
    region    = var.region
  }
  trarn       = aws_iam_role.gromit_tr.arn
  tearn       = aws_iam_role.gromit_ter.arn
  vpc         = module.vpc.vpc_id
  subnets     = module.vpc.private_subnets
  volume_map  = { config = data.terraform_remote_state.base.outputs.config_efs }
  common_tags = local.common_tags
}

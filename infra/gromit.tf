# Used as a proxy for ECR registry ID
data "aws_caller_identity" "current" {}

# Processes env updates
module "gromit-run" {
  source = "../modules/fg-sched-task"

  cdt      = "templates/cd-awsvpc.tpl"
  schedule = "rate(37 minutes)"
  cluster  = aws_ecs_cluster.internal.arn
  # Container definition
  cd = {
    name     = "grun",
    log_group = "internal",
    image     = var.gromit_image,
    command   = ["cluster", "run", "/config"],
    mounts = [
      { src = "config", dest = "/config", readonly = false }
    ],
    env = [
      { name = "GROMIT_TABLENAME", value = local.gromit.table },
      { name = "GROMIT_REPOS", value = local.gromit.repos },
      { name = "GROMIT_DOMAIN", value = local.gromit.domain },
      { name = "GROMIT_ZONEID", value = aws_route53_zone.dev_tyk_tech.zone_id }
    ],
    secrets = [
      { name = "TF_API_TOKEN", from = "arn:aws:secretsmanager:eu-central-1:754489498669:secret:TFCloudAPI-1UnG8y" }
    ],
    region = var.region
  }
  trarn       = aws_iam_role.gromit.arn
  tearn       = aws_iam_role.ecs_role.arn
  vpc         = module.vpc.vpc_id
  subnets     = module.vpc.private_subnets
  volume_map  = { config = var.config_efs }
  common_tags = local.common_tags
}

# Listen for new builds
module "gromit-serve" {
  source = "../modules/fg-service"

  cluster  = aws_ecs_cluster.internal.arn
  cdt = "templates/cd-awsvpc.tpl"
  # Container definition
  cd = {
    name   = "gserve",
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
  trarn       = aws_iam_role.gromit.arn
  tearn       = aws_iam_role.ecs_role.arn
  vpc         = module.vpc.vpc_id
  subnets     = module.vpc.public_subnets
  volume_map  = { cfssl = var.cfssl_efs }
  common_tags = local.common_tags
}

# Refresh license
module "licenser" {
  source   = "../modules/fg-sched-task"

  schedule = "rate(25 days)"
  cluster  = aws_ecs_cluster.internal.arn
  cdt = "templates/cd-awsvpc.tpl"
  # Container definition
  cd = {
    name     = "db-license",
    log_group = "internal",
    image     = var.gromit_image,
    command   = ["licenser", "dashboard-trial", "/config/dash.license"],
    mounts = [
      { src = "config", dest = "/config", readonly = false }
    ],
    env = [],
    secrets = [
      { name = "GROMIT_LICENSE_TOKEN", from = "arn:aws:secretsmanager:eu-central-1:754489498669:secret:TFCloudAPI-1UnG8y" }
    ],
    region = var.region
  }
  trarn       = aws_iam_role.gromit.arn
  tearn       = aws_iam_role.ecs_role.arn
  vpc         = module.vpc.vpc_id
  subnets     = module.vpc.private_subnets
  volume_map  = { config = var.config_efs }
  common_tags = local.common_tags
}

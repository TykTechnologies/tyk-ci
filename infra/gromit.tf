provider "sops" {}

data "sops_file" "secrets" {
  source_file = "infra-secrets.yaml"
}

data "aws_region" "current" {}

data "aws_route53_zone" "dev_tyk_tech" {
  name         = "dev.tyk.technology"
  private_zone = false
}

resource "aws_ssm_parameter" "licenser_tokens" {
  for_each = toset(["dashboard", "mdcb"])

  name        = "/cd/${each.value}_trial_token"
  type        = "SecureString"
  description = "Token to fetch the ${each.value} trial license"
  value       = data.sops_file.secrets.data["licenser_tokens.${each.value}"]
}

# API server for test UI
module "tui" {
  source = "./modules/fg-service"

  cluster = aws_ecs_cluster.internal.arn
  cdt     = "templates/cd-awsvpc.tpl"
  # Container definition
  cd = {
    name      = "tui",
    port      = 80,
    log_group = "internal",
    image     = var.gromit_image,
    command   = ["--textlogs=false", "policy", "serve", "--save=/shared/prod-variations.yml", "--port=:80"],
    mounts = [
      { src = "shared", dest = "/shared", readonly = false },
    ],
    env     = [],
    secrets = [],
    region  = data.aws_region.current.name
  }
  trarn      = aws_iam_role.ter.arn
  tearn      = aws_iam_role.ter.arn
  vpc        = data.terraform_remote_state.base.outputs.vpc.id
  subnets    = data.terraform_remote_state.base.outputs.vpc.public_subnets
  volume_map = { shared = { fs_id = data.terraform_remote_state.base.outputs.shared_efs, root = "/tui" } }
}

# Refresh dash license
module "licenser" {
  source = "./modules/fg-sched-task"

  schedule = "rate(25 days)"
  cluster  = aws_ecs_cluster.internal.arn
  cdt      = "templates/cd-awsvpc.tpl"
  # Container definition
  cd = {
    name      = "db-license",
    log_group = "internal",
    image     = var.gromit_image,
    command   = ["--textlogs=false", "env", "licenser", "dashboard-trial", "/cd/dashboard_license"],
    mounts    = [],
    env       = [],
    secrets = [
      { name = "LICENSER_TOKEN", valueFrom = aws_ssm_parameter.licenser_tokens["dashboard"].arn }
    ],
    region = data.aws_region.current.name
  }
  trarn      = aws_iam_role.ter.arn
  tearn      = aws_iam_role.ter.arn
  vpc        = data.terraform_remote_state.base.outputs.vpc.id
  subnets    = data.terraform_remote_state.base.outputs.vpc.private_subnets
  volume_map = {}
}


# Keep DNS refreshed
# module "chitragupta" {
#   source = "../modules/fg-sched-task"

#   schedule = "rate(13 minutes)"
#   cluster  = aws_ecs_cluster.internal.arn
#   cdt      = "templates/cd-awsvpc.tpl"
#   # Container definition
#   cd = {
#     name      = "chitragupta",
#     log_group = "internal",
#     image     = var.gromit_image,
#     command   = ["cluster", "expose", "-a"],
#     mounts    = [],
#     env = [
#       { name = "GROMIT_CLUSTER_DOMAIN", value = data.aws_route53_zone.dev_tyk_tech.name },
#       { name = "GROMIT_CLUSTER_ZONEID", value = data.aws_route53_zone.dev_tyk_tech.zone_id }
#     ],
#     secrets = [],
#     region  = var.region
#   }
#   trarn       = aws_iam_role.gromit_tr.arn
#   tearn       = aws_iam_role.gromit_ter.arn
#   vpc         = module.vpc.vpc_id
#   subnets     = module.vpc.private_subnets
#   volume_map  = { config = data.terraform_remote_state.base.outputs.config_efs }
#   common_tags = local.common_tags
# }

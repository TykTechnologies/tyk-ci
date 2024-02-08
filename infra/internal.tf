# Internal cluster ancillaries

# Certificate Authority
module "stepca" {
  source = "./modules/fg-service"

  cluster = aws_ecs_cluster.internal.arn
  cdt     = "templates/cd-awsvpc.tpl"
  # Container definition
  cd = {
    name      = "stepca",
    port      = 8888,
    log_group = aws_cloudwatch_log_group.logs.name,
    image     = "smallstep/step-ca:0.25.2",
    mounts = [
      { src = "ca", dest = "/ca", readonly = false },
    ],
    command = [],
    env = [
      { name = "CA_PASSWORD", value = data.sops_file.secrets.data["ca-password"] }
    ],
    secrets = [],
    region  = var.region
  }
  trarn       = data.terraform_remote_state.base.outputs.cd_ter
  tearn       = data.terraform_remote_state.base.outputs.cd_ter
  vpc         = module.vpc.vpc_id
  subnets     = module.vpc.public_subnets
  volume_map  = { ca = data.terraform_remote_state.base.outputs.shared_efs }
  common_tags = {}
}


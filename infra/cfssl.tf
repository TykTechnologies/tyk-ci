# TLS infra provided by cfssl
module "cfssl" {
  source = "../modules/fg-service"
  cluster  = aws_ecs_cluster.internal.arn
  cdt = "templates/cd-awsvpc.tpl"
  # Container definition
  cd = {
    name      = "cfssl",
    port      = 8888,
    log_group = "internal",
    image     = var.cfssl_image,
    command   = ["-port=8888", "-ca=rootca/rootca.pem", "-ca-key=rootca/rootca-key.pem", "-config=config.json", "-responder=rootca/ocsp.pem", "-responder-key=rootca/ocsp-key.pem", "-db-config=db.json", "-loglevel", "1"]
    mounts = [
      { src = "cfssl", dest = "/cfssl", readonly = false },
    ],
    env = [
      { name = "CFSSL_API_KEY", value = var.cfssl_apikey }
    ],
    secrets = [],
    region  = var.region
  }
  tearn       = aws_iam_role.ecs_role.arn
  vpc         = module.vpc.vpc_id
  subnets     = module.vpc.private_subnets
  volume_map  = { cfssl = var.cfssl_efs }
  common_tags = local.common_tags
}


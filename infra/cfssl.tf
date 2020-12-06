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
  trarn       = aws_iam_role.tr.arn
  tearn       = aws_iam_role.tr.arn
  vpc         = module.vpc.vpc_id
  subnets     = module.vpc.public_subnets
  volume_map  = { cfssl = data.terraform_remote_state.base.outputs.cfssl_efs }
  common_tags = local.common_tags
}

# Minimal set of permissions
data "aws_iam_policy_document" "tr" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "tr" {
  name = "cfssl"
  assume_role_policy = data.aws_iam_policy_document.tr.json
}

resource "aws_iam_role_policy_attachment" "tr" {
  role = aws_iam_role.tr.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

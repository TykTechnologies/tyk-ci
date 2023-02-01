# TLS infra provided by step
module "step-ca" {
  source = "../modules/fg-service"
  cluster  = aws_ecs_cluster.internal.arn
  cdt = "templates/cd-awsvpc.tpl"
  # Container definition
  cd = {
    name      = "ca",
    port      = 8888,
    log_group = "internal",
    image     = var.stepca_image,
    command   = [ "--password-file", "<(echo \"$CA_PASSWORD\")" ]
    mounts = [
      { src = "ca", dest = "/home/step", readonly = false },
    ],
    env = [],
    secrets = [
      { name = "CA_PASSWORD", valueFrom = "arn:aws:secretsmanager:eu-central-1:754489498669:secret:CAPassword-UvZ8OG" }
    ],
    region  = var.region
  }
  trarn       = aws_iam_role.tr.arn
  tearn       = aws_iam_role.tr.arn
  vpc         = module.vpc.vpc_id
  subnets     = module.vpc.public_subnets
  volume_map  = { ca = data.terraform_remote_state.base.outputs.ca_efs }
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
  name = "step-ca"
  assume_role_policy = data.aws_iam_policy_document.tr.json
}

resource "aws_iam_role_policy_attachment" "tr" {
  role = aws_iam_role.tr.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

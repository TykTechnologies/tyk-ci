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
    command   = [ "step-ca", "/home/step/config/ca.json", "--password-file", "/home/step/secrets/password" ]
    mounts = [
      { src = "ca", dest = "/home/step", readonly = false },
    ],
    env = [
      { name = "STEPDEBUG", value = "1" }
    ],
    secrets = [
      { name = "CA_PASSWORD", valueFrom = "arn:aws:secretsmanager:eu-central-1:754489498669:secret:CAPassword-UvZ8OG" }
    ],
    region  = var.region
  }
  trarn       = aws_iam_role.ca_tr.arn
  tearn       = aws_iam_role.ca_tr.arn
  vpc         = module.vpc.vpc_id
  subnets     = module.vpc.public_subnets
  volume_map  = { ca = data.terraform_remote_state.base.outputs.ca_efs }
  common_tags = local.common_tags
}

# Task role
resource "aws_iam_role" "ca_tr" {
  name = "step-ca"
  assume_role_policy = data.aws_iam_policy_document.ca_tr.json
}

data "aws_iam_policy_document" "ca_tr" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ca_tr" {
  role = aws_iam_role.ca_tr.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# Task execution role

resource "aws_iam_policy" "ca_ter" {
  name   = "step-ca"
  policy = data.aws_iam_policy_document.ca_ter.json
}

resource "aws_iam_role_policy_attachment" "ca_ter" {
  role       = aws_iam_role.ca_tr.id
  policy_arn = aws_iam_policy.ca_ter.arn
}

data "aws_iam_policy_document" "ca_ter" {
  statement {
    actions = [
      "secretsmanager:*",
      "kms:Decrypt"
    ]
    resources = [
      "arn:aws:kms:eu-central-1:754489498669:key/17432de6-5a75-4a4a-b32e-ff8d8efd277f",
      "arn:aws:secretsmanager:eu-central-1:754489498669:secret:CAPassword-UvZ8OG"
    ]
  }
}
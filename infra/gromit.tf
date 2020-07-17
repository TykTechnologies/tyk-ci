data "template_file" "gromit" {
  template = templatefile("templates/cd-awsvpc.tpl",
    { port=8443,
      name="gromit",
      log_group="internal",
      image=var.gromit_ecr,
      mounts=[
        {src="cfssl", dest="/cfssl"},
        {src="config", dest="/config"}
      ],
      env = [
        {name="GROMIT_TABLENAME", value=aws_dynamodb_table.devenv.name},
        {name="GROMIT_REGISTRYID", value=local.registryid},
        {name="GROMIT_REPOS", value="tyk,tyk-analytics,tyk-pump"}
      ],
      region=var.region } )
}

resource "aws_ecs_task_definition" "gromit" {
  family                   = "gromit"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn
  task_role_arn       = var.gromit_role_arn
  cpu                      = 256
  memory                   = 512

  container_definitions = data.template_file.gromit.rendered 

  volume {
    name = "config"

    efs_volume_configuration {
      file_system_id = var.config_efs
      root_directory = "/"
    }
  }

  volume {
    name = "cfssl"

    efs_volume_configuration {
      file_system_id = var.cfssl_efs
      root_directory = "/gromit/server"
    }
  }

  depends_on = [aws_cloudwatch_log_group.internal]

  tags = local.common_tags
}

resource "aws_security_group" "gromit" {
  name        = "gromit"
  description = "Allow traffic from anywhere"
  vpc_id      = module.vpc.vpc_id


  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "aws_ecs_service" "gromit" {
  name            = "gromit"
  cluster         = aws_ecs_cluster.internal.id
  task_definition = aws_ecs_task_definition.gromit.id
  desired_count   = 1
  launch_type     = "FARGATE"
  # Needed for EFS
  platform_version = "1.4.0"

  network_configuration {
    subnets          = module.vpc.public_subnets
    security_groups  = [ aws_security_group.gromit.id ]
    assign_public_ip = true
  }

  tags = local.common_tags
}

resource "null_resource" "gromit_public_ip" {
  triggers = {
    gromit_service = aws_ecs_service.gromit.id
  }
  depends_on = [ aws_ecs_service.gromit ]
  
  provisioner "local-exec" {
    command = <<EOF
while [ -z $public_ip ]
do
	sleep 20
	public_ip=$(aws ec2 describe-network-interfaces | jq -arcM --arg sg $name '.NetworkInterfaces[] | select(.Groups[].GroupName == $sg) | .Association.PublicIp')
done
export public_ip

aws route53 change-resource-record-sets --hosted-zone-id $hosted_zone --change-batch "$(jq -nMc -f templates/r53-upsert.jq)"
EOF
    environment = {
      name = "gromit"
      fqdn = "gromit.dev.tyk.technology"
      hosted_zone = aws_route53_zone.dev_tyk_tech.zone_id
      region = var.region
    }
  }
}

resource "aws_dynamodb_table" "devenv" {
  name         = "DeveloperEnvironments"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "env"

  attribute {
    name = "env"
    type = "S"
  }

  # Not supported in eu-central-1
  # dynamic "replica" {
  #   for_each = data.aws_availability_zones.available.names
  #   content {
  #     region_name = replica.value
  #   }
  # }

  tags = local.common_tags
}

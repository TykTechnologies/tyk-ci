
module "worker" {
  source = "terraform-aws-modules/ecs/aws//modules/service"

  name                     = "worker"
  cluster_arn              = aws_ecs_cluster.windmill.arn
  assign_public_ip         = false
  requires_compatibilities = ["EC2"]
  launch_type              = "EC2"

  #depends_on = [aws_lb_listener.windmill]

  cpu           = 2048
  memory        = 3072
  desired_count = 1
  container_definitions = {
    windmill-worker = {
      cpu    = 2048
      memory = 3072
      image  = "${local.wmill_image}"

      readonly_root_filesystem = false
      environment = [
        { name = "MODE", value = "worker" },
        { name = "WORKER_GROUP", value = "default" },
        { name = "JSON_FMT", value = "true" }
      ]
      secrets = [
        { name = "DATABASE_URL", valueFrom = data.aws_ssm_parameter.windmill_db_url.arn }
      ]
      log_configuration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "windmill"
          awslogs-region        = "eu-central-1"
          awslogs-stream-prefix = "worker"
        }
      }
    }
  }
  subnet_ids = data.terraform_remote_state.base.outputs.vpc.private_subnets

  create_task_exec_iam_role = false
  create_task_exec_policy   = false
  task_exec_iam_role_arn    = aws_iam_role.windmill.arn
  create_security_group     = false
  security_group_ids        = [aws_security_group.windmill.id]
}

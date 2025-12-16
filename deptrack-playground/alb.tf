# Application Load Balancer

resource "aws_lb" "deptrack" {
  name               = local.name_prefix
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = local.subnet_ids

  enable_deletion_protection = false # Set to true for production

  access_logs {
    bucket  = local.alb_logs_bucket
    prefix  = "alb"
    enabled = var.create_s3_bucket
  }

  tags = {
    Name = local.name_prefix
  }
}

# HTTP Listener (redirects to HTTPS when certificate is available)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.deptrack.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

# Target Groups
resource "aws_lb_target_group" "frontend" {
  name        = "${local.name_prefix}-fe"
  port        = local.dtrack_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = local.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
  }

  deregistration_delay = 30

  tags = {
    Name = "${local.name_prefix}-fe"
  }
}

resource "aws_lb_target_group" "api" {
  name        = "${local.name_prefix}-api"
  port        = local.dtrack_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = local.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/api/version"
    protocol            = "HTTP"
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = {
    Name = "${local.name_prefix}-api"
  }
}

# Listener rules for routing
resource "aws_lb_listener_rule" "frontend" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }

  condition {
    host_header {
      values = ["deptrack.tyk.io"]
    }
  }
}

resource "aws_lb_listener_rule" "api" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }

  condition {
    host_header {
      values = ["api.deptrack.tyk.io"]
    }
  }
}

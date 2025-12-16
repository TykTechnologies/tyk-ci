# Outputs

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.deptrack.dns_name
}

output "alb_url" {
  description = "URL to access DependencyTrack (via ALB DNS)"
  value       = "http://${aws_lb.deptrack.dns_name}"
}

output "api_url" {
  description = "API endpoint URL (via ALB DNS)"
  value       = "http://${aws_lb.deptrack.dns_name}/api"
}

output "custom_dns_frontend" {
  description = "Frontend URL with custom DNS (configure CNAME in Cloudflare)"
  value       = "http://deptrack.tyk.io"
}

output "custom_dns_api" {
  description = "API URL with custom DNS (configure CNAME in Cloudflare)"
  value       = "http://api.deptrack.tyk.io"
}

output "cloudflare_dns_records" {
  description = "DNS records to create in Cloudflare"
  value = {
    frontend = {
      name   = "deptrack.tyk.io"
      type   = "CNAME"
      target = aws_lb.deptrack.dns_name
    }
    api = {
      name   = "api.deptrack.tyk.io"
      type   = "CNAME"
      target = aws_lb.deptrack.dns_name
    }
  }
}

output "rds_endpoint" {
  description = "RDS database endpoint"
  value       = aws_db_instance.deptrack.endpoint
}

output "rds_address" {
  description = "RDS database address"
  value       = aws_db_instance.deptrack.address
}

output "rds_port" {
  description = "RDS database port"
  value       = aws_db_instance.deptrack.port
}

output "efs_id" {
  description = "EFS file system ID"
  value       = aws_efs_file_system.deptrack.id
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.deptrack.name
}

output "kms_key_id" {
  description = "KMS key ID for SSM parameters"
  value       = aws_kms_key.deptrack.id
}

output "ssm_parameter_names" {
  description = "SSM parameter names that need to be created/configured"
  value = {
    master_password = aws_ssm_parameter.db_master_password.name
    db_password     = "/${local.name_prefix}/db_pass"
  }
}

output "database_connection_info" {
  description = "Database connection information for manual setup"
  value = {
    host     = aws_db_instance.deptrack.address
    port     = aws_db_instance.deptrack.port
    database = local.dtrack_db_name
    username = local.dtrack_db_user
    master_user = "master"
  }
}

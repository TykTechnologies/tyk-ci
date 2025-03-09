output "sg_id" {
  value       = aws_security_group.sg.id
  description = "security group id for the task, use in LB"
}

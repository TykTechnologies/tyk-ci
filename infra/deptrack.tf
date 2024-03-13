# Dependency Track

module "deptrack" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name = "deptrack"

  ami                         = data.aws_ami.al2023.id
  instance_type               = "m6a.2xlarge"
  key_name                    = data.terraform_remote_state.base.outputs.key_name
  monitoring                  = true
  vpc_security_group_ids      = [aws_security_group.efs.id, aws_security_group.ssh.id, aws_security_group.egress-all.id]
  subnet_id                   = element(module.vpc.public_subnets, 1)
  associate_public_ip_address = true
  user_data_base64            = data.template_cloudinit_config.deptrack.rendered

  metadata_options = {
    http_tokens = "required" # IMDSv2
  }
}

data "template_cloudinit_config" "deptrack" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.mount_shared.rendered
  }

  part {
    content_type = "text/x-shellscript"
    content      = file("scripts/deptrack-setup.sh")
  }
}

resource "aws_route53_record" "deptrack" {
  zone_id = aws_route53_zone.dev_tyk_tech.zone_id

  name = "deptrack"
  type = "A"
  ttl  = "300"

  records = [module.deptrack.public_ip]
}

# EFS File System for DependencyTrack persistent storage

resource "aws_efs_file_system" "deptrack" {
  creation_token = "${local.name_prefix}-efs"
  encrypted      = true
  kms_key_id     = aws_kms_key.deptrack.arn

  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name = "${local.name_prefix}-efs"
  }
}

# Create mount targets in all subnets
resource "aws_efs_mount_target" "deptrack" {
  count = length(local.subnet_ids)

  file_system_id  = aws_efs_file_system.deptrack.id
  subnet_id       = local.subnet_ids[count.index]
  security_groups = [aws_security_group.efs.id]
}

# Access point for DependencyTrack
resource "aws_efs_access_point" "deptrack" {
  file_system_id = aws_efs_file_system.deptrack.id

  posix_user {
    gid = 1000
    uid = 1000
  }

  root_directory {
    path = "/deptrack"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "755"
    }
  }

  tags = {
    Name = "${local.name_prefix}-access-point"
  }
}

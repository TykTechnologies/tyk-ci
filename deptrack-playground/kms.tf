# KMS Key for encrypting SSM parameters
resource "aws_kms_key" "deptrack" {
  description             = "KMS key for DependencyTrack SSM parameter encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

resource "aws_kms_alias" "deptrack" {
  name          = "alias/${local.name_prefix}-ssm"
  target_key_id = aws_kms_key.deptrack.key_id
}

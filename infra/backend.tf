# Remote state of all dev envs
resource "aws_s3_bucket" "devenv" {
  bucket = "terraform-state-devenv"
  versioning {
    enabled = true
  }
}

resource "aws_dynamodb_table" "devenv_lock" {
  name         = "terraform-state-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}

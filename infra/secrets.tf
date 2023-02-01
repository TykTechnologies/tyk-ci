provider "sops" {}

data "sops_file" "secrets" {
  source_file = "secrets.yaml"
}

resource "aws_secretsmanager_secret" "dash_token" {
  name = "DashTrialToken"
  description = "Auth token to obtain the 30-day trial license for the dashboard"

  tags = local.common_tags
}

resource "aws_secretsmanager_secret" "mdcb_token" {
  name = "MDCBTrialToken"
  description = "Auth token to obtain the 30-day trial license for MDCB"

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "dash_token" {
  secret_id     = aws_secretsmanager_secret.mdcb_token.id
  secret_string = data.sops_file.secrets.data["dashboard-trial"]
}

resource "aws_secretsmanager_secret_version" "mdcb_token" {
  secret_id     = aws_secretsmanager_secret.mdcb_token.id
  secret_string = data.sops_file.secrets.data["mdcb-trial"]
}

resource "aws_secretsmanager_secret" "gromit_serve_key" {
  name = "GromitServeKey"
  description = "The server certificate for gromit serve"

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "gromit_serve_key" {
  secret_id     = aws_secretsmanager_secret.gromit_serve_key.id
  secret_string = data.sops_file.secrets.data["key"]
}


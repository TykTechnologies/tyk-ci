provider "sops" {}

data "sops_file" "licenser_tokens" {
  source_file = "licenser_tokens.yaml"
}

resource "aws_secretsmanager_secret" "dash_token" {
  name = "DashTrialToken"
  description = "Auth token to obtain the 30-day trial license for the dashboard"

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "dash_token" {
  secret_id     = aws_secretsmanager_secret.dash_token.id
  secret_string = data.sops_file.licenser_tokens.data["dashboard-trial"]
}

resource "aws_secretsmanager_secret" "mdcb_token" {
  name = "MDCBTrialToken"
  description = "Auth token to obtain the 30-day trial license for MDCB"

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "mdcb_token" {
  secret_id     = aws_secretsmanager_secret.dash_token.id
  secret_string = data.sops_file.licenser_tokens.data["mdcb-trial"]
}

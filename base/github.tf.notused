provider "github" {
  organization = "TykTechnologies"
}

resource "github_actions_secret" "ecr-keyid" {
  for_each = toset(local.tyk_repos)
  
  repository       = each.key
  secret_name      = "AWS_ACCESS_KEY_ID"
  plaintext_value  = aws_iam_access_key.integration[each.key].id
}

resource "github_actions_secret" "ecr-secret" {
  for_each = toset(local.tyk_repos)
  
  repository       = each.key
  secret_name      = "AWS_SECRET_ACCESS_KEY"
  plaintext_value  = aws_iam_access_key.integration[each.key].secret
}

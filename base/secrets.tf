provider "sops" {}

data "sops_file" "secrets" {
  source_file = "base-secrets.yaml"
}

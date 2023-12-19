provider "sops" {}

data "sops_file" "secrets" {
  source_file = "secrets.yaml"
}

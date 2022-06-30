# resource "random_password" "mongodb_ara_admin" {
#   length           = 16
#   upper            = true
#   lower            = true
#   number           = true
#   special          = true
#   override_special = "!#$&*()-_=[]{}<>?" # Don't allow symbols, which are part of MongoDB conn string
# }

# resource "random_password" "mongodb_ara_dashboard" {
#   length           = 16
#   upper            = true
#   lower            = true
#   number           = true
#   special          = true
#   override_special = "#$*()-_=[]{}<>" # Don't allow symbols, which are part of MongoDB conn string
# }

# resource "random_password" "mongodb_ara_billing" {
#   length           = 16
#   upper            = true
#   lower            = true
#   number           = true
#   special          = true
#   override_special = "#$*()-_=[]{}<>" # Don't allow symbols, which are part of MongoDB conn string
# }

# terraform {
#   required_providers {
#     github = {
#       source  = "integrations/github"
#       version = "~> 6.0"
#     }
#   }
# }


# # Add a user to the organization
# # resource "github_membership" "membership_for_user_x" {
# #   # ...
# # }

# resource "github_repository" "example" {
#   name        = "Terraform"
#   description = "My Terraform codebase"

#   visibility = "public"

#   template {
#     owner                = "github"
#     repository           = "terraform-template-module"
#     include_all_branches = true
#   }
# }
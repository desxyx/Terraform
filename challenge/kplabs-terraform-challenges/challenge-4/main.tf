terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_iam_users" "users" {

}

data "aws_iam_user" "details" {
  for_each  = toset(data.aws_iam_users.users.names)
  user_name = each.value
}

locals {
  user_lines = [
    for u in data.aws_iam_user.details :
    "${u.user_name} | ${u.user_id}"
  ]

  user_text = join("\n", local.user_lines)
}

resource "local_file" "iam_users" {
  filename = "${path.module}/iam_users.txt"
  content = local.user_text
}

data "aws_caller_identity" "current" {
  
}

# resource "aws_iam_user" "lb" {
#   name = "admin-user-${data.aws_caller_identity.current.account_id}"
#   path = "/system/"
# }

# output "usernames" {
#   value = data.aws_iam_users.users.names
# }

# output "total_users" {
#   value = length(data.aws_iam_users.users.names)
# }


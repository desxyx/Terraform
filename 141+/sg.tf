# # # __generated__ by Terraform
# # # Please review these resources and move them into your main configuration files.

# # # __generated__ by Terraform from "sg-0c50e34d2736d5d0d"
# # resource "aws_security_group" "mysg" {
# #   description = "terraform test security group"
# #   egress = [{
# #     cidr_blocks      = ["10.10.10.10/31"]
# #     description      = "SSH only"
# #     from_port        = 22
# #     ipv6_cidr_blocks = []
# #     prefix_list_ids  = []
# #     protocol         = "tcp"
# #     security_groups  = []
# #     self             = false
# #     to_port          = 22
# #   }]
# #   ingress = [{
# #     cidr_blocks      = ["0.0.0.0/0"]
# #     description      = "Http connnection"
# #     from_port        = 80
# #     ipv6_cidr_blocks = []
# #     prefix_list_ids  = []
# #     protocol         = "tcp"
# #     security_groups  = []
# #     self             = false
# #     to_port          = 80
# #     }, {
# #     cidr_blocks      = ["0.0.0.0/0"]
# #     description      = "Https connection"
# #     from_port        = 443
# #     ipv6_cidr_blocks = []
# #     prefix_list_ids  = []
# #     protocol         = "tcp"
# #     security_groups  = []
# #     self             = false
# #     to_port          = 443
# #     }, {
# #     cidr_blocks      = ["0.0.0.0/0"]
# #     description      = "ICMP connection"
# #     from_port        = -1
# #     ipv6_cidr_blocks = []
# #     prefix_list_ids  = []
# #     protocol         = "icmp"
# #     security_groups  = []
# #     self             = false
# #     to_port          = -1
# #   }]
# #   name                   = "tf-test-sg"
# #   region                 = "us-east-1"
# #   revoke_rules_on_delete = null
# #   tags                   = {}
# #   tags_all               = {}
# #   vpc_id                 = "vpc-003118c0d41fa726f"
# # }


# provider "aws" {
#   region = "us-east-1"
# }

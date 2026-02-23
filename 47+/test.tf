provider "aws" {
  region = "us-east-2"
}

# resource "aws_eip" "lb" {
#   domain =  "vpc"
# }

# resource "aws_security_group" "allow_tls" {
#   name = "attribute-sg"
# }

# resource "aws_vpc_security_group_ingress_rule" "allow_tls" {
#   security_group_id = aws_security_group.allow_tls.id

#   cidr_ipv4 = "${aws_eip.lb.public_ip}/32"
#   from_port = 443
#   ip_protocol = "tcp"
#   to_port = 443
# }

# variable "vpn_ip" {
#     default = "1.1.1.1/32"

# }

# resource "aws_instance" "myec2" {
#     ami = "ami-03ea746da1a2e36e7"
#     instance_type = var.types["us-2"]
#     count = 3

#     tags = {
#       name = "devo-team-${count.index}"
#     }
# }


# data "aws_ami" "myimg" {
#   most_recent      = true
#   owners           = ["amazon"]

#   filter {
#     name   = "name"
#     values = ["amzn2-ami-ecs-kernel-5.10-gpu-hvm-i-*"]
#   }

# }

# resource "aws_instance" "myec2" {
#   ami = data.aws_ami.myimg.image_id
#   instance_type = var.environment == "dev" && var.region == "us-east-1" ? "t2.small" : "m5.xlarge"
# }


# resource "local_file" "file_one" {
#   filename = "${path.module}/file_one.txt"
#   content = "This is a test file"
# }

# variable "sg_ports" {
#   type = list(number)
#   default = [ 20,80,8080,3232,1010 ]
# }

# resource "aws_security_group" "test_sg" {
#   name = "test_sg"

#   dynamic "ingress" {
#     for_each = var.sg_ports
#     content {
#       from_port = ingress.value
#       to_port = ingress.value
#       protocol = "tcp"
#       cidr_blocks = ["0.0.0.0/0"]
#     }
#   }
# }

# variable "instance_type" {

# }
# data "aws_ec2_instance_type" "test" {
#   instance_type = var.instance_type
# }
# resource "aws_instance" "test" {
#   lifecycle {
#     ignore_changes        = [image_id, instance_type]
#     create_before_destroy = false
#     prevent_destroy       = false
#     precondition {
#       condition = data.aws_ec2_instance_type.test.free_tier_eligible
#       error_message = "ops"
#     }
#     postcondition {
#       condition = self.public_ip !="1.1.1.1"
#       error_message = "wow"
#     }
#   }
#   depends_on = [var.environment]
# }

# moved {
#   from = aws_instance.test
#   to = aws_instance.test2
# }



# variable "my_set" {
#   type = set(string)
#   # default = [ "1","2","3" ]
# }
# output "my_set" {
#   value = var.my_set
# }

# variable "user_name" {
#   type = set(string)
#   default = [ "Des","John" ,"Bob","Micky","Sue","Sandy","Smith"]
# }

# resource "aws_iam_user" "lb" {
#   for_each = var.user_name
#   name = each.value
# }

# resource "aws_s3_bucket" "test_bucket" {
#   bucket = "te"
# }

# variable "db_password" {
#  type = string
#  validation {
#    condition = length(var.db_password) >= 10
#    error_message = "too short"
#  }
# }

# resource "aws_instance" "myec2" {
#   ami                    = "ami-03ea746da1a2e36e7"
#   instance_type          = "t2.nano"
#   key_name               = "tf_key"
#   vpc_security_group_ids = ["sg-02d0c3257b2b9a0fa"]

#   connection {
#     type        = "ssh"
#     user        = "ec2-user"
#     private_key = file("${path.module}/tf_key.pem")
#     host        = self.public_ip
#   }

#   provisioner "remote-exec" {
#     inline = ["sudo yum -y install nginx",
#     "sudo systemctl start nginx"]
#   }
# }

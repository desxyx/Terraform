
# module "ec2-instance" {
#   source  = "terraform-aws-modules/ec2-instance/aws"
#   version = "6.2.0"
#   subnet_id     = "subnet-03ae9386bc90f085a"
# }

# resource "aws_db_instance" "tf-db" {
#   allocated_storage = 10
#   db_name = "mydb"
#   engine = "mysql"
#   engine_version = "8.0"
#   instance_class = "db.t3.micro"
#   username = "des"
#   # password = "123123123"
#   password = file("./password.txt")
#   parameter_group_name = "default.mysql8.0"
#   skip_final_snapshot = true
# }

# module "s3_bucket" {
#   source = "terraform-aws-modules/s3-bucket/aws"

#   bucket = "my-s3-bucket-for-tf-test"
#   acl    = "private"

#   control_object_ownership = true
#   object_ownership         = "ObjectWriter"

#   versioning = {
#     enabled = true
#   }
# }


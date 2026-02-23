provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias = "au"
  region = "ap-southeast-2"
}

# variable "password" {
#   default = "Mypassw0rd"
#   sensitive = true
# }

/*resource "local_sensitive_file" "password" {
  content = "Mypassword"
  filename = "${path.module}/password.txt"
}

resource "local_file" "test_txt" {
  content = "This is test txt content."
  filename = "${path.module}/test_txt.txt"
}
*/

output "output_test" {
  value = local_file.test_txt.content
}

ephemeral "aws_secretsmanager_random_password" "name" {
  
}
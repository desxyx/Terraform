resource "aws_instance" "myec2"{
  ami = "ami-0532be01f26a3de5"
  instance_type = "t2.micro"
}

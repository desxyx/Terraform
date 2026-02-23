# resource "local_file" "hi_there" {
#   content = "Hi there"
#   filename = "${path.module}/hi.txt"
# }

removed {
  from = local_file.hi_there
  lifecycle {
    destroy = false
  }
}
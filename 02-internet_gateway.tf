resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.main.id
  tags   = merge({ "Name" : "MC-${terraform.workspace}-IGW" }, local.tags)
}

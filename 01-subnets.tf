# Create public subnets
resource "aws_subnet" "public" {
  count                   = local.subnetCount
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 1)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags                    = merge({ "Name" = "MC-${workspace}-PublicSubnet-${count.index + 1}" }, local.tags)
}

# Create private subnets
resource "aws_subnet" "proxy-server-private" {
  count                   = local.subnetCount
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 3)
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags                    = merge({ "Name" : "MC-${workspace}-ProxyServer-PrivateSubnet-${count.index + 1}" }, local.tags)
}

resource "aws_subnet" "web-server-private" {
  count                   = local.subnetCount
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 5)
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags                    = merge({ "Name" : "MC-${workspace}-WebServer-PrivateSubnet-${count.index + 1}" }, local.tags)
}

resource "aws_subnet" "database-private" {
  count                   = local.subnetCount
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 7)
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags                    = merge({ "Name" : "MC-${workspace}-Database-PrivateSubnet-${count.index + 1}" }, local.tags)
}

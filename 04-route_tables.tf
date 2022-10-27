# create route table for the public subnets
resource "aws_route_table" "public-rtb" {
  vpc_id = aws_vpc.main.id
  tags   = merge({ "Name" : "MC-${terraform.workspace}-PublicRouteTable" }, local.tags)
}

# create route for the public route table and attach the internet gateway
resource "aws_route" "public-rtb-route" {
  route_table_id         = aws_route_table.public-rtb.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ig.id
}

# associate all public subnets to the public route table
resource "aws_route_table_association" "public-subnets-assoc" {
  count          = length(aws_subnet.public[*].id)
  subnet_id      = element(aws_subnet.public[*].id, count.index)
  route_table_id = aws_route_table.public-rtb.id
}

####********************************************************#####

# create private route table for web and proxy server
resource "aws_route_table" "web-proxy-server-private-rtb" {
  vpc_id = aws_vpc.main.id
  tags   = merge({ "Name" : "MC-${terraform.workspace}-WebAndProxyServer-PrivateRouteTable" }, local.tags)
}

# create route for the private route table and attach the nat gateway
resource "aws_route" "private_nat_gateway" {
  route_table_id         = aws_route_table.web-proxy-server-private-rtb.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

# associate proxy server private subnets to the private route table
resource "aws_route_table_association" "proxy-server-private-subnets-assoc" {
  count          = length(aws_subnet.proxy-server-private[*].id)
  subnet_id      = element(aws_subnet.proxy-server-private[*].id, count.index)
  route_table_id = aws_route_table.web-proxy-server-private-rtb.id
}

# associate web server private subnets to the private route table
resource "aws_route_table_association" "web-server-private-subnets-assoc" {
  count          = length(aws_subnet.web-server-private[*].id)
  subnet_id      = element(aws_subnet.web-server-private[*].id, count.index)
  route_table_id = aws_route_table.web-proxy-server-private-rtb.id
}

####********************************************************#####

# create private route table for database
resource "aws_route_table" "database-private-rtb" {
  vpc_id = aws_vpc.main.id
  tags   = merge({ "Name" : "MC-${terraform.workspace}-Database-PrivateRouteTable" }, local.tags)
}

# associate database subnets to the private route table
resource "aws_route_table_association" "database-private-subnets-assoc" {
  count          = length(aws_subnet.database-private[*].id)
  subnet_id      = element(aws_subnet.database-private[*].id, count.index)
  route_table_id = aws_route_table.database-private-rtb.id
}

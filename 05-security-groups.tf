# security group for alb, to allow acess from any where for HTTP and HTTPS traffic
resource "aws_security_group" "ext-alb-sg" {
  name        = "MC-${terraform.workspace}-ExternalALB-SG"
  vpc_id      = aws_vpc.main.id
  description = "Allow TLS inbound traffic"

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge({ "Name" : "MC-${terraform.workspace}-ExternalALB-SG" }, local.tags)
}

####********************************************************#####

# security group for bastion, to allow access into the bastion host from you IP
resource "aws_security_group" "bastion-sg" {
  name        = "MC-${terraform.workspace}-Bastion-SG"
  vpc_id      = aws_vpc.main.id
  description = "Allow incoming SSH connections."

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge({ "Name" : "MC-${terraform.workspace}-Bastion-SG" }, local.tags)
}

####********************************************************#####

# security group for proxy server, to allow access only from the external load balancer and bastion instance
resource "aws_security_group" "proxy-server-sg" {
  name   = "MC-${terraform.workspace}-ProxyServer-SG"
  vpc_id = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge({ "Name" : "MC-${terraform.workspace}-ProxyServer-SG" }, local.tags)
}

resource "aws_security_group_rule" "inbound-proxy-server-http" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ext-alb-sg.id
  security_group_id        = aws_security_group.proxy-server-sg.id
}

resource "aws_security_group_rule" "inbound-proxy-server-https" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ext-alb-sg.id
  security_group_id        = aws_security_group.proxy-server-sg.id
}

resource "aws_security_group_rule" "inbound-bastion-ssh" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion-sg.id
  security_group_id        = aws_security_group.proxy-server-sg.id
}

####********************************************************#####

# security group for internal alb, to have access only from nginx reverse proxy server
resource "aws_security_group" "int-alb-sg" {
  name   = "MC-${terraform.workspace}-InternalALB-SG"
  vpc_id = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge({ "Name" : "MC-${terraform.workspace}-InternalALB-SG" }, local.tags)
}

resource "aws_security_group_rule" "inbound-internal-alb-http" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.proxy-server-sg.id
  security_group_id        = aws_security_group.int-alb-sg.id
}

resource "aws_security_group_rule" "inbound-internal-alb-https" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.proxy-server-sg.id
  security_group_id        = aws_security_group.int-alb-sg.id
}

####********************************************************#####

# security group for webservers, to have access only from the internal load balancer and bastion instance
resource "aws_security_group" "webserver-sg" {
  name   = "MC-${terraform.workspace}-Webserver-SG"
  vpc_id = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({ "Name" : "MC-${terraform.workspace}-WebServer-SG" }, local.tags)
}

resource "aws_security_group_rule" "inbound-webserver-http" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.int-alb-sg.id
  security_group_id        = aws_security_group.webserver-sg.id
}

resource "aws_security_group_rule" "inbound-webserver-https" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.int-alb-sg.id
  security_group_id        = aws_security_group.webserver-sg.id
}

resource "aws_security_group_rule" "inbound-web-ssh" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion-sg.id
  security_group_id        = aws_security_group.webserver-sg.id
}

####********************************************************#####

# security group for datalayer to allow traffic from webserver on nfs and mysql port and bastion host on mysql port
resource "aws_security_group" "datalayer-sg" {
  name   = "datalayer-sg"
  vpc_id = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({ "Name" : "MC-${terraform.workspace}-Database-SG" }, local.tags)
}

resource "aws_security_group_rule" "inbound-nfs-port" {
  # Allow for connection to EFS from webservers
  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.webserver-sg.id
  security_group_id        = aws_security_group.datalayer-sg.id
}

resource "aws_security_group_rule" "inbound-mysql-bastion" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion-sg.id
  security_group_id        = aws_security_group.datalayer-sg.id
}

resource "aws_security_group_rule" "inbound-mysql-webserver" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.webserver-sg.id
  security_group_id        = aws_security_group.datalayer-sg.id
}

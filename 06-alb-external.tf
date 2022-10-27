resource "aws_lb" "ext-alb" {
  name     = "MC-${workspace}-ExternalALB"
  internal = false
  security_groups = [
    aws_security_group.ext-alb-sg.id,
  ]

  subnets = [
    aws_subnet.public[0].id,
    aws_subnet.public[1].id
  ]

  tags = merge({ "Name" : "MC-${workspace}-ExternalALB" }, local.tags)

  ip_address_type    = "ipv4"
  load_balancer_type = "application"
}

####********************************************************#####

# Creates Target Group for Proxy Server
resource "aws_lb_target_group" "proxy-server-tg" {
  health_check {
    interval            = 10
    path                = "/"
    protocol            = "HTTPS"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
  name        = "MC-${workspace}-ProxyServer-TG"
  port        = 443
  protocol    = "HTTPS"
  target_type = "instance"
  vpc_id      = aws_vpc.main.id
}

# Creates ALB Listener to point to the proxy server target group
resource "aws_lb_listener" "proxy-server-listener" {
  load_balancer_arn = aws_lb.ext-alb.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate_validation.chisomejim.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.proxy-server-tg.arn
  }
}

####********************************************************#####

output "alb_dns_name" {
  value = aws_lb.ext-alb.dns_name
}

output "alb_target_group_arn" {
  value = aws_lb_target_group.proxy-server-tg.arn
}

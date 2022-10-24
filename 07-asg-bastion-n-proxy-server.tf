#### creating sns topic for all the auto scaling groups
resource "aws_sns_topic" "mc-sns" {
  name = "Default_CloudWatch_Alarms_Topic"
}

resource "aws_autoscaling_notification" "mc-notifications" {
  group_names = [
    aws_autoscaling_group.bastion-asg.name,
    aws_autoscaling_group.proxy-server-asg.name,
    aws_autoscaling_group.wordpress-asg.name,
    aws_autoscaling_group.tooling-asg.name,
  ]
  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
  ]

  topic_arn = aws_sns_topic.mc-sns.arn
}


resource "random_shuffle" "az_list" {
  input = data.aws_availability_zones.available.names
}

resource "aws_launch_template" "bastion-lt" {
  image_id               = var.ubuntu-ami
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.bastion-sg.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ip.id
  }

  key_name = var.keypair

  placement {
    availability_zone = "random_shuffle.az_list.result"
  }

  lifecycle {
    create_before_destroy = true
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge({ "Name" : "MC-Bastion-LaunchTemplate" }, local.tags)
  }

  user_data = filebase64("${path.module}/bin/bastion.sh")
}

# ---- Autoscaling for bastion  hosts

resource "aws_autoscaling_group" "bastion-asg" {
  name                      = "bastion-asg"
  max_size                  = 2
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 1

  vpc_zone_identifier = [
    aws_subnet.public[0].id,
    aws_subnet.public[1].id
  ]

  launch_template {
    id      = aws_launch_template.bastion-lt.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = "MC-Bastion-ASG"
    propagate_at_launch = true
  }

}

# launch template for nginx

resource "aws_launch_template" "proxy-server-lt" {
  image_id               = var.redhat-ami
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.proxy-server-sg.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ip.id
  }

  key_name = var.keypair

  placement {
    availability_zone = "random_shuffle.az_list.result"
  }

  lifecycle {
    create_before_destroy = true
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge({ "Name" : "MC-ProxyServer-LaunchTemplate" }, local.tags)
  }

  user_data = filebase64("${path.module}/bin/nginx.sh")
}

# ------ Autoscaling group for reverse proxy nginx ---------

resource "aws_autoscaling_group" "proxy-server-asg" {
  name                      = "nginx-asg"
  max_size                  = 2
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 1

  vpc_zone_identifier = [
    aws_subnet.proxy-server-private[0].id,
    aws_subnet.proxy-server-private[1].id
  ]

  launch_template {
    id      = aws_launch_template.proxy-server-lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "MC-ProxyServer-ASG"
    propagate_at_launch = true
  }

}

# attaching autoscaling group of proxy server to external load balancer
resource "aws_autoscaling_attachment" "asg-attachment-proxy-server" {
  autoscaling_group_name = aws_autoscaling_group.proxy-server-asg.id
  lb_target_group_arn    = aws_lb_target_group.proxy-server-tg.arn
}

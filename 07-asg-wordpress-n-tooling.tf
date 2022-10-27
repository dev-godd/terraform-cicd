# launch template for wordpress

resource "aws_launch_template" "wordpress-app-lt" {
  image_id               = var.redhat-ami
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.webserver-sg.id]

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

    tags = merge({ "Name" : "MC-${terraform.workspace}-Wordpress-LaunchTemplate" }, local.tags)

  }

  user_data = filebase64("${path.module}/bin/wordpress.sh")
}

# ---- Autoscaling for wordpress application

resource "aws_autoscaling_group" "wordpress-asg" {
  name                      = "wordpress-asg"
  max_size                  = 2
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 1
  vpc_zone_identifier = [

    aws_subnet.web-server-private[0].id,
    aws_subnet.web-server-private[1].id
  ]

  launch_template {
    id      = aws_launch_template.wordpress-app-lt.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = "wordpress-asg"
    propagate_at_launch = true
  }
}

# attaching autoscaling group of wordpress application to internal load balancer
resource "aws_autoscaling_attachment" "asg_attachment_wordpress" {
  autoscaling_group_name = aws_autoscaling_group.wordpress-asg.id
  lb_target_group_arn    = aws_lb_target_group.wordpress-tg.arn
}

# launch template for tooling
resource "aws_launch_template" "tooling-app-lt" {
  image_id               = var.redhat-ami
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.webserver-sg.id]

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

    tags = merge({ "Name" : "MC-${terraform.workspace}-ToolingApp-LaunchTemplate" }, local.tags)
  }

  user_data = filebase64("${path.module}/bin/tooling.sh")
}

# ---- Autoscaling for tooling -----

resource "aws_autoscaling_group" "tooling-asg" {
  name                      = "tooling-asg"
  max_size                  = 2
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 1

  vpc_zone_identifier = [

    aws_subnet.web-server-private[0].id,
    aws_subnet.web-server-private[1].id
  ]

  launch_template {
    id      = aws_launch_template.tooling-app-lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "MC-${terraform.workspace}-ToolingApp-LT"
    propagate_at_launch = true
  }
}

# attaching autoscaling group of  tooling application to internal load balancer
resource "aws_autoscaling_attachment" "asg_attachment_tooling" {
  autoscaling_group_name = aws_autoscaling_group.tooling-asg.id
  lb_target_group_arn    = aws_lb_target_group.tooling-tg.arn
}

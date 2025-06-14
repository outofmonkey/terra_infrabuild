data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_lb" "alb" {
  name               = "test-vpc-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public_subnet[*].id

  tags = {
    Name    = "test-vpc-alb"
    Project = var.project
    Env     = var.env
  }
}

resource "aws_lb_target_group" "web_tg" {
  name     = "test-vpc-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name    = "test-vpc-web-tg"
    Project = var.project
    Env     = var.env
  }
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }

  tags = {
    Name    = "test-vpc-http-listener"
    Project = var.project
    Env     = var.env
  }
}

resource "aws_launch_template" "web_lt" {
  name_prefix            = "test-vpc-web-"
  image_id               = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  user_data              = filebase64("./scripts/user_data.sh")
  key_name               = var.key_name
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name    = "test-vpc-web-instance"
      Project = var.project
      Env     = var.env
    }
  }
}

resource "aws_autoscaling_group" "web_asg" {
  name                      = "test-vpc-web-asg"
  desired_capacity          = 2
  min_size                  = 1
  max_size                  = 4
  vpc_zone_identifier       = aws_subnet.private_subnet[*].id
  target_group_arns         = [aws_lb_target_group.web_tg.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.web_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "test-vpc-web-instance"
    propagate_at_launch = true
  }
  tag {
    key                 = "Project"
    value               = var.project
    propagate_at_launch = true
  }
  tag {
    key                 = "Env"
    value               = var.env
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "web_scaling_policy" {
  name                   = "test-vpc-request-scaling"
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label        = "${aws_lb.alb.arn_suffix}/${aws_lb_target_group.web_tg.arn_suffix}"
    }
    target_value = var.request_count_threshold
  }
}
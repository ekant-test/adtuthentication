resource "aws_lb" "default" {
  name               = "default"
  internal           = true
  load_balancer_type = "application"
  subnets            = [for s in data.aws_subnet.internal_app : s.id]
  security_groups    = [data.aws_security_group.default.id]
}
resource "aws_alb_listener" "default" {
  load_balancer_arn = aws_lb.default.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-FS-1-2-Res-2019-08"
  certificate_arn   = aws_acm_certificate.default.arn
  default_action {
    target_group_arn = aws_lb_target_group.default.id
    type             = "forward"
  }
}
# port 80 will always get redirected to 443
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.default.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      port        = 443
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
resource "aws_lb_target_group" "default" {
  name                 = "default"
  port                 = 443
  protocol             = "HTTPS"
  vpc_id               = data.aws_vpc.default.id
  deregistration_delay = 300
  target_type          = "instance"
  health_check {
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    matcher             = "200-299,301,302,404"
  }
  stickiness {
    enabled = true
    type    = "lb_cookie"
  }
}

resource "aws_autoscaling_group" "default" {
  name                      = "default"
  max_size                  = var.default_server_count + 2
  min_size                  = 2
  health_check_grace_period = 60
  health_check_type         = "EC2"
  desired_capacity          = var.default_server_count
  force_delete              = true
  target_group_arns         = [aws_lb_target_group.default.arn]
  vpc_zone_identifier       = [for s in data.aws_subnet.internal_app : s.id]
  launch_template {
    id      = aws_launch_template.default.id
    version = "$Default"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_template" "default" {
  name_prefix   = "default"
  image_id      = "ami-0dbcc5e3b0f662f48" ## give the image id
  instance_type = var.default_instance_type
  key_name      = "default" ## give the name of ket pair ##
  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = 50
      encrypted   = "true"
    }
  }
  block_device_mappings {
    device_name = "/dev/sdb"
    ebs {
      volume_size = 15
      encrypted   = "true"
    }
  }
  tag_specifications {
    resource_type = "volume"
    tags = merge(
      map(
        "Name", "default"
      ),
      local.common_tags
    )
  }
  tag_specifications {
    resource_type = "instance"
    tags = merge(
      map(
        "Name", "default"
      ),
      local.common_tags
    )
  }
  update_default_version = true
  iam_instance_profile {
    name = "test" ## give the name of instance profile ##
  }
  user_data = base64encode(filebase64("ad-join-userdata.ps1"))

  vpc_security_group_ids = [
    data.aws_security_group.default.id
  ]

  tags = merge(
    local.common_tags,
    map(
      "Name", "default",
    )
  )
  lifecycle {
    create_before_destroy = true
  }
}

resource "null_resource" "portal" {
  depends_on = [
    aws_launch_template.default,
    aws_autoscaling_group.default
  ]
  triggers = {
    instance_refresh = "launch_template_version=${aws_launch_template.default.default_version}"
  }
  provisioner "local-exec" {
    command = "aws autoscaling start-instance-refresh --auto-scaling-group-name ${aws_autoscaling_group.default.name} --strategy Rolling --preferences '{\"InstanceWarmup\": 1200, \"MinHealthyPercentage\": 50}'"
  }
}

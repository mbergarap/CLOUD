resource "aws_launch_template" "worker" {
  name_prefix   = "${var.name}-k3s-worker-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  iam_instance_profile {
    name = var.instance_profile_name
  }
  vpc_security_group_ids = var.security_group_ids

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required" # IMDSv2
  }

  user_data = base64encode(templatefile("${path.module}/user_data_worker.sh.tpl", {
    server_ip   = var.k3s_server_ip
    token_param = var.token_ssm_parameter
    region      = var.aws_region
    k3s_version = var.k3s_version
  }))

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { Name = "${var.name}-k3s-worker" })
  }
}

resource "aws_autoscaling_group" "workers" {
  name                      = "${var.name}-k3s-workers"
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_size
  vpc_zone_identifier       = var.subnet_ids # reparte entre AZ
  target_group_arns         = var.target_group_arns
  health_check_type         = length(var.target_group_arns) > 0 ? "ELB" : "EC2"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.worker.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.name}-k3s-worker"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "cpu" {
  name                   = "${var.name}-workers-cpu-target"
  autoscaling_group_name = aws_autoscaling_group.workers.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.cpu_target
  }
}

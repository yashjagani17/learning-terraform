
provider "aws" {
  region = "eu-west-2"
}

variable "server_port" {
  description = "Port number for the web server"
  type = number
  default = 80
}

data "aws_vpc" "default" {
    default = true
}

data "aws_subnets" "default" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_launch_template" "example" {
  image_id           = "ami-002aab1cab5a08e35"
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              dnf install httpd -y
              echo "Hello World" > /var/www/html/index.html
              sed -i 's/^Listen 80/Listen ${var.server_port}/' /etc/httpd/conf/httpd.conf
              systemctl enable httpd
              systemctl start httpd
              EOF
)

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "name" {
  security_group_id = aws_security_group.instance.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port = var.server_port
  to_port = var.server_port
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "name" {
  security_group_id = aws_security_group.instance.id
  cidr_ipv4 = "0.0.0.0/0"
  ip_protocol = "-1"
}

resource "aws_security_group" "instance" {
    name = "terraform-web-server-cluster-instances"
    vpc_id = data.aws_vpc.default.id
}

resource "aws_autoscaling_group" "example" {
  launch_template {
    id = aws_launch_template.example.id
  }

  min_size = 2
  max_size = 10
  vpc_zone_identifier = data.aws_subnets.default.ids
  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  tag {
    key = "Name"
    value = "terraform-asg-example"
    propagate_at_launch = true
  }
}

resource "aws_lb" "example" {
    name = "terraform-asg-example"
    load_balancer_type = "application"
    subnets = data.aws_subnets.default.ids
    security_groups = [aws_security_group.alb.id]
}

resource "aws_alb_listener" "example" {
  load_balancer_arn = aws_lb.example.arn
  port = 80
  protocol = "HTTP"
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code = 404
    }
  }
}

resource "aws_alb_listener_rule" "asg" {
    listener_arn = aws_alb_listener.example.arn
    priority = 100

    condition {
      path_pattern {
        values = ["*"]
      }
    }  
    action {
      type = "forward"
      target_group_arn = aws_lb_target_group.asg.arn
    }
}

resource "aws_security_group" "alb" {
  name = "terraform-example-alb"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_target_group" "asg" {
  name = "terraform-example-asg"
  port = var.server_port
  protocol = "HTTP"
  vpc_id = data.aws_vpc.default.id

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

output "alb_dns_name" {
  value = aws_lb.example.dns_name
  description = "DNS name of the load balancer"
}
provider "aws" {
  region = "eu-west-2"
}

variable "server_port" {
  description = "The port the server will use for http requests"
  type = number
  default = 80
}

data "aws_vpc" "default" {
    default = true
}

resource "aws_instance" "example" {
  ami           = "ami-002aab1cab5a08e35"
  instance_type = "t3.micro"

  user_data = <<-EOF
              #!/bin/bash
              dnf install httpd -y
              echo "Hello World" > /var/www/html/index.html
              sed -i 's/^Listen 80/Listen ${var.server_port}/' /etc/httpd/conf/httpd.conf
              systemctl enable httpd
              systemctl start httpd
              EOF

  user_data_replace_on_change = true

  vpc_security_group_ids = [aws_security_group.instance.id]

  tags = {
    Name = "terraform-single-web-server-example"
  }
}

resource "aws_security_group" "instance" {
  name = "terraform-single-web-server-instance"
  vpc_id = data.aws_vpc.default.id
}

resource "aws_vpc_security_group_ingress_rule" "instance" {
  security_group_id = aws_security_group.instance.id
  
  cidr_ipv4 = "0.0.0.0/0"
  from_port = var.server_port
  to_port = var.server_port
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "instance" {
  security_group_id = aws_security_group.instance.id

  cidr_ipv4 = "0.0.0.0/0"
  ip_protocol = "-1"
}

output "server_ip_address" {
  value = aws_instance.example.public_ip
  description = "The public ipv4 address of the web server"
}
provider "aws" {
  region = "eu-west-2"
}

resource "aws_instance" "example" {
  ami = "ami-002aab1cab5a08e35"
  instance_type = "t3.micro"

  tags = {
    Name = "terraform-example"
  }
}
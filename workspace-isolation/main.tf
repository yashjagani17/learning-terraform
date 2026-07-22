provider "aws" {
  region = "eu-west-2"
}

terraform {
  backend "s3" {
    bucket = "terraform-up-and-running-state-yash"
    key = "workspaces-example/terraform.tfstate"
    region = "eu-west-2"
    encrypt = true
    use_lockfile = true
    
  }
}

resource "aws_instance" "example" {
  ami = "ami-002aab1cab5a08e35"
  instance_type = terraform.workspace == "default" ? "t3.small" : "t3.micro"
}


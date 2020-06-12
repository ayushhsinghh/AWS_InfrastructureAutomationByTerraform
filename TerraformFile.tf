provider "aws" {
  region                  = "us-east-1"
  shared_credentials_file = "credentials"
}

resource "aws_key_pair" "NewKey" {
  key_name   = "Terraform-key"
  public_key = file("publickey")

}

resource "aws_security_group" "allow_http_ssh" {
  name        = "allow_http_ssh"
  description = "It allow Only http and SSH"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_instance" "NewInstaces" {
  ami             = "ami-098f16afa9edf40be"
  instance_type   = "t2.micro"
  key_name        = aws_key_pair.NewKey.key_name
  security_groups = [aws_security_group.allow_http_ssh.name]

  tags = {
    name = "TerraformOS"
  }
}

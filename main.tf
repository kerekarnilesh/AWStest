
provider "aws" {
  region = var.region != "" ? var.region : "us-east-1"
}


resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}


resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "subnet2" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
}


resource "aws_route_table" "custom_route_table" {
  vpc_id = aws_vpc.my_vpc.id
}


resource "aws_autoscaling_group" "my_asg" {
  name                 = "my-asg"
  launch_configuration = aws_launch_configuration.my_lc.name
  min_size             = 2
  max_size             = 4
  desired_capacity     = 2
  cooldown             = 300
  health_check_type    = "ELB"
}


resource "aws_launch_configuration" "my_lc" {
  name_prefix          = "my-lc-"
  image_id             = "ami-12345678"  
  instance_type        = "t2.micro"    
  security_groups      = [aws_security_group.my_sg.id]
  key_name             = "my-key-pair" 
  user_data            = <<-EOF
                          #!/bin/bash
                          Your user data script here
                          EOF
}


resource "aws_security_group" "my_sg" {
  name        = "my-sg"
  description = "My Security Group"
  vpc_id      = aws_vpc.my_vpc.id
  # Define your security group rules here
}


resource "aws_lb" "my_alb" {
  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"
  enable_deletion_protection = false
  subnets            = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
  enable_http2       = true
}

# Define IAM role for account owner (adjust permissions as needed)
resource "aws_iam_role" "account_owner_role" {
  name = "account-owner-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      }
    }]
  })
}


output "alb_dns_name" {
  value = aws_lb.my_alb.dns_name
}


data "aws_caller_identity" "current" {}

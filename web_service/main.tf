terraform {
  backend "s3" {
    bucket  = "your unique bucket name" # unique bucket name from state_bucket
    key     = "terraform/terraform.tfstate"
    region  = "your region for S3" # region for state from state_region
    encrypt = true
  }
}

provider "aws" {
  region = var.region
}

module "vpc" {
  source          = "terraform-aws-modules/vpc/aws"
  version         = "2.77.0"
  name            = var.proj_name
  cidr            = var.proj_cidr
  azs             = var.proj_azs
  private_subnets = var.proj_private_subnets
  public_subnets  = var.proj_public_subnets

  enable_ipv6 = false
  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    Name = "${var.proj_name}-public"
  }
  private_subnet_tags = {
    Name = "${var.proj_name}-private"
  }

  vpc_tags = {
    Name = "${var.proj_name}-vpc"
  }
}

data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

# resource "aws_instance" "terminal" {
#   ami = data.aws_ami.amazon-linux-2.id
#   instance_type = "t2.micro"
#   vpc_security_group_ids = [module.vpc.default_security_group_id, aws_security_group.terminal.id]
#   subnet_id = module.vpc.public_subnets[0]
#   key_name = "MyKP"
#   tags = {
#     Name = "terminal"
#   }
# }

# resource "aws_security_group" "terminal" {
#   name = "terminal"
#   vpc_id = module.vpc.vpc_id
#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

resource "aws_security_group" "nginx" {
  name = "${var.proj_name}-nginx"
  vpc_id = module.vpc.vpc_id
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.proj_cidr]
  }
}

resource "aws_instance" "test-task-server" {
  ami = data.aws_ami.amazon-linux-2.id
  instance_type = "t2.micro"
  
  vpc_security_group_ids = [
    module.vpc.default_security_group_id, 
    aws_security_group.nginx.id
  ]
  subnet_id = module.vpc.private_subnets[0]
#  key_name = "MyKP"

  user_data = <<-EOF
    #!/bin/bash
    sysctl -w net.ipv6.conf.all.disable_ipv6=1
    sysctl -w net.ipv6.conf.default.disable_ipv6=1
    yum update -y
    yum install -y docker
    service docker start
    docker run -d -p 8080:80 nginx
    EOF

  tags = {
    Name = "${var.proj_name}-server"
  }
}

resource "aws_security_group" "test-task-lb" {
  name = "${var.proj_name}-lb"
  vpc_id = module.vpc.vpc_id
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.proj_cidr]
  }
}

resource "aws_lb" "test-task-lb" {
  name = "${var.proj_name}-lb"
  load_balancer_type = "application"
  subnets = module.vpc.public_subnets
  security_groups = [aws_security_group.test-task-lb.id]
}

resource "aws_lb_listener" "test-task-http" {
  load_balancer_arn = aws_lb.test-task-lb.arn
  port     = 80
  protocol = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: Oops! Something goes wrong"
      status_code  = "404"
    }
  }
}

resource "aws_lb_target_group" "test-task" {
  name = "${var.proj_name}-tg"
  port = 8080
  protocol = "HTTP"
  vpc_id = module.vpc.vpc_id

  health_check {
    path     = "/"
    protocol = "HTTP"
    matcher  = "200"
    interval = 10
    timeout  = 5
  }
}

resource "aws_lb_target_group_attachment" "test-task" {
  target_group_arn = aws_lb_target_group.test-task.arn
  target_id = aws_instance.test-task-server.id
  port = 8080
}

resource "aws_lb_listener_rule" "test-task" {
  listener_arn = aws_lb_listener.test-task-http.arn 
  priority = 100

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.test-task.arn 
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}

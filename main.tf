# Define the AWS provider and region
provider "aws" {
  region = "us-east-1"  # Change this to your preferred region if necessary
}

# Define a variable for the number of instances
# Change this value to set the number of servers
variable "number_of_servers" {
  default     = 3  # Default number of EC2 instances
  description = "The number of EC2 instances to create"
}

# Define an Amazon Linux 2 AMI (free tier eligible)
data "aws_ami" "amazon_linux" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]  # Amazon Linux 2 AMI
  }
  owners = ["amazon"]
}

# Retrieve the default VPC
data "aws_vpc" "default" {
  default = true
}

# Retrieve subnets in the default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Create a security group for the instances
resource "aws_security_group" "web_sg" {
  name        = "web_sg"
  description = "Allow HTTP and SSH traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow SSH from anywhere
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow HTTP traffic
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # Allow all outbound traffic
  }
}

# Provision EC2 instances
resource "aws_instance" "web" {
  count         = var.number_of_servers  # Number of servers (set above)
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"  # Free tier eligible instance type
  security_groups = [aws_security_group.web_sg.name]

  tags = {
    Name = "prod-${count.index + 1}"  # Names each instance as prod-1, prod-2, etc.
  }

  # User data script to install and start a web server
  # Replace this script with your application's setup commands
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y httpd
              sudo systemctl start httpd
              sudo systemctl enable httpd
              echo "Welcome to Prod ${count.index + 1}" > /var/www/html/index.html
              EOF
}

# Output public IPs of the instances
output "instance_ips" {
  value = aws_instance.web[*].public_ip  # Lists the public IPs of all servers
}

# Create an Application Load Balancer
resource "aws_lb" "app_lb" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]
  subnets            = data.aws_subnets.default.ids
  enable_deletion_protection = false
}

# Generate a random string for unique target group naming
resource "random_string" "tg_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Define a target group for the ALB
resource "aws_lb_target_group" "web_tg" {
  name        = "example-tg-${random_string.tg_suffix.result}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "instance"
}

# Attach EC2 instances to the target group
resource "aws_lb_target_group_attachment" "web_tg_attachment" {
  count            = var.number_of_servers
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web[count.index].id
  port             = 80
}

# Define an ALB listener
resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# Output the ALB DNS name
output "alb_dns_name" {
  value = aws_lb.app_lb.dns_name  # ALB DNS name to access the application
}

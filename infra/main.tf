provider "aws" {
  region ="eu-north-1"
}

### DATA ###
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name    = "name"
    values  = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  owners = ["099720109477"] # Canonical
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

###  AWS SECURITY GROUP ###
resource "aws_security_group" "ec2" {
  name        = "securitygroup-ec2"
  description = "Allow HTTP inbound"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "alb" {
  name        = "securitygroup-alb"
  description = "Allow HTTP inbound for ALB"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


### LOAD BALANCER ###
resource "aws_lb" "app" {
  name               = "app-alb"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
  security_groups    = [aws_security_group.alb.id]
}

### TARGET GROUPS ### 
resource "aws_lb_target_group" "blue" {
  name     = "tg-blue"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path = "/health"
  }
}

resource "aws_lb_target_group" "green" {
  name     = "tg-green"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path = "/health"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn ### to change w/ github actions
  }
}

###  EC2  ###
resource "aws_instance" "app-blue"{
  ami             = data.aws_ami.ubuntu.id
  instance_type   = var.instance_type
  subnet_id = data.aws_subnets.default.ids[0]
  security_groups = [aws_security_group.ec2.id]

  user_data = file("setup-docker.sh")
  # user_data = <<-EOF
  #            #!/bin/bash
  #            sudo apt-get update
  #            sudo apt-get install -y nginx
  #            sudo systemctl start nginx
  #            sudo systemctl enable nginx
  #            echo '<!doctype html>
  #            <html lang="en"><h1>Images!</h1></br>
  #            <h3>(Instance BLUE)</h3>
  #            </html>' | sudo tee /var/www/html/index.html
  #            echo 'server {
  #                      listen 80 default_server;
  #                      listen [::]:80 default_server;
  #                      root /var/www/html;
  #                      index index.html index.htm index.nginx-debian.html;
  #                      server_name _;
  #                      location /images/ {
  #                          alias /var/www/html/;
  #                          index index.html;
  #                      }
  #                      location / {
  #                          try_files $uri $uri/ =404;
  #                      }
  #                  }' | sudo tee /etc/nginx/sites-available/default
  #            sudo systemctl reload nginx
  #            EOF

  tags = {
    Name = "app-blue"
  }
}

resource "aws_instance" "app-green"{
  ami             = data.aws_ami.ubuntu.id
  instance_type   = var.instance_type
  subnet_id       = data.aws_subnets.default.ids[0]
  security_groups = [aws_security_group.ec2.id]

  user_data = file("setup-docker.sh")
  # user_data = <<-EOF
  #            #!/bin/bash
  #            sudo apt-get update
  #            sudo apt-get install -y nginx
  #            sudo systemctl start nginx
  #            sudo systemctl enable nginx
  #            echo '<!doctype html>
  #            <html lang="en"><h1>Images!</h1></br>
  #            <h3>(Instance Green)</h3>
  #            </html>' | sudo tee /var/www/html/index.html
  #            echo 'server {
  #                      listen 80 default_server;
  #                      listen [::]:80 default_server;
  #                      root /var/www/html;
  #                      index index.html index.htm index.nginx-debian.html;
  #                      server_name _;
  #                      location /images/ {
  #                          alias /var/www/html/;
  #                          index index.html;
  #                      }
  #                      location / {
  #                          try_files $uri $uri/ =404;
  #                      }
  #                  }' | sudo tee /etc/nginx/sites-available/default
  #            sudo systemctl reload nginx
  #            EOF

  tags = {
    Name = "app-green"
  }
}


### ADD STATE LOCK #### 

terraform {
  backend "s3" {
    bucket         = "surprise-terraform-state"
    key            = "blue-green/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

###  ATTATCHMENT TO LB  ###
resource "aws_lb_target_group_attachment" "blue" {
  target_group_arn = aws_lb_target_group.blue.arn
  target_id        = aws_instance.app-blue.id
  port             = 8080
}

resource "aws_lb_target_group_attachment" "green" {
  target_group_arn = aws_lb_target_group.green.arn
  target_id        = aws_instance.app-green.id
  port             = 8080
}
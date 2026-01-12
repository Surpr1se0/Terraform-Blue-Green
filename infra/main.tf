provider "aws" {
  region ="eu-north-1"
}

### LOAD BALANCER ###
resource "aws_lb" "app" {
  name                = "app-lb"
  load_balancer_type  = "application"
  subnets             = data.aws_subnets.default.ids
  security_groups     = [aws_security_group.alb.id]
}


### TARGET GROUPS ### 
resource "aws_lb_target_group" "blue" { ## blue
  name        = "tg-blue"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
}


resource "aws_lb_target_group" "green" { ## green
  name        = "tg-green"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
}

### LB LISTENER ### 
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn # for now
  }
}
resource "aws_lb" "My_ALB" {  
  name               = "My-ALB"  
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["sg-05a7764c699471d6b"]
  subnets            = data.aws_subnet_ids.all.ids
  ip_address_type    = "ipv4"
  tags = {
    Name   =   "My_ALB"
  } 
}

resource "aws_lb_listener" "alb_listener" {  
  load_balancer_arn = aws_lb.My_ALB.arn  
  port              = "80"
  protocol          = "HTTP"
  
  default_action {   
    target_group_arn = aws_lb_target_group.ALB_TG.arn
    type             = "forward"  
  }
}


#Use the commented block below to configure additionnal listener rule
/* resource "aws_lb_listener_rule" "ALB_listener" {
  depends_on   = aws_lb_target_group.ALB_TG
  listener_arn = aws_lb_listener.alb_listener.arn
  priority     = 100   
  action {    
    type             = "forward"    
    target_group_arn = aws_ab_target_group.ALB_TG.id  
  }   
  condition {    
    field  = "path-pattern"    
    values = ["${var.alb_path}"]  
  }
} */

resource "aws_lb_target_group" "ALB_TG" {  
  name     = "ALB-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
  tags = {    
    name = "ALB_TG"   
  }

  #use the block below to configure stickiness
  /* stickiness {    
    type            = "lb_cookie"    
    cookie_duration = 1800    
    enabled         = true 
  }    */

  health_check {
    path = "/"
    port = 80
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 2
    interval = 10
    matcher = "200"
  }
}

#output handling
output "ALB_DNS" {
  value = aws_lb.My_ALB.dns_name
}

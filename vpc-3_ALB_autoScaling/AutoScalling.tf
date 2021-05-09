resource "aws_launch_template" "My_template" {
  name_prefix   = "My_template"
  image_id      = "ami-0c94855ba95c71c99"
  instance_type = "t2.micro"
  key_name      = "KeyPair"
  vpc_security_group_ids   = ["sg-0b3a9411551582605"]
  user_data = filebase64("install_apache.sh")
  
  #if you would like to add extra volume to the launched instance use the block below
  /* block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = 10
      delete_on_termination = true
    }
  } */
}

#use the resource block below if you would like to use launch configuration instead.
/* resource "aws_launch_configuration" "My_LC" {
  name_prefix   = "My_LC"
  image_id      = data.aws_ami.centos.id
  instance_type = "t2.micro"
  key_name      = "KeyPair"
  security_groups   = ["WebDMZ"]
  user_data = <<EOF
        #! /bin/bash
        sudo yum update -y
        sudo yum install httpd -y
        sudo systemctl start httpd
        sudo systemctl enable httpd
        sudo mkdir -p /var/www/html/
        echo "<h1>Welcome! Server. This is served by the ALB</h1>" | sudo tee /var/www/html/index.html
  EOF
  lifecycle {
    create_before_destroy = true
  }
} */

resource "aws_autoscaling_group" "My_ASG" {
  name                 = "My_ASG"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1e"]
  desired_capacity   = 2
  max_size           = 4
  min_size           = 2
  depends_on = [aws_lb.My_ALB]
  wait_for_capacity_timeout = 0
  health_check_grace_period = 60
  health_check_type    = "ELB"
  launch_template {
    id      = aws_launch_template.My_template.id
    version = "$Latest"
  }
  #enable the line below for ASG to use launch configuration
  # launch_configuration = aws_launch_configuration.My_LC.name

  target_group_arns = [aws_lb_target_group.ALB_TG.arn]
}

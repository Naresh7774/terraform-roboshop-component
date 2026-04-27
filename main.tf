# Create EC2 instance
resource "aws_instance" "main" {
    ami = local.ami_id
    instance_type = "t3.micro"
    vpc_security_group_ids = [local.sg_id]
    subnet_id = local.private_subnet_id
    
    tags = merge (
        local.common_tags,
        {
            Name = "${local.common_name_suffix}-${var.component}" # roboshop-dev-mongodb
        }
    )
}


resource "terraform_data" "main" {
  triggers_replace = [
    aws_instance.main.id
  ]
  
  connection {
    type     = "ssh"
    user     = "ec2-user"
    password = "DevOps321"
    host     = aws_instance.main.private_ip
  }

  provisioner "file" {
    source = "bootstrap.sh"
    destination = "/tmp/bootstrap.sh"
  }

  provisioner "remote-exec" {
    inline = [
        "chmod +x /tmp/bootstrap.sh",
        "sudo sh /tmp/bootstrap.sh ${var.component} ${var.environment}"
    ]
  }
}

resource "aws_ec2_instance_state" "main" {
  instance_id = aws_instance.main.id
  state       = "stopped"
  depends_on = [terraform_data.main]
}

resource "aws_ami_from_instance" "main" {
  name               = "${local.common_name_suffix}-${var.component}-ami"
  source_instance_id = aws_instance.main.id
  depends_on = [aws_ec2_instance_state.main]
  tags = merge (
        local.common_tags,
        {
            Name = "${local.common_name_suffix}-${var.component}-ami" # roboshop-dev-mongodb
        }
  )
}

resource "aws_lb_target_group" "main" {
  name     = "${local.common_name_suffix}-${var.component}"
  port     = local.tg_port # if frontend port is 80, otherwise port is 8080
  protocol = "HTTP"
  vpc_id   = local.vpc_id
  deregistration_delay = 60 # waiting period before deleting the instance

  health_check {
    healthy_threshold = 2
    interval = 10
    matcher = "200-299"
    path = local.health_check_path
    port = local.tg_port
    protocol = "HTTP"
    timeout = 2
    unhealthy_threshold = 2
  }
}

resource "aws_launch_template" "main" {
  name = "${local.common_name_suffix}-${var.component}"
  image_id = aws_ami_from_instance.main.id

  instance_initiated_shutdown_behavior = "terminate"
  instance_type = "t3.micro"

  vpc_security_group_ids = [local.sg_id]

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket         = "drohealth-tf-state"
    key            = "vpc/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "test_EHR_tf_lock_db"
  }
}


terraform {
  backend "s3" {
    bucket         = "drohealth-tf-state"
    key            = "compute/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "test_EHR_tf_lock_db"
  }
}


#key pair
resource "aws_key_pair" "id_rsa" {
  key_name   = "id_rsa"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDA3ANB5W074m7U1lW5+c/nelwEYybRtVZVpp2v6tzhoECRzIHABx8YcoynvU3YUcRONV6FT9uaIOJ4sIojV9xcNlNPTzy/NEzje8cSOgoH/A3ZnAmpcA1s2ZBTsH8sMsyOS4F5yPIaKicTw7axKCi5PjQeXb5cjjA8VMehxFKggfEqZcNLm4UlLCh64wKlVSmqUeU3d53r5j5UUDSbhHkWSrMHv2i9ifIKgGvW69IjwwNDv1t5ImPENa4qRKYudSFDhify8K7/HFdMTg4HJspxyhDK5EiAqP45FzRBE07iC3kU/e0DaCnMtdM29lMq/a10sDDvHO9cd8SznCL62jIV jamin@Lorenzo"
}

#EC2 Code Deploy role
resource "aws_iam_role" "ec2_codedeploy_role" {
  name = "ec2_codedeploy_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    Name = "ec2_codedeploy_role"
  }

}


resource "aws_iam_role_policy_attachment" "ec2_fullaccess_attach" {
  role       = aws_iam_role.ec2_codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}


resource "aws_iam_instance_profile" "ec2_cd_instance_profile" {
  name = "ec2_cd_instance_profile"
  role = aws_iam_role.ec2_codedeploy_role.name
}


# EC2
resource "aws_instance" "test_EHR" {
  ami                         = "ami-0778521d914d23bc1"
  instance_type               = "t2.medium"
  subnet_id                   = data.terraform_remote_state.vpc.outputs.vpc_public_subnets[0]
  vpc_security_group_ids      = ["${aws_security_group.test_EHR_EC2_sg.id}"] #"aws_security_group.DroHealth_sg.id" 
  associate_public_ip_address = true
  key_name                    = "id_rsa"
  tags = {
    Name = "test_EHR"
  }
  iam_instance_profile = aws_iam_instance_profile.ec2_cd_instance_profile.name
  user_data            = file("codedeploy_agent_install.sh")
  lifecycle {
    create_before_destroy = true
  }
}
 
#.................................................Security Group
resource "aws_security_group" "test_EHR_EC2_sg" {
  name        = "test_EHR_EC2_sg"
  description = "ssh"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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
  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_security_group" "test_EHR_alb_sg" {
  name        = "test_EHR_lb_sg"
  description = "Application Load Balancer security group"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id
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

  lifecycle {
    create_before_destroy = true
  }
}


#..............................................ALB Target Group
resource "aws_lb_target_group" "test-ehr-tg" {
  name     = "test-ehr-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.vpc.outputs.vpc_id
}


#................................................ALB
resource "aws_lb" "test-EHR-lb" {
  name                             = "test-EHR-lb"
  internal                         = false
  load_balancer_type               = "application"
  security_groups                  = [aws_security_group.test_EHR_alb_sg.id]
  subnets                          = data.terraform_remote_state.vpc.outputs.vpc_public_subnets
  enable_cross_zone_load_balancing = true

  tags = {
    Name = "test_EHR_lb"
  }
}


#......................ALB Listener
resource "aws_lb_listener" "test_EHR_listener" {
  load_balancer_arn = aws_lb.test-EHR-lb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.test-ehr-tg.arn
  }
}



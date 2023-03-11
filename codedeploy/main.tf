data "terraform_remote_state" "vpc" {
  backend = "s3"
    config = {
        bucket = "drohealth-tf-state"
        key = "vpc/terraform.tfstate"
        region = "us-east-1"
        dynamodb_table = "test_EHR_tf_lock_db"
    }
}


data "terraform_remote_state" "compute" {
    backend = "s3"
    config = {
        bucket = "drohealth-tf-state"
        key = "compute/terraform.tfstate"
        region = "us-east-1"
        dynamodb_table = "test_EHR_tf_lock_db"
    }
}


terraform {
  backend "s3" {
    bucket         = "drohealth-tf-state"
    key            = "codedeploy/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "test_EHR_tf_lock_db"
  }
}


#AWS Code Deploy role
resource "aws_iam_role" "codedeploy_role" {
  name = "codedeploy_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "codedeploy.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags = {
    Name = "codedeploy_role"
  }


}

resource "aws_iam_role_policy_attachment" "AWSCodeDeployRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
  role       = aws_iam_role.codedeploy_role.name
}


resource "aws_codedeploy_app" "test_EHR" {
  name             = "test_EHR"
  compute_platform = "Server"
}


resource "aws_sns_topic" "test_EHR_topic" {
  name = "test_EHR_topic"
}


resource "aws_codedeploy_deployment_group" "test_EHR_group" {
  app_name              = aws_codedeploy_app.test_EHR.name
  deployment_group_name = "test_EHR_group"
  service_role_arn      = aws_iam_role.codedeploy_role.arn
  deployment_config_name = "CodeDeployDefault.OneAtATime"
  deployment_style {
    # deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type = "IN_PLACE"

    # load_balancer_info {
    #   # elb_info {
    #   #   name = aws_lb.test_EHR_lb.name
    #   # }
    #   target_group_info {
    #     name = aws_lb_target_group.test_EHR_tg.name
    #   }
    # }  
    }

  ec2_tag_set {
    ec2_tag_filter {
      key   = "Name"
      type  = "KEY_AND_VALUE"
      value = "test_EHR"
    }

  }
  trigger_configuration {
    trigger_events     = ["DeploymentFailure", "DeploymentSuccess"]
    trigger_name       = "event-trigger"
    trigger_target_arn = aws_sns_topic.test_EHR_topic.arn
  }

  auto_rollback_configuration {
    enabled = false
    events  = ["DEPLOYMENT_FAILURE"]
  }

  alarm_configuration {
    alarms  = ["my-alarm-name"]
    enabled = true
  }

}
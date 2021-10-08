resource "aws_autoscaling_lifecycle_hook" "default" {
  name                   = "default"
  autoscaling_group_name = aws_autoscaling_group.default.name
  default_result         = "ABANDON"
  heartbeat_timeout      = 300
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_TERMINATING"
}

resource "aws_cloudwatch_event_rule" "default_event_rule" {
  name        = "default"
  description = "EC2 Instance-terminate Lifecycle Action"
  event_pattern = jsonencode(
    {
      "source" : [
        "aws.autoscaling"
      ],
      "detail-type" : [
        "EC2 Instance-terminate Lifecycle Action"
      ],
      "detail" : {
        "AutoScalingGroupName" : [
          aws_autoscaling_group.default.name
        ]
      }
    }
  )
}


resource "aws_cloudwatch_event_target" "default_target" {
  target_id = "default"
  arn       = "arn:aws:ssm:ap-southeast-2:${local.account_id}:automation-definition/ad-domain-unjoin:$DEFAULT"
  rule      = aws_cloudwatch_event_rule.default_event_rule.name
  role_arn  = aws_iam_role.cloudwatch_event.arn
  input_transformer {
    input_paths = {
      instance = "$.detail.EC2InstanceId"
    }
    input_template = <<EOF
{"terminatingId":[<instance>]}
EOF
  }
}

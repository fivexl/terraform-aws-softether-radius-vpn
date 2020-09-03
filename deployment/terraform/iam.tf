data "aws_iam_policy_document" "vpn" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:CreateLogGroup"
    ]
    resources = [
      aws_cloudwatch_log_group.rserver.arn,
      aws_cloudwatch_log_group.vpn_server_log.arn,
      aws_cloudwatch_log_group.vpn_security_log.arn
    ]
  }
  statement {
    actions = [
      "logs:PutLogEvents"
    ]
    resources = [
      "${aws_cloudwatch_log_group.rserver.arn}:log-stream:*",
      "${aws_cloudwatch_log_group.vpn_server_log.arn}:log-stream:*",
      "${aws_cloudwatch_log_group.vpn_security_log.arn}:log-stream:*"
    ]
  }
}

data "aws_iam_policy_document" "trust" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "this" {
  name               = var.project_name
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.trust.json
}

resource "aws_iam_role_policy" "this" {
  name   = var.project_name
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.vpn.json
}

resource "aws_iam_instance_profile" "this" {
  name = var.project_name
  role = aws_iam_role.this.name
}

data "aws_iam_policy_document" "vpn" {

  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
      "logs:CreateLogGroup"
    ]

    resources = ["${aws_cloudwatch_log_group.rserver.arn}",
                 "${aws_cloudwatch_log_group.rserver.arn}:log-stream:*",
                 "${aws_cloudwatch_log_group.vpn_server_log.arn}",
                 "${aws_cloudwatch_log_group.vpn_server_log.arn}:log-stream:*",
                 "${aws_cloudwatch_log_group.vpn_security_log.arn}",
                 "${aws_cloudwatch_log_group.vpn_security_log.arn}:log-stream:*"]
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

resource "aws_iam_role" "vpn" {
  name               = "softether-radius-vpn"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.trust.json
}

resource "aws_iam_role_policy" "vpn" {
  name   = "softether-radius-vpn"
  role   = aws_iam_role.vpn.id
  policy = data.aws_iam_policy_document.vpn.json
}

resource "aws_iam_instance_profile" "vpn" {
  name = "softether-radius-vpn"
  role = aws_iam_role.vpn.name
}

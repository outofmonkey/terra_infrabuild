resource "aws_iam_role" "ec2_role" {
  name = "test-vpc-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "test-vpc-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_cloudwatch_log_group" "web_access_logs" {
  name              = "/aws/ec2/webserver/access_logs"
  retention_in_days = 7

  tags = {
    Name    = "test-vpc-web-access-log-group"
    Project = var.project
    Env     = var.env
  }
}

resource "aws_cloudwatch_log_group" "web_error_logs" {
  name              = "/aws/ec2/webserver/error_logs"
  retention_in_days = 7

  tags = {
    Name    = "test-vpc-web-error-log-group"
    Project = var.project
    Env     = var.env
  }
}

resource "aws_cloudwatch_log_group" "bastion_secure_logs" {
  name              = "/aws/ec2/bastion/secure_logs"
  retention_in_days = 7

  tags = {
    Name    = "test-vpc-bastion-secure-log-group"
    Project = var.project
    Env     = var.env
  }
}
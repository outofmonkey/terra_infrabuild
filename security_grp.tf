resource "aws_security_group" "alb_sg" {
  name        = "test-vpc-alb-sg"
  description = "Allow inbound HTTP and HTTPS traffic for ALB"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "test-vpc-alb-sg"
    Project = var.project
    Env     = var.env
  }
}

resource "aws_security_group" "bastion_sg" {
  name        = "test-vpc-bastion-sg"
  description = "Allow inbound SSH traffic for Bastion host"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "test-vpc-bastion-sg"
    Project = var.project
    Env     = var.env
  }
}

resource "aws_security_group" "web_sg" {
  name        = "test-vpc-web-sg"
  description = "Allow inbound traffic from ALB and SSH from Bastion"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "test-vpc-web-sg"
    Project = var.project
    Env     = var.env
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "test-vpc-rds-sg"
  description = "Allow inbound MySQL traffic from web instances"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "test-vpc-rds-sg"
    Project = var.project
    Env     = var.env
  }
}
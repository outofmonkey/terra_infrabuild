data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "vpc" {
  cidr_block           = "10.100.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"

  tags = {
    Name    = "test-vpc"
    Project = var.project
    Env     = var.env
  }
}

resource "aws_subnet" "public_subnet" {
  count                   = 2
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.100.${count.index}.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name    = "test-vpc-public_subnet_${count.index + 1}"
    Project = var.project
    Env     = var.env
  }
}

resource "aws_subnet" "private_subnet" {
  count                   = var.private_subnet_count
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.cidr_block_private[count.index]
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]

  tags = {
    Name    = "test-vpc-private_subnet_${count.index + 1}"
    Project = var.project
    Env     = var.env
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name    = "test-vpc-igw"
    Project = var.project
    Env     = var.env
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name    = "test-vpc-public_rt"
    Project = var.project
    Env     = var.env
  }

  depends_on = [aws_internet_gateway.igw, aws_subnet.public_subnet]
}

resource "aws_route_table_association" "public_rt_association" {
  count          = 2
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_rt.id

  tags = {
    Name    = "test-vpc-public_rt_association_${count.index + 1}"
    Project = var.project
    Env     = var.env
  }

  depends_on = [aws_route_table.public_rt, aws_subnet.public_subnet]
}

resource "aws_eip" "nateip" {
  domain = "vpc"

  tags = {
    Name    = "test-vpc-nat_eip"
    Project = var.project
    Env     = var.env
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nateip.id
  subnet_id     = aws_subnet.public_subnet[0].id

  tags = {
    Name    = "test-vpc-nat_gateway"
    Project = var.project
    Env     = var.env
  }

  depends_on = [aws_eip.nateip, aws_subnet.public_subnet]
}

resource "aws_route_table" "nat_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name    = "test-vpc-nat_pvt_rt"
    Project = var.project
    Env     = var.env
  }
}

resource "aws_route_table_association" "private_rt_association" {
  count          = var.private_subnet_count
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.nat_rt.id

  tags = {
    Name    = "test-vpc-private_rt_association_${count.index + 1}"
    Project = var.project
    Env     = var.env
  }

  depends_on = [aws_route_table.nat_rt, aws_subnet.private_subnet]
}

resource "aws_s3_bucket" "vpc_flow_logs_bucket" {
  bucket = "test-vpc-flow-logs-${random_string.bucket_suffix.result}"

  tags = {
    Name    = "test-vpc-flow-logs-bucket"
    Project = var.project
    Env     = var.env
  }
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_policy" "vpc_flow_logs_policy" {
  bucket = aws_s3_bucket.vpc_flow_logs_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSLogDeliveryWrite"
        Effect    = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action    = ["s3:PutObject"]
        Resource  = "${aws_s3_bucket.vpc_flow_logs_bucket.arn}/AWSLogs/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Sid       = "AWSLogDeliveryAclCheck"
        Effect    = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action    = ["s3:GetBucketAcl"]
        Resource  = aws_s3_bucket.vpc_flow_logs_bucket.arn
      }
    ]
  })
}

resource "aws_flow_log" "vpc_flow_log" {
  vpc_id               = aws_vpc.vpc.id
  traffic_type         = "ALL"
  log_destination      = aws_s3_bucket.vpc_flow_logs_bucket.arn
  log_destination_type = "s3"
  destination_options {
    file_format        = "plain-text"
    per_hour_partition = true
  }

  tags = {
    Name    = "test-vpc-flow-log"
    Project = var.project
    Env     = var.env
  }
}
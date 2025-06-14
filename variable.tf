variable "project" {
  default     = "nextcloud"
  description = "Project name for tagging resources"
  type        = string
}

variable "env" {
  default     = "testing"
  description = "Environment name for tagging resources"
  type        = string
}

variable "request_count_threshold" {
  default     = 10
  description = "HTTP request count per minute to trigger auto scaling"
  type        = number
}

variable "private_subnet_count" {
  default     = 3
  description = "Number of private subnets to create (minimum 3)"
  type        = number
  validation {
    condition     = var.private_subnet_count >= 3
    error_message = "The number of private subnets must be 3 or more."
  }
}

variable "cidr_block_private" {
  type        = list(string)
  default     = ["10.100.1.0/24", "10.100.2.0/24", "10.100.3.0/24"]
  description = "List of CIDR blocks for private subnets, must match private_subnet_count and be within VPC CIDR (10.100.0.0/16)"
  validation {
    condition     = length(var.cidr_block_private) >= 3
    error_message = "The number of private subnet CIDR blocks must be at least 3."
  }
  validation {
    condition     = alltrue([for cidr in var.cidr_block_private : can(cidrsubnet(cidr, 0, 0))])
    error_message = "All private subnet CIDR blocks must be valid."
  }
  validation {
    condition     = alltrue([
      for cidr in var.cidr_block_private : contains([
        for i in range(256) : cidrsubnet("10.100.0.0/16", 8, i)
      ], cidr)
    ])
    error_message = "All private subnet CIDR blocks must be within the VPC CIDR (10.100.0.0/16)."
  }
}

variable "admin_cidr_block" {
  default     = "0.0.0.0/0"
  description = "CIDR block allowed to SSH into the Bastion host"
  type        = string
}

variable "key_name" {
  description = "Name of the SSH key pair to use for instances"
  type        = string
  default     = "aws-key-pair"
}

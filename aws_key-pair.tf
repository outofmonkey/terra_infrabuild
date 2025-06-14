resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "aws_key" {
  key_name   = "aws-key-pair"
  public_key = tls_private_key.key.public_key_openssh

  tags = {
    Name = "aws-key-pair"
  }
}

resource "local_file" "key_file" {
  content         = tls_private_key.key.private_key_pem
  filename        = "./aws_keyring/aws_key_pair.pem"
  file_permission = "0600"
}

output "private_key_file" {
  value       = abspath(local_file.key_file.filename)
  sensitive   = true
  description = "Path to store the private key file."
}
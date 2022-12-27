# Generate Key pair for master
resource "tls_private_key" "key_pair_master" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key_master" {
  provider   = aws.region_master
  key_name   = "${var.intance_key_name}-master"
  public_key = tls_private_key.key_pair_master.public_key_openssh
}

resource "local_file" "private_key_master" {
  content         = tls_private_key.key_pair_master.private_key_pem
  filename        = "../ansible/${var.intance_key_name}-master.pem"
  file_permission = "600"
}

# Generate Key pair for worker
resource "tls_private_key" "key_pair_worker" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key_worker" {
  provider   = aws.region_worker
  key_name   = "${var.intance_key_name}-worker"
  public_key = tls_private_key.key_pair_worker.public_key_openssh
}

resource "local_file" "private_key_worker" {
  content         = tls_private_key.key_pair_worker.private_key_pem
  filename        = "../ansible/${var.intance_key_name}-worker.pem"
  file_permission = "600"
}
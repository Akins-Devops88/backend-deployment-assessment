# Retrieve the latest Ubuntu 24.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Bastion Host - Public Subnet
resource "aws_instance" "bastion" {
  ami                         = "ami-02a9cdd4e98bc3c78"
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_a.id
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_size = 10
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    http_tokens = "required"
  }

  tags = {
    Name = "${var.project_name}-bastion"
  }
}

# MongoDB Server - Private Subnet
resource "aws_instance" "mongodb" {
  depends_on = [
    aws_route_table_association.private_b,
    aws_iam_role_policy.mongodb_ssm
  ]
  iam_instance_profile        = aws_iam_instance_profile.mongodb.name
  user_data                   = file("${path.module}/user_data/mongodb_setup.sh")
  ami                         = "ami-02a9cdd4e98bc3c78"
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private_b.id
  vpc_security_group_ids      = [aws_security_group.mongodb.id]
  key_name                    = var.key_name
  associate_public_ip_address = false
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    http_tokens = "required"
  }

  tags = {
    Name = "${var.project_name}-mongodb"
  }
}

# Backend Server - Private Subnet
resource "aws_instance" "backend" {
  depends_on = [
    aws_route_table_association.private_a,
    aws_iam_role_policy.backend_ssm,
    aws_iam_role_policy.backend_ecr
  ]
  iam_instance_profile = aws_iam_instance_profile.backend.name
  user_data = templatefile("${path.module}/user_data/backend_setup.sh", {
    mongodb_private_ip = aws_instance.mongodb.private_ip
  })
  ami                         = "ami-02a9cdd4e98bc3c78"
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private_a.id
  vpc_security_group_ids      = [aws_security_group.backend.id]
  key_name                    = var.key_name
  associate_public_ip_address = false
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    http_tokens = "required"
  }

  tags = {
    Name = "${var.project_name}-backend"
  }
}

terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.41.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_security_group" "minecraft" {
  name        = "cs312-minecraft-sg"
  description = "launch-wizard-1 created 2026-04-12T08:24:51.148Z"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH admin access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Minecraft client access"
    from_port   = 25565
    to_port     = 25565
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
    Name  = "cs312-minecraft-sg"
    Owner = var.onid
  }
}

resource "aws_instance" "minecraft" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.minecraft.id]
  iam_instance_profile   = "LabInstanceProfile"

  root_block_device {
    volume_size = 20
  }

  user_data = <<-EOF
    #!/bin/bash
    # Install k3s (same as lab 7)
    curl -sfL https://get.k3s.io | sh -

    # Let ubuntu user run kubectl without sudo (same as lab 7)
    mkdir -p /home/ubuntu/.kube
    cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
    chown ubuntu:ubuntu /home/ubuntu/.kube/config
    echo 'export KUBECONFIG=~/.kube/config' >> /home/ubuntu/.bashrc

    # Install AWS CLI
    apt-get update -y
    apt-get install -y unzip curl
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
    unzip -o /tmp/awscliv2.zip -d /tmp
    /tmp/aws/install

    # ECR credential helper for containerd (node-level, uses IAM instance profile)
    # This lets k3s pull from ECR without hardcoded credentials
    mkdir -p /var/lib/rancher/k3s/agent/etc/containerd
    cat > /etc/rancher/k3s/registries.yaml <<'REGISTRY'
    mirrors:
      "627060426125.dkr.ecr.us-east-1.amazonaws.com":
        endpoint:
          - "https://627060426125.dkr.ecr.us-east-1.amazonaws.com"
    configs:
      "627060426125.dkr.ecr.us-east-1.amazonaws.com":
        auth:
          username: AWS
          password: "$(aws ecr get-login-password --region us-east-1)"
    REGISTRY

    # Restart k3s to pick up registry config
    systemctl restart k3s

    # Create data dir for world restore
    mkdir -p /opt/minecraft/data

    # Restore world from S3 using instance profile (no hardcoded creds)
    aws s3 cp s3://cs312-hsunyu-minecraft-backups/world.tar.gz /tmp/world.tar.gz && \
      tar -xzf /tmp/world.tar.gz -C /opt/minecraft/data || true
  EOF

  tags = {
    Name  = "cs312-minecraft-ops4"
    Owner = var.onid
  }
}

# ============================================
# Data Sources
# ============================================

# VPCプロジェクトのリモートステートから情報を取得
data "terraform_remote_state" "vpc" {
  backend = "s3"
  
  config = {
    bucket = var.vpc_state_bucket
    key    = var.vpc_state_key
    region = var.aws_region
  }
}

# パラメータストアから最新のAmazon Linux 2023 AMI IDを取得
data "aws_ssm_parameter" "amazon_linux_2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# 取得したAMI IDの詳細情報を取得
data "aws_ami" "amazon_linux_2023" {
  owners = ["amazon"]
  
  filter {
    name   = "image-id"
    values = [data.aws_ssm_parameter.amazon_linux_2023.value]
  }
}

# ============================================
# VPCリモートステートから取得できる値
# ============================================
# data.terraform_remote_state.vpc.outputs.vpc_id
# data.terraform_remote_state.vpc.outputs.vpc_cidr
# data.terraform_remote_state.vpc.outputs.public_subnet_ids
# data.terraform_remote_state.vpc.outputs.private_subnet_ids
# data.terraform_remote_state.vpc.outputs.nat_gateway_id

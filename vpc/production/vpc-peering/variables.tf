variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
  default     = "vpc-peering"
}

variable "environment" {
  description = "Environment (dev, stg, prod)"
  type        = string
  default     = "dev"
}

# ===========================
# 既存VPC設定
# ===========================
variable "bastion_vpc_id" {
  description = "Bastion VPC ID"
  type        = string
}

variable "app_vpc_id" {
  description = "Application VPC ID"
  type        = string
}

variable "bastion_vpc_cidr" {
  description = "Bastion VPC CIDR block"
  type        = string
}

variable "app_vpc_cidr" {
  description = "Application VPC CIDR block"
  type        = string
}

# ===========================
# ルートテーブル設定
# ===========================
variable "bastion_route_table_ids" {
  description = "List of bastion VPC route table IDs"
  type        = list(string)
}

variable "app_route_table_ids" {
  description = "List of application VPC route table IDs"
  type        = list(string)
}

# ===========================
# RDS設定
# ===========================
variable "rds_security_group_id" {
  description = "RDS security group ID"
  type        = string
}

variable "rds_port" {
  description = "RDS port number"
  type        = number
  default     = 3306  # MySQL/Aurora
}

# ===========================
# 踏み台設定
# ===========================
variable "bastion_security_group_id" {
  description = "Bastion instance security group ID (optional, for egress rule)"
  type        = string
  default     = ""
}

# 今回不要
# variable "allowed_ssh_cidr_blocks" {
#   description = "CIDR blocks allowed to SSH to bastion"
#   type        = list(string)
#   default     = []  # 要設定: 自分のIPアドレス
# }

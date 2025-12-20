# ============================================
# General Variables
# ============================================
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "onyaku-bastion"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

# ============================================
# VPC Remote State Variables
# ============================================
variable "vpc_state_bucket" {
  description = "S3 bucket name for VPC remote state"
  type        = string
  default     = "terraform-state-862763484576"  # 適切なバケット名に変更してください
}

variable "vpc_state_key" {
  description = "S3 key for VPC remote state"
  type        = string
  default     = "vpc/onyaku-bastion/terraform.tfstate"
}

# ============================================
# Bastion Host Variables
# ============================================
variable "bastion_instance_type" {
  description = "Instance type for bastion host"
  type        = string
  default     = "t3a.small"
}

variable "bastion_volume_size" {
  description = "Root volume size for bastion host (GB)"
  type        = number
  default     = 80
}

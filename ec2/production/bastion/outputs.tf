# ============================================
# Bastion Host Outputs
# ============================================
output "bastion_instance_id" {
  description = "Bastion host instance ID"
  value       = aws_instance.bastion.id
}

output "bastion_instance_arn" {
  description = "Bastion host instance ARN"
  value       = aws_instance.bastion.arn
}

output "bastion_private_ip" {
  description = "Bastion host private IP address"
  value       = aws_instance.bastion.private_ip
}

output "bastion_security_group_id" {
  description = "Bastion host security group ID"
  value       = aws_security_group.bastion.id
}

output "bastion_iam_role_arn" {
  description = "Bastion host IAM role ARN"
  value       = aws_iam_role.bastion.arn
}

output "bastion_connection_command" {
  description = "Command to connect to bastion host via Session Manager"
  value       = "aws ssm start-session --target ${aws_instance.bastion.id} --region ${var.aws_region}"
}

# ============================================
# VPC Information (from remote state)
# ============================================
output "vpc_id" {
  description = "VPC ID (from remote state)"
  value       = data.terraform_remote_state.vpc.outputs.vpc_id
}

output "private_subnet_id" {
  description = "Private subnet ID where bastion is deployed"
  value       = data.terraform_remote_state.vpc.outputs.private_subnet_ids[0]
}

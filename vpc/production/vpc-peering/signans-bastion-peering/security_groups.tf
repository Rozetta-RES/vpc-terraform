# ===========================
# RDS セキュリティグループルール
# ===========================

#
# 今回はスクリプトで RDS SG に設定を実施するため
# このコードは不要とする
#

# 踏み台VPCからのアクセスを許可
# resource "aws_security_group_rule" "rds_from_bastion_vpc" {
#   type              = "ingress"
#   from_port         = var.rds_port
#   to_port           = var.rds_port
#   protocol          = "tcp"
#   cidr_blocks       = [var.bastion_vpc_cidr]
#   security_group_id = var.rds_security_group_id
#   description       = "Allow RDS access from bastion VPC"
# }

# ===========================
# 踏み台 セキュリティグループルール (オプション)
# ===========================

# 踏み台からアプリVPCへのアウトバウンド許可
# ※既存の踏み台SGがある場合のみ使用
# resource "aws_security_group_rule" "bastion_to_app_vpc" {
#   count = var.bastion_security_group_id != "" ? 1 : 0

#   type              = "egress"
#   from_port         = var.rds_port
#   to_port           = var.rds_port
#   protocol          = "tcp"
#   cidr_blocks       = [var.app_vpc_cidr]
#   security_group_id = var.bastion_security_group_id
#   description       = "Allow outbound to RDS in app VPC"
# }

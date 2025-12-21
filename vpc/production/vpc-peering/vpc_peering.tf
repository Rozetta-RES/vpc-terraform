# ===========================
# VPC Peering接続
# ===========================
resource "aws_vpc_peering_connection" "bastion_to_app" {
  vpc_id      = var.bastion_vpc_id
  peer_vpc_id = var.app_vpc_id
  auto_accept = true

  tags = {
    Name = "${var.project_name}-bastion-app-peering"
    Side = "Requester"
  }
}

# ===========================
# 踏み台VPC → アプリVPCへのルート
# ===========================
resource "aws_route" "bastion_to_app" {
  for_each = toset(var.bastion_route_table_ids)

  route_table_id            = each.value
  destination_cidr_block    = var.app_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.bastion_to_app.id
}

# ===========================
# アプリVPC → 踏み台VPCへのルート
# (return traffic用)
# ===========================
resource "aws_route" "app_to_bastion" {
  for_each = toset(var.app_route_table_ids)

  route_table_id            = each.value
  destination_cidr_block    = var.bastion_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.bastion_to_app.id
}

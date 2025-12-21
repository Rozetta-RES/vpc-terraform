output "vpc_peering_connection_id" {
  description = "VPC Peering Connection ID"
  value       = aws_vpc_peering_connection.bastion_to_app.id
}

output "vpc_peering_connection_status" {
  description = "VPC Peering Connection Status"
  value       = aws_vpc_peering_connection.bastion_to_app.accept_status
}

output "bastion_routes_created" {
  description = "Number of routes created in bastion VPC"
  value       = length(aws_route.bastion_to_app)
}

output "app_routes_created" {
  description = "Number of routes created in app VPC"
  value       = length(aws_route.app_to_bastion)
}

output "connection_info" {
  description = "VPC Peering connection information"
  value = {
    peering_id     = aws_vpc_peering_connection.bastion_to_app.id
    bastion_vpc_id = var.bastion_vpc_id
    app_vpc_id     = var.app_vpc_id
    status         = aws_vpc_peering_connection.bastion_to_app.accept_status
  }
}

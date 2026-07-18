output "id" {
  description = "OCID of the subnet."
  value       = oci_core_subnet.this.id
}

output "cidr_block" {
  description = "IPv4 CIDR block assigned to the subnet."
  value       = oci_core_subnet.this.cidr_block
}

output "virtual_router_ip" {
  description = "IP address of the virtual router for the subnet."
  value       = oci_core_subnet.this.virtual_router_ip
}

output "virtual_router_mac" {
  description = "MAC address of the virtual router for the subnet."
  value       = oci_core_subnet.this.virtual_router_mac
}

output "subnet_domain_name" {
  description = "Internal domain name of the subnet, if a dns_label was set."
  value       = oci_core_subnet.this.subnet_domain_name
}

resource "oci_core_subnet" "this" {
  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = var.display_name
  cidr_block     = var.cidr_block
  dns_label      = var.dns_label

  prohibit_public_ip_on_vnic = var.prohibit_public_ip_on_vnic

  route_table_id    = var.route_table_id
  dhcp_options_id   = var.dhcp_options_id
  security_list_ids = length(var.security_list_ids) > 0 ? var.security_list_ids : null

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

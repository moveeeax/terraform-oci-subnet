locals {
  # prohibit_public_ip_on_vnic is the deprecated way to pick public/private.
  # When a caller still sets it, the module sends exactly what it sent before
  # (that flag alone); otherwise it sends prohibit_internet_ingress, which also
  # governs IPv6 ingress. The provider says only one of the two should be set.
  legacy_public_ip_flag = var.prohibit_public_ip_on_vnic != null

  type = (
    var.type != null ? var.type :
    local.legacy_public_ip_flag ? (var.prohibit_public_ip_on_vnic ? "private" : "public") :
    "private"
  )
}

resource "oci_core_subnet" "this" {
  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = var.display_name
  cidr_block     = var.cidr_block
  dns_label      = var.dns_label

  prohibit_internet_ingress  = local.legacy_public_ip_flag ? null : local.type == "private"
  prohibit_public_ip_on_vnic = local.legacy_public_ip_flag ? var.prohibit_public_ip_on_vnic : null

  route_table_id    = var.route_table_id
  dhcp_options_id   = var.dhcp_options_id
  security_list_ids = length(var.security_list_ids) > 0 ? var.security_list_ids : null

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags

  lifecycle {
    precondition {
      condition     = var.type == null || var.prohibit_public_ip_on_vnic == null
      error_message = "Set type or the deprecated prohibit_public_ip_on_vnic, not both. type = \"private\" is the old prohibit_public_ip_on_vnic = true, type = \"public\" the old false."
    }
  }
}

check "prohibit_public_ip_on_vnic_is_deprecated" {
  assert {
    condition     = !local.legacy_public_ip_flag
    error_message = "prohibit_public_ip_on_vnic is deprecated and will be removed in the next major version. Use type = \"private\" or type = \"public\" instead; type also controls internet ingress to IPv6 addresses, which prohibit_public_ip_on_vnic does not."
  }
}

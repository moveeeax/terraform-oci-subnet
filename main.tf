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

  # Optional helper: carve the subnet's /64 out of the VCN's IPv6 prefix. OCI
  # gives a VCN a /56 by default, so this is usually cidrsubnet(prefix, 8, n),
  # but newbits is derived so a larger BYOIPv6 prefix works too.
  # try() turns an out-of-range netnum into null so the precondition below
  # reports it, instead of a bare cidrsubnet() error.
  computed_ipv6cidr_block = (
    var.vcn_ipv6_cidr_block != null && var.ipv6_netnum != null
    ? try(cidrsubnet(var.vcn_ipv6_cidr_block, 64 - tonumber(split("/", var.vcn_ipv6_cidr_block)[1]), var.ipv6_netnum), null)
    : null
  )

  ipv6cidr_blocks = concat(
    var.ipv6cidr_blocks,
    local.computed_ipv6cidr_block != null ? [local.computed_ipv6cidr_block] : [],
  )
}

resource "oci_core_subnet" "this" {
  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = var.display_name
  cidr_block     = var.cidr_block
  dns_label      = var.dns_label

  ipv6cidr_blocks = length(local.ipv6cidr_blocks) > 0 ? local.ipv6cidr_blocks : null

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

    precondition {
      condition     = (var.vcn_ipv6_cidr_block == null) == (var.ipv6_netnum == null)
      error_message = "vcn_ipv6_cidr_block and ipv6_netnum work as a pair: set both to derive a /64 from the VCN prefix, or neither."
    }

    precondition {
      condition = (
        var.vcn_ipv6_cidr_block == null || var.ipv6_netnum == null ||
        try(var.ipv6_netnum < pow(2, 64 - tonumber(split("/", var.vcn_ipv6_cidr_block)[1])), false)
      )
      error_message = "ipv6_netnum does not fit in vcn_ipv6_cidr_block: a /N VCN prefix holds 2^(64-N) /64 subnets, numbered from 0 (0-255 for a /56)."
    }

    precondition {
      condition     = length(distinct(local.ipv6cidr_blocks)) == length(local.ipv6cidr_blocks)
      error_message = "The IPv6 prefix derived from vcn_ipv6_cidr_block and ipv6_netnum is already listed in ipv6cidr_blocks (or ipv6cidr_blocks has a duplicate); OCI rejects overlapping prefixes."
    }
  }
}

check "prohibit_public_ip_on_vnic_is_deprecated" {
  assert {
    condition     = !local.legacy_public_ip_flag
    error_message = "prohibit_public_ip_on_vnic is deprecated and will be removed in the next major version. Use type = \"private\" or type = \"public\" instead; type also controls internet ingress to IPv6 addresses, which prohibit_public_ip_on_vnic does not."
  }
}

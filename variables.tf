variable "compartment_id" {
  description = "OCID of the compartment in which to create the subnet."
  type        = string
}

variable "vcn_id" {
  description = "OCID of the VCN the subnet belongs to."
  type        = string
}

variable "display_name" {
  description = "Human-readable name for the subnet."
  type        = string
}

variable "cidr_block" {
  description = "IPv4 CIDR block assigned to the subnet. Must be a network address inside the parent VCN's CIDR block."
  type        = string

  validation {
    # cidrhost() also accepts IPv6, but oci_core_subnet.cidr_block is IPv4 only
    # (IPv6 prefixes are a separate attribute), so check for an IPv4 CIDR.
    condition     = can(cidrnetmask(var.cidr_block))
    error_message = "cidr_block must be a valid IPv4 CIDR in a.b.c.d/prefix form, for example 10.0.1.0/24."
  }

  validation {
    condition     = try(cidrhost(var.cidr_block, 0) == split("/", var.cidr_block)[0], false)
    error_message = "cidr_block must be the network address of the block (host bits must be zero), for example 10.0.1.0/24 and not 10.0.1.5/24."
  }

  validation {
    condition     = try(tonumber(split("/", var.cidr_block)[1]) >= 16 && tonumber(split("/", var.cidr_block)[1]) <= 30, false)
    error_message = "cidr_block prefix length must be between /16 and /30, the range OCI accepts for VCN and subnet CIDRs."
  }
}

variable "dns_label" {
  description = "DNS label for the subnet, used to form its domain name. Null disables per-subnet DNS. Can only be set if the VCN itself has a DNS label."
  type        = string
  default     = null

  validation {
    # OCI rejects anything else at apply time: the label must begin with a
    # letter, be alphanumeric (no hyphens or periods) and be at most 15 chars.
    condition     = var.dns_label == null || can(regex("^[a-zA-Z][a-zA-Z0-9]{0,14}$", var.dns_label))
    error_message = "dns_label must start with a letter, contain only letters and digits, and be at most 15 characters long."
  }
}

variable "prohibit_public_ip_on_vnic" {
  description = "Whether to prohibit public IP addresses on VNICs in this subnet (makes it a private subnet). Defaults to true; note that OCI's own default is false."
  type        = bool
  default     = true
}

variable "route_table_id" {
  description = "OCID of the route table to associate with the subnet. Null uses the VCN default."
  type        = string
  default     = null
}

variable "dhcp_options_id" {
  description = "OCID of the set of DHCP options to associate with the subnet. Null uses the VCN default."
  type        = string
  default     = null
}

variable "security_list_ids" {
  description = <<-EOT
    List of security list OCIDs to associate with the subnet. Leaving this empty
    falls back to the VCN's default security list, which OCI creates with SSH
    (TCP/22) open to 0.0.0.0/0 unless those rules have been removed. Pass an
    explicit list for anything that is not a throwaway environment.
  EOT
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.security_list_ids) <= 5
    error_message = "OCI allows at most 5 security lists per subnet."
  }
}

variable "freeform_tags" {
  description = "Free-form tags applied to the subnet."
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "Defined tags applied to the subnet, keyed as \"namespace.key\"."
  type        = map(string)
  default     = {}
}

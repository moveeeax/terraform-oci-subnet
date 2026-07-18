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
  description = "IPv4 CIDR block assigned to the subnet."
  type        = string

  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "cidr_block must be a valid IPv4 CIDR."
  }
}

variable "dns_label" {
  description = "DNS label for the subnet, used to form its domain name. Null disables per-subnet DNS."
  type        = string
  default     = null
}

variable "prohibit_public_ip_on_vnic" {
  description = "Whether to prohibit public IP addresses on VNICs in this subnet (makes it a private subnet)."
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
  description = "List of security list OCIDs to associate with the subnet. Empty uses the VCN default security list."
  type        = list(string)
  default     = []
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

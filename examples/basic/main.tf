provider "oci" {}

module "subnet" {
  source = "../.."

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "example-subnet"
  cidr_block     = "10.10.1.0/24"
  dns_label      = "app"

  # Dual stack: pass the VCN's IPv6 prefix (for example
  # module.vcn.ipv6_cidr_blocks[0] from terraform-oci-vcn with is_ipv6enabled)
  # and the module takes /64 number 1 out of it. Left null, the subnet is IPv4-only.
  vcn_ipv6_cidr_block = var.vcn_ipv6_cidr_block
  ipv6_netnum         = var.vcn_ipv6_cidr_block != null ? 1 : null

  # "private" (the default): no public IPv4 on VNICs and no internet ingress to IPv6.
  type = "private"

  freeform_tags = {
    Environment = "sandbox"
    ManagedBy   = "terraform"
  }
}

variable "compartment_id" {
  description = "Compartment OCID to deploy the example subnet into."
  type        = string
}

variable "vcn_id" {
  description = "OCID of the VCN to attach the example subnet to."
  type        = string
}

variable "vcn_ipv6_cidr_block" {
  description = "IPv6 prefix of the VCN, if it has IPv6 enabled. Null keeps the example subnet IPv4-only."
  type        = string
  default     = null
}

output "subnet_id" {
  value = module.subnet.id
}

output "subnet_ipv6cidr_blocks" {
  value = module.subnet.ipv6cidr_blocks
}

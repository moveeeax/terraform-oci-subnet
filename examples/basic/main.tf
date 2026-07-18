provider "oci" {}

module "subnet" {
  source = "../.."

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "example-subnet"
  cidr_block     = "10.10.1.0/24"
  dns_label      = "app"

  prohibit_public_ip_on_vnic = true

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

output "subnet_id" {
  value = module.subnet.id
}

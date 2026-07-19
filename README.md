# terraform-oci-subnet

Terraform module that manages an [Oracle Cloud Infrastructure](https://www.oracle.com/cloud/)
subnet inside an existing VCN. It supports public and private subnets and lets you
associate a custom route table, DHCP options and security lists.

## Usage

```hcl
module "subnet" {
  source = "github.com/moveeeax/terraform-oci-subnet"

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "prod-app-subnet"
  cidr_block     = "10.0.1.0/24"
  dns_label      = "app"

  prohibit_public_ip_on_vnic = true

  freeform_tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

A runnable example lives in [`examples/basic`](examples/basic).

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.5   |
| oci       | >= 5.0   |

## Inputs

| Name                         | Description                                                             | Type           | Default | Required |
|------------------------------|-------------------------------------------------------------------------|----------------|---------|:--------:|
| `compartment_id`             | OCID of the compartment in which to create the subnet.                  | `string`       | n/a     |   yes    |
| `vcn_id`                     | OCID of the VCN the subnet belongs to.                                  | `string`       | n/a     |   yes    |
| `display_name`               | Human-readable name for the subnet.                                     | `string`       | n/a     |   yes    |
| `cidr_block`                 | IPv4 CIDR block assigned to the subnet.                                 | `string`       | n/a     |   yes    |
| `dns_label`                  | DNS label for the subnet. Null disables per-subnet DNS.                 | `string`       | `null`  |    no    |
| `prohibit_public_ip_on_vnic` | Prohibit public IPs on VNICs, making it a private subnet.               | `bool`         | `true`  |    no    |
| `route_table_id`             | Route table OCID to associate. Null uses the VCN default.               | `string`       | `null`  |    no    |
| `dhcp_options_id`            | DHCP options OCID to associate. Null uses the VCN default.              | `string`       | `null`  |    no    |
| `security_list_ids`          | Security list OCIDs to associate. Empty uses the VCN default.           | `list(string)` | `[]`    |    no    |
| `freeform_tags`              | Free-form tags applied to the subnet.                                   | `map(string)`  | `{}`    |    no    |
| `defined_tags`               | Defined tags applied to the subnet, keyed as `namespace.key`.           | `map(string)`  | `{}`    |    no    |

## Outputs

| Name                 | Description                                              |
|----------------------|----------------------------------------------------------|
| `id`                 | OCID of the subnet.                                      |
| `cidr_block`         | IPv4 CIDR block assigned to the subnet.                  |
| `virtual_router_ip`  | IP address of the virtual router for the subnet.         |
| `virtual_router_mac` | MAC address of the virtual router for the subnet.        |
| `subnet_domain_name` | Internal domain name of the subnet, if a dns_label set.  |

## License

[MIT](LICENSE)

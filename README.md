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

## Security notes

- **Subnets are private by default.** `prohibit_public_ip_on_vnic` defaults to `true`,
  which is the opposite of OCI's own default (`false`, meaning every VNIC in the subnet
  can be given a public IP). Set it to `false` deliberately when you want a public subnet.
  OCI derives the subnet's IPv4 internet-ingress behaviour from this same flag — its
  sibling API field `prohibitInternetIngress` must not be set at the same time, so this
  module intentionally does not expose it.
- **Leaving `security_list_ids` empty falls back to the VCN's default security list.**
  OCI creates that list with SSH (TCP/22) allowed from `0.0.0.0/0`. Unless the VCN module
  that created it has emptied those rules, an "empty" subnet is not a closed one — pass
  an explicit list of security list OCIDs for anything that matters.
- **`route_table_id` left null uses the VCN's default route table.** That table has no
  internet gateway route unless someone added one, but it is shared VCN-wide, so a change
  made for one subnet affects every subnet that relies on the default.
- **`cidr_block` is not checked against the VCN's CIDR** — the module only receives the
  VCN's OCID, not its address space, so an out-of-range block is rejected by OCI at apply
  time. Format, alignment and prefix length (`/16`–`/30`) *are* validated up front.

## Input validation

`cidr_block` must be a well-formed IPv4 CIDR, the network address of its block
(host bits zero) and between `/16` and `/30`. `dns_label`, when set, must begin with a
letter, contain only letters and digits, and be at most 15 characters — OCI otherwise
rejects it at apply time, after the plan has been approved. At most five security lists
may be attached to a subnet.

## Tests

`terraform test` (or `tofu test`) runs the suite in [`tests/`](tests) against a mocked
OCI provider — no credentials and no network required. The tests need Terraform/OpenTofu
>= 1.7 for `mock_provider`; the module itself still supports >= 1.5.

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
| `cidr_block`                 | IPv4 CIDR block assigned to the subnet. Network address, `/16`–`/30`.   | `string`       | n/a     |   yes    |
| `dns_label`                  | DNS label for the subnet. Letter-initial, alphanumeric, max 15 chars.   | `string`       | `null`  |    no    |
| `prohibit_public_ip_on_vnic` | Prohibit public IPs on VNICs, making it a private subnet.               | `bool`         | `true`  |    no    |
| `route_table_id`             | Route table OCID to associate. Null uses the VCN default.               | `string`       | `null`  |    no    |
| `dhcp_options_id`            | DHCP options OCID to associate. Null uses the VCN default.              | `string`       | `null`  |    no    |
| `security_list_ids`          | Security list OCIDs to associate (max 5). Empty uses the VCN default.   | `list(string)` | `[]`    |    no    |
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

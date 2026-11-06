# terraform-oci-subnet

Terraform module that manages an [Oracle Cloud Infrastructure](https://www.oracle.com/cloud/)
subnet inside an existing VCN. It supports public and private subnets and lets you
associate a custom route table, DHCP options and security lists.

## Usage

```hcl
module "subnet" {
  source = "github.com/moveeeax/terraform-oci-subnet?ref=v1.0.0"

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "prod-app-subnet"
  cidr_block     = "10.0.1.0/24"
  dns_label      = "app"
  type           = "private"

  freeform_tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

A runnable example lives in [`examples/basic`](examples/basic).

## Security notes

- **Subnets are private by default.** `type` defaults to `"private"`, which sends
  `prohibit_internet_ingress = true`: VNICs cannot get a public IPv4 address and IPv6
  addresses in the subnet accept no ingress from the internet. OCI's own default is the
  opposite. Set `type = "public"` deliberately when you want a public subnet. Both
  underlying flags force a new subnet when they change, so pick the type up front.
- **`prohibit_public_ip_on_vnic` is deprecated.** It still works and, when set, the module
  sends that flag alone, exactly as earlier versions did. It only governs IPv4: with an
  IPv6 prefix on the subnet, VNICs stay reachable from the internet over IPv6. The
  provider documents that only one of the two flags should be set, so the module refuses
  `type` and `prohibit_public_ip_on_vnic` together, and a `check` block warns while the old
  input is in use.
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
may be attached to a subnet. `type` must be `"private"` or `"public"` and cannot be
combined with the deprecated `prohibit_public_ip_on_vnic`.

## Upgrading from `prohibit_public_ip_on_vnic`

| Before                               | After              |
|--------------------------------------|--------------------|
| `prohibit_public_ip_on_vnic = true`  | `type = "private"` |
| `prohibit_public_ip_on_vnic = false` | `type = "public"`  |
| not set (module default `true`)      | nothing to change  |

With `type` (or with neither input set, which is how a caller that relied on the old
default upgrades) the module sends `prohibit_internet_ingress` instead of
`prohibit_public_ip_on_vnic`. The provider marks both flags as forcing a new subnet. OCI
is expected to report the same value for both on an IPv4-only subnet, which makes the
switch a no-op, but this has not been verified against a live tenancy, so read the first
plan after upgrading. If it shows the subnet being replaced, set
`prohibit_public_ip_on_vnic = true` (or `false`) explicitly: that sends exactly the old
request until you can migrate.

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
| `type`                       | `"private"` or `"public"`. Private prohibits internet ingress (IPv4 and IPv6). | `string` | `null` (private) | no |
| `prohibit_public_ip_on_vnic` | Deprecated, use `type`. Prohibit public IPs on VNICs (IPv4 only).       | `bool`         | `null`  |    no    |
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
| `type`               | `"private"` or `"public"`, as resolved from the inputs.  |

## License

[MIT](LICENSE)

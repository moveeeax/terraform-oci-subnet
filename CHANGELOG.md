# Changelog

All notable changes to this module are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- `type` input (`"private"` or `"public"`, default private) that sets
  `prohibit_internet_ingress`, so a private subnet also blocks internet ingress to
  IPv6 addresses, and a `type` output.
- IPv6 prefixes: `ipv6cidr_blocks` (list of /64 network addresses, validated at plan
  time), and the `vcn_ipv6_cidr_block` + `ipv6_netnum` pair that derives a /64 from the
  VCN's IPv6 prefix with `cidrsubnet()`. New outputs `ipv6cidr_blocks` and
  `ipv6virtual_router_ip`. Subnets without these inputs stay IPv4-only and plan
  unchanged.

### Deprecated

- `prohibit_public_ip_on_vnic`: use `type`. It keeps working (default is now `null`);
  when set, the module sends that flag alone as before, and a `check` block warns.
  Setting it together with `type` fails the plan. Callers that never set it now send
  `prohibit_internet_ingress = true` instead of `prohibit_public_ip_on_vnic = true`;
  both force a new subnet, so review the first plan after upgrading (see the README).

### Changed

- CI: bump actions to their current majors, pin tool versions, and restrict the
  workflow token to `contents: read`.
- CI: add Dependabot for GitHub Actions and the Terraform provider.
- Docs: pin the README usage `source` to a release tag; fix the LICENSE year.

## [1.0.0]

Initial release (`v0.1.0` points at the same commit).

[Unreleased]: https://github.com/moveeeax/terraform-oci-subnet/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/moveeeax/terraform-oci-subnet/releases/tag/v1.0.0

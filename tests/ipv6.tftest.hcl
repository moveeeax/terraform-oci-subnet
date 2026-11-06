# Requires Terraform >= 1.7 / OpenTofu >= 1.7 for mock_provider.
# IPv6 prefixes: explicit ipv6cidr_blocks, the vcn_ipv6_cidr_block + ipv6_netnum
# helper, and the inputs OCI would reject at apply time.

mock_provider "oci" {}

variables {
  compartment_id = "ocid1.compartment.oc1..aaaaaaaaexamplecompartment"
  vcn_id         = "ocid1.vcn.oc1.phx.aaaaaaaaexamplevcn"
  display_name   = "test-subnet"
  cidr_block     = "10.0.1.0/24"
}

run "ipv4_only_by_default" {
  command = plan

  assert {
    condition     = length(local.ipv6cidr_blocks) == 0
    error_message = "No IPv6 prefix may be requested unless the caller asks for one."
  }
}

run "passes_explicit_ipv6_prefixes_through" {
  command = plan

  variables {
    ipv6cidr_blocks = ["2001:db8:0:1::/64", "fd00:0:0:1::/64"]
  }

  assert {
    condition     = oci_core_subnet.this.ipv6cidr_blocks == tolist(["2001:db8:0:1::/64", "fd00:0:0:1::/64"])
    error_message = "ipv6cidr_blocks must be passed through to the subnet in order."
  }
}

run "derives_a_64_from_a_56_vcn_prefix" {
  command = plan

  variables {
    vcn_ipv6_cidr_block = "2001:db8:0:100::/56"
    ipv6_netnum         = 3
  }

  assert {
    condition     = oci_core_subnet.this.ipv6cidr_blocks == tolist(["2001:db8:0:103::/64"])
    error_message = "netnum 3 of 2001:db8:0:100::/56 must be 2001:db8:0:103::/64."
  }
}

run "derives_from_a_48_byoip_prefix" {
  command = plan

  variables {
    vcn_ipv6_cidr_block = "2001:db8:1::/48"
    ipv6_netnum         = 513
  }

  assert {
    condition     = oci_core_subnet.this.ipv6cidr_blocks == tolist(["2001:db8:1:201::/64"])
    error_message = "A /48 prefix must use 16 new bits, so netnum 513 is 2001:db8:1:201::/64."
  }
}

run "appends_the_derived_prefix_to_explicit_ones" {
  command = plan

  variables {
    ipv6cidr_blocks     = ["fd00:0:0:1::/64"]
    vcn_ipv6_cidr_block = "2001:db8:0:100::/56"
    ipv6_netnum         = 0
  }

  assert {
    condition     = oci_core_subnet.this.ipv6cidr_blocks == tolist(["fd00:0:0:1::/64", "2001:db8:0:100::/64"])
    error_message = "The derived /64 must be appended after the explicit prefixes."
  }
}

run "rejects_ipv4_in_ipv6cidr_blocks" {
  command = plan

  variables {
    ipv6cidr_blocks = ["10.0.1.0/24"]
  }

  expect_failures = [var.ipv6cidr_blocks]
}

run "rejects_ipv6_prefix_that_is_not_a_64" {
  command = plan

  variables {
    ipv6cidr_blocks = ["2001:db8:0:100::/56"]
  }

  expect_failures = [var.ipv6cidr_blocks]
}

run "rejects_ipv6_prefix_with_host_bits_set" {
  command = plan

  variables {
    ipv6cidr_blocks = ["2001:db8:0:1::5/64"]
  }

  expect_failures = [var.ipv6cidr_blocks]
}

run "accepts_non_canonical_ipv6_spelling" {
  command = plan

  variables {
    ipv6cidr_blocks = ["2001:0db8:0000:0001::/64"]
  }

  assert {
    condition     = length(oci_core_subnet.this.ipv6cidr_blocks) == 1
    error_message = "A zero-padded but valid /64 network address must be accepted."
  }
}

run "rejects_duplicate_ipv6_prefixes" {
  command = plan

  variables {
    ipv6cidr_blocks = ["2001:db8:0:1::/64", "2001:db8:0:1::/64"]
  }

  expect_failures = [var.ipv6cidr_blocks]
}

run "rejects_ipv4_vcn_prefix" {
  command = plan

  variables {
    vcn_ipv6_cidr_block = "10.0.0.0/16"
    ipv6_netnum         = 1
  }

  expect_failures = [var.vcn_ipv6_cidr_block]
}

run "rejects_vcn_prefix_smaller_than_64" {
  command = plan

  variables {
    vcn_ipv6_cidr_block = "2001:db8::/96"
    ipv6_netnum         = 0
  }

  expect_failures = [var.vcn_ipv6_cidr_block]
}

run "rejects_negative_netnum" {
  command = plan

  variables {
    vcn_ipv6_cidr_block = "2001:db8:0:100::/56"
    ipv6_netnum         = -1
  }

  expect_failures = [var.ipv6_netnum]
}

run "rejects_netnum_outside_the_vcn_prefix" {
  command = plan

  variables {
    vcn_ipv6_cidr_block = "2001:db8:0:100::/56"
    ipv6_netnum         = 256
  }

  expect_failures = [oci_core_subnet.this]
}

run "rejects_netnum_without_vcn_prefix" {
  command = plan

  variables {
    ipv6_netnum = 1
  }

  expect_failures = [oci_core_subnet.this]
}

run "rejects_derived_prefix_already_listed" {
  command = plan

  variables {
    ipv6cidr_blocks     = ["2001:db8:0:100::/64"]
    vcn_ipv6_cidr_block = "2001:db8:0:100::/56"
    ipv6_netnum         = 0
  }

  expect_failures = [oci_core_subnet.this]
}

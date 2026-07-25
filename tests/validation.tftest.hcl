# Requires Terraform >= 1.7 / OpenTofu >= 1.7 for mock_provider.
# Every input rejected here is one that OCI would otherwise reject at apply
# time, after the plan has already been approved.

mock_provider "oci" {}

variables {
  compartment_id = "ocid1.compartment.oc1..aaaaaaaaexamplecompartment"
  vcn_id         = "ocid1.vcn.oc1.phx.aaaaaaaaexamplevcn"
  display_name   = "test-subnet"
  cidr_block     = "10.0.1.0/24"
}

run "rejects_malformed_cidr" {
  command = plan

  variables {
    cidr_block = "10.0.1.0"
  }

  expect_failures = [var.cidr_block]
}

run "rejects_ipv6_cidr" {
  command = plan

  variables {
    cidr_block = "2001:db8::/64"
  }

  expect_failures = [var.cidr_block]
}

run "rejects_cidr_with_host_bits_set" {
  command = plan

  variables {
    cidr_block = "10.0.1.5/24"
  }

  expect_failures = [var.cidr_block]
}

run "rejects_cidr_prefix_below_range" {
  command = plan

  variables {
    cidr_block = "10.0.0.0/8"
  }

  expect_failures = [var.cidr_block]
}

run "rejects_cidr_prefix_above_range" {
  command = plan

  variables {
    cidr_block = "10.0.1.0/31"
  }

  expect_failures = [var.cidr_block]
}

run "accepts_smallest_supported_cidr" {
  command = plan

  variables {
    cidr_block = "10.0.1.0/30"
  }

  assert {
    condition     = oci_core_subnet.this.cidr_block == "10.0.1.0/30"
    error_message = "A /30 is the smallest subnet OCI supports and must be accepted."
  }
}

run "rejects_dns_label_starting_with_a_digit" {
  command = plan

  variables {
    dns_label = "1app"
  }

  expect_failures = [var.dns_label]
}

run "rejects_dns_label_with_a_hyphen" {
  command = plan

  variables {
    dns_label = "app-subnet"
  }

  expect_failures = [var.dns_label]
}

run "rejects_dns_label_over_15_characters" {
  command = plan

  variables {
    dns_label = "abcdefghijklmnop"
  }

  expect_failures = [var.dns_label]
}

run "rejects_more_than_five_security_lists" {
  command = plan

  variables {
    security_list_ids = [
      "ocid1.securitylist.oc1.phx.aaaaaaaaexamplelist1",
      "ocid1.securitylist.oc1.phx.aaaaaaaaexamplelist2",
      "ocid1.securitylist.oc1.phx.aaaaaaaaexamplelist3",
      "ocid1.securitylist.oc1.phx.aaaaaaaaexamplelist4",
      "ocid1.securitylist.oc1.phx.aaaaaaaaexamplelist5",
      "ocid1.securitylist.oc1.phx.aaaaaaaaexamplelist6",
    ]
  }

  expect_failures = [var.security_list_ids]
}

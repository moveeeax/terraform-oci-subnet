# Requires Terraform >= 1.7 / OpenTofu >= 1.7 for mock_provider.
# The module itself still supports >= 1.5 - this requirement is test-only.

mock_provider "oci" {}

variables {
  compartment_id = "ocid1.compartment.oc1..aaaaaaaaexamplecompartment"
  vcn_id         = "ocid1.vcn.oc1.phx.aaaaaaaaexamplevcn"
  display_name   = "test-subnet"
  cidr_block     = "10.0.1.0/24"
}

run "defaults_to_a_private_subnet" {
  command = plan

  assert {
    condition     = oci_core_subnet.this.prohibit_internet_ingress == true
    error_message = "Subnets must be private by default (prohibit_internet_ingress = true); OCI's own default lets the internet in."
  }

  assert {
    condition     = output.type == "private"
    error_message = "The type output must report \"private\" by default."
  }
}

run "type_private_prohibits_internet_ingress" {
  command = plan

  variables {
    type = "private"
  }

  assert {
    condition     = oci_core_subnet.this.prohibit_internet_ingress == true
    error_message = "type = \"private\" must set prohibit_internet_ingress = true."
  }

  assert {
    condition     = output.type == "private"
    error_message = "The type output must echo type."
  }
}

run "type_public_allows_internet_ingress" {
  command = plan

  variables {
    type = "public"
  }

  assert {
    condition     = oci_core_subnet.this.prohibit_internet_ingress == false
    error_message = "type = \"public\" must set prohibit_internet_ingress = false."
  }

  assert {
    condition     = output.type == "public"
    error_message = "The type output must echo type."
  }
}

# The deprecated flag keeps sending exactly what earlier versions sent, so an
# existing subnet that pins it sees no change on upgrade.
run "deprecated_flag_true_still_makes_a_private_subnet" {
  command = plan

  variables {
    prohibit_public_ip_on_vnic = true
  }

  assert {
    condition     = oci_core_subnet.this.prohibit_public_ip_on_vnic == true
    error_message = "prohibit_public_ip_on_vnic = true must still be passed through."
  }

  assert {
    condition     = output.type == "private"
    error_message = "prohibit_public_ip_on_vnic = true must resolve to type \"private\"."
  }

  expect_failures = [check.prohibit_public_ip_on_vnic_is_deprecated]
}

run "public_subnet_via_deprecated_flag" {
  command = plan

  variables {
    prohibit_public_ip_on_vnic = false
  }

  assert {
    condition     = oci_core_subnet.this.prohibit_public_ip_on_vnic == false
    error_message = "prohibit_public_ip_on_vnic must be passed through so a public subnet can still be requested the old way."
  }

  assert {
    condition     = output.type == "public"
    error_message = "prohibit_public_ip_on_vnic = false must resolve to type \"public\"."
  }

  expect_failures = [check.prohibit_public_ip_on_vnic_is_deprecated]
}

run "associates_supplied_security_lists" {
  command = plan

  variables {
    security_list_ids = [
      "ocid1.securitylist.oc1.phx.aaaaaaaaexamplelist1",
      "ocid1.securitylist.oc1.phx.aaaaaaaaexamplelist2",
    ]
  }

  assert {
    condition     = length(oci_core_subnet.this.security_list_ids) == 2
    error_message = "Supplied security list OCIDs must be associated with the subnet."
  }
}

run "passes_through_optional_associations" {
  command = plan

  variables {
    dns_label       = "app1"
    route_table_id  = "ocid1.routetable.oc1.phx.aaaaaaaaexamplert"
    dhcp_options_id = "ocid1.dhcpoptions.oc1.phx.aaaaaaaaexampledhcp"
    freeform_tags   = { Environment = "test" }
  }

  assert {
    condition     = oci_core_subnet.this.dns_label == "app1"
    error_message = "dns_label must be passed through to the subnet."
  }

  assert {
    condition     = oci_core_subnet.this.route_table_id == "ocid1.routetable.oc1.phx.aaaaaaaaexamplert"
    error_message = "route_table_id must be passed through to the subnet."
  }

  assert {
    condition     = oci_core_subnet.this.dhcp_options_id == "ocid1.dhcpoptions.oc1.phx.aaaaaaaaexampledhcp"
    error_message = "dhcp_options_id must be passed through to the subnet."
  }

  assert {
    condition     = oci_core_subnet.this.freeform_tags["Environment"] == "test"
    error_message = "freeform_tags must be passed through to the subnet."
  }
}

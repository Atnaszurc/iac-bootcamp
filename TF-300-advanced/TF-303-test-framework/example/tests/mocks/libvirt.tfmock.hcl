# TF-303: Terraform Test Framework — Libvirt Mock Provider File
#
# This is a `.tfmock.hcl` file — a reusable mock definition that can be
# referenced from multiple test files using the `source` attribute:
#
#   mock_provider "libvirt" {
#     source = "./tests/mocks/libvirt.tfmock.hcl"
#   }
#
# Mock files let you define synthetic provider behaviour ONCE and reuse it
# across many test files, keeping your tests DRY.
#
# This file mocks the `dmacvicar/libvirt` provider for unit testing
# Terraform configurations that manage KVM/QEMU virtual infrastructure.
#
# Usage in a test file:
#   mock_provider "libvirt" {
#     source = "./tests/mocks/libvirt.tfmock.hcl"
#   }
#
# See: https://developer.hashicorp.com/terraform/language/tests/mocking

mock_resource "libvirt_network" {
  defaults = {
    id = "00000000-0000-4000-8000-000000000001"
  }
}

mock_resource "libvirt_volume" {
  defaults = {
    id   = "/var/lib/libvirt/images/mock-disk.qcow2"
    key  = "/var/lib/libvirt/images/mock-disk.qcow2"
    path = "/var/lib/libvirt/images/mock-disk.qcow2"
  }
}

mock_resource "libvirt_domain" {
  defaults = {
    uuid = "00000000-0000-4000-8000-000000000002"
  }
}

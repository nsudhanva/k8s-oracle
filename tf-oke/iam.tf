resource "oci_identity_dynamic_group" "oke_nodes" {
  compartment_id = var.tenancy_ocid
  name           = "oke-nodes-dg"
  description    = "Dynamic group for OKE nodes to access OCI Vault"
  matching_rule  = "ALL {instance.compartment.id = '${var.compartment_ocid}'}"
}

resource "oci_identity_policy" "oke_secrets_policy" {
  compartment_id = var.compartment_ocid
  name           = "oke-secrets-read-policy"
  description    = "Allow OKE nodes to read secrets from Vault"

  statements = [
    "Allow dynamic-group oke-nodes-dg to read secret-family in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group oke-nodes-dg to use vaults in compartment id ${var.compartment_ocid}"
  ]
}

# OCI Identity Domain - OIDC Application for Open WebUI
# Free tier limit: 2 third-party applications (this is #1)
# App was created manually and is managed outside Terraform via data source lookup.

data "oci_identity_domains" "default" {
  compartment_id = var.compartment_ocid
  display_name   = "Default"
}

data "oci_identity_domains_apps" "open_webui" {
  idcs_endpoint = data.oci_identity_domains.default.domains[0].url
  app_filter    = "displayName eq \"open-webui\""
}

locals {
  open_webui_app = length(data.oci_identity_domains_apps.open_webui.apps) > 0 ? data.oci_identity_domains_apps.open_webui.apps[0] : null
}

output "oidc_client_id" {
  value       = local.open_webui_app != null ? local.open_webui_app.name : "not-found"
  description = "OIDC Client ID for Open WebUI"
}

output "oidc_idcs_endpoint" {
  value       = data.oci_identity_domains.default.domains[0].url
  description = "OCI Identity Domain endpoint for OIDC"
}

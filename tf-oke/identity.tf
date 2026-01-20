# OCI Identity Domain - OIDC Application for Open WebUI
# Free tier limit: 2 third-party applications (this is #1)

data "oci_identity_domains" "default" {
  compartment_id = var.compartment_ocid
  display_name   = "Default"
}

resource "oci_identity_domains_app" "open_webui" {
  idcs_endpoint = data.oci_identity_domains.default.domains[0].url
  display_name  = "open-webui"
  description   = "Open WebUI - Chat interface for Gemma LLM"
  schemas       = ["urn:ietf:params:scim:schemas:oracle:idcs:App"]

  based_on_template {
    value = "CustomWebAppTemplateId"
  }

  is_oauth_client           = true
  client_type               = "confidential"
  allowed_grants            = ["authorization_code", "refresh_token"]
  redirect_uris             = ["https://chat.${var.domain_name}/oauth/oidc/callback"]
  post_logout_redirect_uris = ["https://chat.${var.domain_name}"]
  is_login_target           = true
  show_in_my_apps           = true
  login_mechanism           = "OIDC"

  active = true

  lifecycle {
    ignore_changes = [
      # Prevent drift from manual changes in console
      description,
    ]
  }
}

output "oidc_client_id" {
  value       = oci_identity_domains_app.open_webui.name
  description = "OIDC Client ID for Open WebUI"
}

output "oidc_idcs_endpoint" {
  value       = data.oci_identity_domains.default.domains[0].url
  description = "OCI Identity Domain endpoint for OIDC"
}

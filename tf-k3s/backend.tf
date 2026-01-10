# Terraform Remote State Backend for OCI Object Storage
#
# This file configures remote state storage in OCI Object Storage using S3 compatibility.
# 
# PREREQUISITES:
# 1. Generate OCI Customer Secret Keys:
#    - Go to OCI Console > Profile > User Settings > Customer Secret Keys
#    - Click "Generate Secret Key" and SAVE both keys immediately
#    - The Access Key = AWS_ACCESS_KEY_ID
#    - The Secret Key = AWS_SECRET_ACCESS_KEY (shown only once!)
#
# 2. Set environment variables before running terraform init:
#    export AWS_ACCESS_KEY_ID="<your-access-key>"
#    export AWS_SECRET_ACCESS_KEY="<your-secret-key>"
#
# 3. Uncomment the terraform block below
#
# 4. Run: terraform init -migrate-state
#
# BUCKET: k3s-tfstate (already created)
# NAMESPACE: idlam3ku7ae7
#
# terraform {
#   backend "s3" {
#     bucket                      = "k3s-tfstate"
#     key                         = "terraform.tfstate"
#     region                      = "us-ashburn-1"
#     endpoints = {
#       s3 = "https://idlam3ku7ae7.compat.objectstorage.us-ashburn-1.oraclecloud.com"
#     }
#     skip_region_validation      = true
#     skip_credentials_validation = true
#     skip_requesting_account_id  = true
#     skip_metadata_api_check     = true
#     use_path_style              = true
#     skip_s3_checksum            = true
#   }
# }

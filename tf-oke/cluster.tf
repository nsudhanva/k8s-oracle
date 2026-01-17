data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_ocid
}

data "oci_containerengine_node_pool_option" "node_pool_option" {
  node_pool_option_id = "all"
  compartment_id      = var.compartment_ocid
}

locals {
  ssh_public_key = file(var.ssh_public_key_path)

  oke_arm_images = [
    for source in data.oci_containerengine_node_pool_option.node_pool_option.sources :
    source if length(regexall("Oracle-Linux-8.*aarch64.*OKE-${var.kubernetes_version}", source.source_name)) > 0
  ]
}

resource "oci_containerengine_cluster" "oke_cluster" {
  compartment_id     = var.compartment_ocid
  kubernetes_version = "v${var.kubernetes_version}"
  name               = "oke-cluster"
  vcn_id             = oci_core_vcn.oke_vcn.id

  type = "BASIC_CLUSTER"

  cluster_pod_network_options {
    cni_type = "FLANNEL_OVERLAY"
  }

  endpoint_config {
    is_public_ip_enabled = true
    subnet_id            = oci_core_subnet.public_subnet.id
  }

  options {
    add_ons {
      is_kubernetes_dashboard_enabled = false
      is_tiller_enabled               = false
    }
    kubernetes_network_config {
      pods_cidr     = "10.244.0.0/16"
      services_cidr = "10.96.0.0/16"
    }
    service_lb_subnet_ids = [oci_core_subnet.public_subnet.id]
  }

  freeform_tags = var.common_tags
}

resource "oci_containerengine_node_pool" "oke_node_pool" {
  cluster_id         = oci_containerengine_cluster.oke_cluster.id
  compartment_id     = var.compartment_ocid
  kubernetes_version = "v${var.kubernetes_version}"
  name               = "oke-arm-pool"

  node_config_details {
    size = var.node_pool_size

    dynamic "placement_configs" {
      for_each = [for ad in data.oci_identity_availability_domains.ads.availability_domains : ad.name]
      content {
        availability_domain = placement_configs.value
        subnet_id           = oci_core_subnet.private_subnet.id
      }
    }

    node_pool_pod_network_option_details {
      cni_type = "FLANNEL_OVERLAY"
    }
  }

  node_shape = "VM.Standard.A1.Flex"

  node_shape_config {
    memory_in_gbs = var.node_memory_in_gbs
    ocpus         = var.node_ocpus
  }

  node_source_details {
    image_id    = local.oke_arm_images[0].image_id
    source_type = "image"
  }

  initial_node_labels {
    key   = "name"
    value = "oke-arm-worker"
  }

  ssh_public_key = local.ssh_public_key

  freeform_tags = var.common_tags
}

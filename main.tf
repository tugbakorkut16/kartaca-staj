# Google Cloud Platform Provider ayarları
provider "google" {
  credentials = file("service-account.json")
  project     = var.project_id
  region      = "europe-west1"
}


variable "project_id" {}

locals {
  network_name      = "kartaca-staj-network-yeni"
  subnet_cidrs      = ["10.2.0.0/16", "10.3.0.0/16", "10.4.16.0/24"]
  subnet_region     = "europe-west1"
  subnet_zone_count = 3
  subnet_zone_names = ["a", "b" , "c"]
}

resource "google_compute_network" "vpc_network" {
  name                    = "${local.network_name}"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "vpc_subnet" {
  # count = local.subnet_zone_count

  # name          = "${local.network_name}-subnet-${local.subnet_zone_names[count.index]}"
  # region        = local.subnet_region
  # network       = google_compute_network.vpc_network.self_link
  # ip_cidr_range = local.subnet_cidrs[count.index]
  name          = "kartaca-staj-network-subnet"
  ip_cidr_range = "10.0.0.0/18"
  network       = google_compute_network.vpc_network.self_link
  region        = "europe-west1"
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "services-ranges"
    ip_cidr_range = "192.168.1.0/24"
  }

  secondary_ip_range {
    range_name    = "pod-ranges"
    ip_cidr_range = "192.168.64.0/22"
  }
}

# GKE Cluster oluşturma
resource "google_container_cluster" "my-gke-cluster" {
  name               = "my-gke-cluster"
  location           = "europe-west1"
  # remove_default_node_pool = true
 # initial_node_count = 1

  # Standart cluster
  release_channel {
    channel = "STABLE"
  }

  # Node Pool
  node_pool {
    name               = "my-node-pool"
    initial_node_count = 1
    version            = "1.24.9-gke.3200"
    autoscaling {
      max_node_count = 5
      min_node_count = 1
    }
    node_config {
      machine_type = "e2-medium"
      disk_size_gb = 20
    }
  }

  # Network
  network    = google_compute_network.vpc_network.id
  subnetwork = google_compute_subnetwork.vpc_subnet.id

  ip_allocation_policy {
    cluster_secondary_range_name  = "pod-ranges"
    services_secondary_range_name = "services-ranges"
  }
 # subnetwork = google_compute_subnetwork.vpc_subnet.*.self_link[count.index]

} 

# Deployment oluşturma
resource "kubernetes_deployment" "my-deployment" {
  metadata {
    name = "my-deployment"
  }
  spec {
    replicas = 3

    selector {
      match_labels = {
        app = "my-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "my-app"
        }
      }
      spec {
        container {
          image = "tugbakorkut16/kartaca_staj_2023"
          name  = "my-container"
          port {
            container_port = 80
          }
        }
      }
    }
  }
}

# Servis oluşturma
resource "kubernetes_service" "my-service" {
  metadata {
    name = "my-service"
  }
  spec {
    selector = {
      app = "my-app"
    }
    port {
      port        = 80
      target_port = 80
    }
    type = "LoadBalancer"
  }
}

# Output tanımlama
output "cluster_endpoint" {
  value = google_container_cluster.my-gke-cluster.endpoint
}

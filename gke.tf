terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.39.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.37.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.0.0-pre2"
    }
  }

  backend "gcs" {
    bucket = "terraform-on-gcp-enuygun"
    prefix = "terraform/demo"
  }
}

provider "google" {
  region = "europe-west1"
}

variable "project" {}
variable "region" { default = "europe-west1" }
variable "cluster_name" {}

module "gke" {
  source                   = "terraform-google-modules/kubernetes-engine/google"
  version                  = "36.3.0"
  project_id               = var.project
  name                     = var.cluster_name
  region                   = var.region
  zones                    = ["europe-west1-b"]

  network                  = google_compute_network.vpc_network.name
  subnetwork               = google_compute_subnetwork.vpc_subnet.name
  ip_range_pods            = "pods-range"
  ip_range_services        = "services-range"

  remove_default_node_pool = true
  logging_service          = "none"
  monitoring_service       = "none"

  node_pools = [
    {
      name               = "main-pool"
      machine_type       = "n2d-standard-2"
      node_locations     = "europe-west1-b"
      initial_node_count = 1
      min_count          = 1
      max_count          = 1
      autoscaling        = false
    },
    {
      name               = "application-pool"
      machine_type       = "n2d-standard-2"
      node_locations     = "europe-west1-b"
      initial_node_count = 1
      min_count          = 1
      max_count          = 3
      autoscaling        = true
    }
  ]

  node_pools_oauth_scopes = {
    all = []
    main-pool = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    application-pool = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

data "google_client_config" "current" {}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
  token                  = data.google_client_config.current.access_token
}

provider "helm" {
  kubernetes = {
    host                   = "https://${module.gke.endpoint}"
    cluster_ca_certificate = base64decode(module.gke.ca_certificate)
    token                  = data.google_client_config.current.access_token
  }
}

resource "helm_release" "monitoring" {
  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true

  values = [
    yamlencode({
      grafana = {
        adminPassword = "enuygun"
        service = {
          type = "LoadBalancer"
        }
      }
      prometheus = {
        prometheusSpec = {
          serviceMonitorSelectorNilUsesHelmValues = false
        }
      }
    })
  ]
}

resource "helm_release" "keda" {
  name             = "keda"
  repository       = "https://kedacore.github.io/charts"
  chart            = "keda"
  namespace        = "keda"
  create_namespace = true

  set =[ {
    name  = "watchNamespace"
    value = ""
  } ]
}

resource "helm_release" "istio-base" {
  name       = "istio-base"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "base"
  namespace  = "istio-system"
  create_namespace = true
}

resource "helm_release" "istiod" {
  name       = "istiod"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  namespace  = "istio-system"
  depends_on = [helm_release.istio-base]
}

resource "helm_release" "istio-ingress" {
  name       = "istio-ingress"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  namespace  = "istio-ingress"
  create_namespace = true

  set =[ {
    name  = "gateways.istio-ingressgateway.type"
    value = "LoadBalancer"
  } ]

  depends_on = [helm_release.istiod]
}

resource "helm_release" "istio-egress" {
  name       = "istio-egress"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  namespace  = "istio-egress"
  create_namespace = true

  set =[ {
    name  = "gateways.istio-egressgateway.type"
    value = "ClusterIP"
  } ]

  depends_on = [helm_release.istiod]
}
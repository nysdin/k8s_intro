resource "google_compute_network" "main" {
  name                    = "k8s-the-hard-way"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "k8s_the_hard_way" {
  name          = "k8s-the-hard-way"
  region        = "asia-northeast1"
  ip_cidr_range = "10.240.0.0/24"
  network       = google_compute_network.main.id
}

resource "google_compute_firewall" "kubernetes_the_hard_way_allow_internal" {
  name    = "kubernetes-the-hard-way-allow-internal"
  network = google_compute_network.main.id
  source_ranges = [
    google_compute_subnetwork.k8s_the_hard_way.ip_cidr_range,
    "10.200.0.0/16",
  ]

  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }
  allow {
    protocol = "icmp"
  }
}

resource "google_compute_firewall" "kubernetes_the_hard_way_allow_external" {
  name          = "kubernetes-the-hard-way-allow-external"
  network       = google_compute_network.main.id
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["22", "6443"]
  }
  allow {
    protocol = "icmp"
  }
}

resource "google_compute_firewall" "allow_health_check" {
  name          = "kubernetes-the-hard-way-allow-health-check"
  network       = google_compute_network.main.name
  source_ranges = ["209.85.152.0/22", "209.85.204.0/22", "35.191.0.0/16"] # lb-google
  allow {
    protocol = "tcp"
  }
}

resource "google_compute_address" "kubernetes_the_hard_way" {
  name = "kubernetes-the-hard-way"
}

resource "google_compute_http_health_check" "api_server" {
  name         = "kubernetes"
  description  = "Kubernetes Health Check"
  host         = "kubernetes.default.svc.cluster.local"
  request_path = "/healthz"
}

# google_compute_instance.example.self_link: AWSでいうARNのようなもので各リソースに割り当てられる一意のURL
resource "google_compute_target_pool" "kubernetes" {
  name          = "kubernetes-target-pool"
  health_checks = [google_compute_http_health_check.api_server.name]
  instances     = [for instance in google_compute_instance.controller : instance.self_link]
}

resource "google_compute_forwarding_rule" "kubernetes" {
  name       = "kubernetes-forwarding-rule"
  target     = google_compute_target_pool.kubernetes.id
  port_range = "6443"
  ip_address = google_compute_address.kubernetes_the_hard_way.address
}

resource "aws_ssm_parameter" "spacelift_test" {
  type  = "String"
  name = "/spacelift/test"
  value = "test"
}

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
  name = "kubernetes-the-hard-way-allow-internal"
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
  name = "kubernetes-the-hard-way-allow-external"
  network = google_compute_network.main.id
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports = [ "22", "6443" ]
  }
  allow {
    protocol = "icmp"
  }
}

resource "google_compute_address" "kubernetes_the_hard_way" {
  name = "kubernetes-the-hard-way"
}

resource "google_compute_instance" "controller" {
  for_each = toset(["0", "1"])
  name           = "controller-${each.key}"
  machine_type   = "e2-small"
  zone           = "asia-northeast1-a"
  tags           = ["kubernetes-the-hard-way", "controller"]
  can_ip_forward = true
  boot_disk {
    initialize_params {
      size  = "20"
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
      type  = "pd-standard"
    }
  }
  network_interface {
    network = "kubernetes-the-hard-way"
    subnetwork = "kubernetes"
    network_ip = "10.240.0.1${each.key}"
    access_config {
    }
  }
  service_account {
    scopes = ["compute-rw", "storage-ro", "service-management", "service-control", "logging-write", "monitoring"]
  }
  metadata = {
    "user-data" = file("./templates/cloud-init/controller.yaml")
  }
}


resource "google_compute_instance" "worker" {
  for_each = toset(["0", "1"])
  name           = "worker-${each.key}"
  machine_type   = "e2-small"
  zone           = "asia-northeast1-a"
  tags           = ["kubernetes-the-hard-way", "worker"]
  can_ip_forward = true
  boot_disk {
    initialize_params {
      size  = "20"
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
      type  = "pd-standard"
    }
  }
  network_interface {
    network = "kubernetes-the-hard-way"
    subnetwork = "kubernetes"
    network_ip = "10.240.0.2${each.key}"
    access_config {
    }
  }
  service_account {
    scopes = ["compute-rw", "storage-ro", "service-management", "service-control", "logging-write", "monitoring"]
  }
}

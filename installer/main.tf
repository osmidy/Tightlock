/*
 Copyright 2023 Google LLC

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

      https://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

resource "google_project_service" "compute" {
  project            = var.project_id
  disable_on_destroy = false
  service            = "compute.googleapis.com"
}

resource "google_project_service" "cloudresourcemanager" {
  project            = var.project_id
  disable_on_destroy = false
  service            = "cloudresourcemanager.googleapis.com"
}

resource "google_compute_address" "vm-static-ip" {
  name    = "vm-static-ip"
  project = var.project_id
  region  = "us-central1"
  depends_on = [
    google_project_service.cloudresourcemanager,
    google_project_service.compute
  ]
}

resource "google_compute_instance" "tightlock-backend" {
  name         = "tightlock-backend"
  machine_type = "e2-standard-4"
  zone         = "us-central1-a"
  project      = var.project_id
  tags = ["http-server"]

  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-105-17412-1-75"
    }
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.vm-static-ip.address
    }
  }

  metadata = {
    user-data = templatefile("cloud-config.yaml", { API_KEY = "${var.api_key}" })
  }

  depends_on = [
    google_compute_address.vm-static-ip
  ]
}

output "ConnectionCode" {
  value = base64encode("{'apiKey': '${var.api_key}', 'address': '${google_compute_address.vm-static-ip.address}'}")
}

output "Address" {
  value = google_compute_address.vm-static-ip.address
}


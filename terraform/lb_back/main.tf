terraform {
  required_version = ">= 1.0.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.vm_zone
}

#############################
# UNMANAGED INSTANCE GROUP
#############################
resource "google_compute_instance_group" "uig" {
  name        = var.instance_group_name
  zone        = var.vm_zone
  network     = var.network
  description = "Unmanaged instance group for existing VM"
}

#############################
# ADD EXISTING VM TO INSTANCE GROUP
#############################
resource "google_compute_instance_group_membership" "member" {
  instance_group = google_compute_instance_group.uig.id

  # FIX: ONLY ONE INSTANCE SUPPORTED → USE 'instance'
  instance = "projects/${var.project_id}/zones/${var.vm_zone}/instances/${var.vm_name}"
}

#############################
# HEALTH CHECK
#############################
resource "google_compute_health_check" "hc" {
  name = "ecom-hc"

  http_health_check {
    port         = var.backend_port
    request_path = "/"
  }

  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2
}

#############################
# BACKEND SERVICE
#############################
resource "google_compute_backend_service" "backend" {
  name                  = "ecom-backend"
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL"
  timeout_sec           = 30
  health_checks         = [google_compute_health_check.hc.id]
  port_name             = "http"

  backend {
    group = google_compute_instance_group.uig.self_link
  }
}

#############################
# URL MAP
#############################
resource "google_compute_url_map" "urlmap" {
  name            = "ecom-url-map"
  default_service = google_compute_backend_service.backend.id
}

#############################
# HTTP PROXY
#############################
resource "google_compute_target_http_proxy" "http_proxy" {
  name    = "ecom-http-proxy"
  url_map = google_compute_url_map.urlmap.id
}

#############################
# GLOBAL FORWARDING RULE
#############################
resource "google_compute_global_forwarding_rule" "http_fr" {
  name                  = "ecom-http-fr"
  load_balancing_scheme = "EXTERNAL"
  target                = google_compute_target_http_proxy.http_proxy.self_link
  port_range            = "80"
}

#############################
# FIREWALL RULES (LB → VM)
#############################
resource "google_compute_firewall" "allow_gfe" {
  name    = "allow-gfe-backend"
  network = var.network

  allow {
    protocol = "tcp"
    ports    = [tostring(var.backend_port)]
  }

  source_ranges = [
    "130.211.0.0/22", # LB health check IPs
    "35.191.0.0/16"
  ]

  description = "Allow LB health checks and GFE traffic"
}

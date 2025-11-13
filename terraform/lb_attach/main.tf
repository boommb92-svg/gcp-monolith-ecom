provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Read existing unmanaged instance group
data "google_compute_instance_group" "target_group" {
  name = var.instance_group_name
  zone = var.instance_group_zone
}

# Health check on backend_port
resource "google_compute_health_check" "lb_hc" {
  name = "lb-hc-${var.instance_group_name}"

  http_health_check {
    port         = var.backend_port
    request_path = "/"
  }

  timeout_sec         = 5
  check_interval_sec  = 10
  healthy_threshold   = 2
  unhealthy_threshold = 2
}

# Backend service referencing instance group
resource "google_compute_backend_service" "lb_backend" {
  name                  = "${var.instance_group_name}-backend"
  protocol              = "HTTP"
  health_checks         = [google_compute_health_check.lb_hc.id]
  load_balancing_scheme = "EXTERNAL"
  timeout_sec           = 30

  backend {
    group = data.google_compute_instance_group.target_group.self_link
  }

  # Use a named port name that you will map to the real port on the instance group
  port_name = "http"
}

# URL map and http(s) proxy
resource "google_compute_url_map" "lb_urlmap" {
  name            = "${var.instance_group_name}-urlmap"
  default_service = google_compute_backend_service.lb_backend.id
}

# Optional managed SSL certificate if domain provided
resource "google_compute_managed_ssl_certificate" "managed_cert" {
  count = length(trimspace(var.lb_domain)) > 0 ? 1 : 0
  name  = "${var.instance_group_name}-managed-cert"

  managed {
    domains = [var.lb_domain]
  }
}

# choose HTTPS proxy if cert exists, otherwise create HTTP proxy
resource "google_compute_target_https_proxy" "https_proxy" {
  count   = length(google_compute_managed_ssl_certificate.managed_cert) > 0 ? 1 : 0
  name    = "${var.instance_group_name}-https-proxy"
  url_map = google_compute_url_map.lb_urlmap.id

  ssl_certificates = [
    for c in google_compute_managed_ssl_certificate.managed_cert : c.id
  ]
}

resource "google_compute_target_http_proxy" "http_proxy" {
  count   = length(google_compute_managed_ssl_certificate.managed_cert) > 0 ? 0 : 1
  name    = "${var.instance_group_name}-http-proxy"
  url_map = google_compute_url_map.lb_urlmap.id
}

# Reserve static global IP optionally
resource "google_compute_global_address" "static_ip" {
  count = var.reserve_static_ip ? 1 : 0
  name  = "lb-static-ip"
  project = var.project_id
}

# Global forwarding rule (attach to https or http proxy)
resource "google_compute_global_forwarding_rule" "lb_fr" {
  name                 = "${var.instance_group_name}-fr"
  load_balancing_scheme = "EXTERNAL"
  port_range           = length(google_compute_managed_ssl_certificate.managed_cert) > 0 ? "443" : "80"

  target = length(google_compute_managed_ssl_certificate.managed_cert) > 0 ?
    google_compute_target_https_proxy.https_proxy[0].self_link :
    google_compute_target_http_proxy.http_proxy[0].self_link

  ip_address = var.reserve_static_ip ? google_compute_global_address.static_ip[0].address : null
  # ip_address omitted if not reserving; TF will create ephemeral IP
}

# Firewall: allow GFE (Google Front Ends) to reach backend_port and health checks
resource "google_compute_firewall" "allow_gfe_backend" {
  name    = "${var.instance_group_name}-allow-gfe"
  network = data.google_compute_instance_group.target_group.network

  allow {
    protocol = "tcp"
    ports    = [tostring(var.backend_port)]
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  description   = "Allow Google Front Ends (LB/IAP) to reach backend VMs"
}

# Also allow health checks explicitly (same ranges; included above but kept for clarity)
resource "google_compute_firewall" "allow_healthchecks" {
  name    = "${var.instance_group_name}-allow-healthchecks"
  network = data.google_compute_instance_group.target_group.network

  allow {
    protocol = "tcp"
    ports    = [tostring(var.backend_port)]
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  description   = "Allow load balancer health checks"
}

# Helper: show the gcloud command to set named ports on the instance group (run this once)
resource "null_resource" "set_named_ports_hint" {
  triggers = {
    ig_name = data.google_compute_instance_group.target_group.name
    port    = tostring(var.backend_port)
    zone    = var.instance_group_zone
  }

  provisioner "local-exec" {
    command = "echo 'Run this command once to set named ports: gcloud compute instance-groups set-named-ports ${data.google_compute_instance_group.target_group.name} --named-ports=http:${var.backend_port} --zone=${var.instance_group_zone} --project=${var.project_id}'"
  }
}

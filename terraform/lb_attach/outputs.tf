output "lb_ip" {
  value       = google_compute_global_forwarding_rule.lb_fr.ip_address
  description = "Public IP of the Load Balancer (may be empty until provisioning finishes)"
}

output "lb_forwarding_rule" {
  value = google_compute_global_forwarding_rule.lb_fr.self_link
}

output "backend_service" {
  value = google_compute_backend_service.lb_backend.self_link
}

output "managed_cert_status" {
  value = length(google_compute_managed_ssl_certificate.managed_cert) > 0 ? google_compute_managed_ssl_certificate.managed_cert[0].managed.status : ""
}

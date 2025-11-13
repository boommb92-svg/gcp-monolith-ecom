output "lb_ip" {
  description = "Public IP of the Load Balancer"
  value       = try(google_compute_global_forwarding_rule.lb_fr_https[0].ip_address, google_compute_global_forwarding_rule.lb_fr_http[0].ip_address, "")
}

output "lb_forwarding_rule" {
  description = "Forwarding rule self_link"
  value       = try(google_compute_global_forwarding_rule.lb_fr_https[0].self_link, google_compute_global_forwarding_rule.lb_fr_http[0].self_link, "")
}

output "backend_service" {
  description = "Backend service self_link"
  value       = google_compute_backend_service.lb_backend.self_link
}

output "managed_cert_name" {
  description = "Managed SSL Certificate name (if created)"
  value       = try(google_compute_managed_ssl_certificate.managed_cert[0].name, "")
}

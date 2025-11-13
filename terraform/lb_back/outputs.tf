output "lb_ip" {
  description = "External Load Balancer IP"
  value       = google_compute_global_forwarding_rule.http_fr.ip_address
}

output "backend_service" {
  value = google_compute_backend_service.backend.self_link
}

output "instance_group" {
  value = google_compute_instance_group.uig.self_link
}

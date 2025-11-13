output "lb_ip" {
  description = "Load Balancer External IP"
  value       = google_compute_global_forwarding_rule.http_fr.ip_address
}

output "backend_service" {
  description = "Backend service self_link"
  value       = google_compute_backend_service.backend.self_link
}

output "instance_group" {
  description = "Instance group self_link"
  value       = google_compute_instance_group.uig.self_link
}

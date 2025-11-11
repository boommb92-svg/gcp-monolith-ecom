output "app_vm_ip" {
  description = "Public IP of the App VM"
  value       = google_compute_instance.app.network_interface[0].access_config[0].nat_ip
}

output "jenkins_url" {
  description = "Jenkins URL"
  value       = "http://${google_compute_instance.jenkins.network_interface[0].access_config[0].nat_ip}:8080"
}

output "db_private_ip" {
  value       = google_sql_database_instance.db.private_ip_address
  description = "Private IP of DB"
}

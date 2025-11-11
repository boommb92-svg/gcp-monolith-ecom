locals {
  apis = [
    "compute.googleapis.com",
    "iam.googleapis.com",
    "servicenetworking.googleapis.com",
    "sqladmin.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudresourcemanager.googleapis.com"
  ]
}

resource "google_project_service" "services" {
  for_each           = toset(local.apis)
  service            = each.value
  disable_on_destroy = false
}

resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "app" {
  name          = "app-subnet"
  network       = google_compute_network.vpc.id
  region        = var.region
  ip_cidr_range = var.app_subnet_cidr
}

resource "google_compute_subnetwork" "db" {
  name                     = "db-subnet"
  network                  = google_compute_network.vpc.id
  region                   = var.region
  ip_cidr_range            = var.db_subnet_cidr
  private_ip_google_access = true
}

resource "google_compute_router" "cr" {
  name    = "ecom-cr"
  region  = var.region
  network = google_compute_network.vpc.name
}

resource "google_compute_router_nat" "nat" {
  name                   = "ecom-nat"
  router                 = google_compute_router.cr.name
  region                 = var.region
  nat_ip_allocate_option = "AUTO_ONLY"

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.app.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  subnetwork {
    name                    = google_compute_subnetwork.db.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}

resource "google_service_account" "app" {
  account_id   = "ecom-app-sa"
  display_name = "E-commerce App Service Account"
}

resource "google_service_account" "jenkins" {
  account_id   = "jenkins-sa"
  display_name = "Jenkins Service Account"
}

resource "google_project_iam_member" "app_log" {
  role   = "roles/logging.logWriter"
  member = "serviceAccount:${google_service_account.app.email}"
}

resource "google_project_iam_member" "app_mon" {
  role   = "roles/monitoring.metricWriter"
  member = "serviceAccount:${google_service_account.app.email}"
}

resource "google_project_iam_member" "app_secret" {
  role   = "roles/secretmanager.secretAccessor"
  member = "serviceAccount:${google_service_account.app.email}"
}

resource "google_project_iam_member" "app_sql_client" {
  role   = "roles/cloudsql.client"
  member = "serviceAccount:${google_service_account.app.email}"
}

resource "google_project_iam_member" "jenkins_editor" {
  role   = "roles/editor"
  member = "serviceAccount:${google_service_account.jenkins.email}"
}

resource "random_password" "db" {
  length  = 20
  special = true
}

resource "google_secret_manager_secret" "db_password" {
  secret_id = "db-password"
  replication { automatic = true }
}

resource "google_secret_manager_secret_version" "db_password_v" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db.result
}

resource "google_compute_global_address" "psa" {
  name          = "ecom-psa-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
}

resource "google_service_networking_connection" "vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.psa.name]
}

resource "google_sql_database_instance" "db" {
  name                = "ecom-sql"
  database_version    = var.db_version
  region              = var.region
  deletion_protection = false

  settings {
    tier = var.db_tier

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc.id
    }
  }

  depends_on = [google_service_networking_connection.vpc_connection]
}

resource "google_sql_database" "appdb" {
  name     = var.db_name
  instance = google_sql_database_instance.db.name
}

resource "google_sql_user" "appuser" {
  name     = var.db_user
  instance = google_sql_database_instance.db.name
  password = random_password.db.result
}

resource "google_compute_firewall" "app_http" {
  name    = "app-http-allow"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-allowed"]
}
}

resource "google_compute_firewall" "ssh" {
  count          = var.ssh_source_cidr == null ? 0 : 1
  name           = "allow-ssh"
  network        = google_compute_network.vpc.name
  allow { protocol = "tcp"; ports = ["22"] }
  source_ranges  = [var.ssh_source_cidr]
  target_tags    = ["app-vm", "jenkins-vm"]
}

resource "google_compute_firewall" "jenkins_ui" {
  count   = var.jenkins_allow_cidr == null ? 0 : 1
  name    = "allow-jenkins-ui"
  network = google_compute_network.vpc.name
  allow { protocol = "tcp"; ports = ["8080"] }
  source_ranges = [var.jenkins_allow_cidr]
  target_tags   = ["jenkins-vm"]
}

locals {
  app_startup = <<-EOT
    #!/usr/bin/env bash
    apt-get update
    apt-get install -y nginx
    cat >/var/www/html/index.html <<EOF
    <html><body>
    <h1>E-commerce App Running</h1>
    <p>DB Private IP: ${google_sql_database_instance.db.private_ip_address}</p>
    </body></html>
    EOF
  EOT
}

resource "google_compute_instance" "app" {
  name         = "ecom-app"
  machine_type = var.app_machine_type
  zone         = var.zone
  tags         = ["app-vm"]

  boot_disk {
    initialize_params { image = var.app_image }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.app.id
    access_config {}
  }

  metadata_startup_script = local.app_startup

  service_account {
    email  = google_service_account.app.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}

locals {
  jenkins_startup = <<-EOT
    #!/usr/bin/env bash
    apt-get update
    apt-get install -y openjdk-17-jre wget unzip curl

    TF_VERSION=1.7.5
    wget https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip
    unzip terraform_* -d /usr/local/bin/

    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | tee \
        /usr/share/keyrings/jenkins-keyring.asc > /dev/null
    echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
        https://pkg.jenkins.io/debian-stable binary/ | tee \
        /etc/apt/sources.list.d/jenkins.list > /dev/null

    apt-get update
    apt-get install -y jenkins git
    systemctl restart jenkins
  EOT
}

resource "google_compute_instance" "jenkins" {
  name         = "jenkins"
  machine_type = var.jenkins_machine_type
  zone         = var.zone
  tags         = ["jenkins-vm"]

  boot_disk {
    initialize_params { image = var.app_image }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.app.id
    access_config {}
  }

  metadata_startup_script = local.jenkins_startup

  service_account {
    email  = google_service_account.jenkins.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}

########################
subnetwork = google_compute_subnetwork.app.id
access_config {}
}


service_account {
email = google_service_account.app.email
scopes = ["https://www.googleapis.com/auth/cloud-platform"]
}


metadata = {
db_private_ip = google_sql_database_instance.db.private_ip_address
db_name = var.db_name
db_user = var.db_user
}


metadata_startup_script = local.app_startup
}


########################
# Jenkins VM #
########################
locals {
jenkins_startup = <<-EOT
#!/usr/bin/env bash
set -euxo pipefail
apt-get update
apt-get install -y openjdk-17-jre wget unzip apt-transport-https gnupg curl


# Install Terraform
TF_VER=1.7.5
wget -q https://releases.hashicorp.com/terraform/${TF_VER}/terraform_${TF_VER}_linux_amd64.zip
unzip terraform_*_linux_amd64.zip -d /usr/local/bin


# Install Jenkins
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | tee \
/usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
https://pkg.jenkins.io/debian-stable binary/ | tee \
/etc/apt/sources.list.d/jenkins.list > /dev/null
apt-get update
apt-get install -y jenkins git


systemctl enable jenkins
systemct
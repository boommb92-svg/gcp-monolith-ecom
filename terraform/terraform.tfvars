project_id        = "pavan-477919"
region            = "us-central1"
zone              = "us-central1-a"

ssh_source_cidr    = "10.128.0.2/32"
jenkins_allow_cidr = "10.128.0.2/32"

vpc_name        = "ecom-vpc"
app_subnet_cidr = "10.20.1.0/24"
db_subnet_cidr  = "10.20.2.0/24"

app_machine_type     = "e2-standard-2"
jenkins_machine_type = "e2-standard-2"

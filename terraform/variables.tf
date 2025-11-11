variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "zone" {
  type    = string
  default = "us-central1-a"
}

variable "vpc_name" {
  type    = string
  default = "ecom-vpc"
}

variable "app_subnet_cidr" {
  type    = string
  default = "10.20.1.0/24"
}

variable "db_subnet_cidr" {
  type    = string
  default = "10.20.2.0/24"
}

variable "app_machine_type" {
  type    = string
  default = "e2-standard-2"
}

variable "app_image" {
  type    = string
  default = "projects/debian-cloud/global/images/family/debian-12"
}

variable "jenkins_machine_type" {
  type    = string
  default = "e2-standard-2"
}

variable "jenkins_allow_cidr" {
  type        = string
  default     = null
  description = "YourIP/32 allowed to access Jenkins (8080)"
}

variable "db_tier" {
  type    = string
  default = "db-f1-micro"
}

variable "db_version" {
  type    = string
  default = "MYSQL_8_0"
}

variable "db_name" {
  type    = string
  default = "ecom"
}

variable "db_user" {
  type    = string
  default = "ecomapp"
}

variable "ssh_source_cidr" {
  type        = string
  default     = null
  description = "YourIP/32 allowed for SSH"
}

variable "app_port" {
  type    = number
  default = 80
}

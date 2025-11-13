variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "region" {
  type        = string
  default     = "us-central1"
}

variable "vm_name" {
  type        = string
  description = "Name of the existing VM"
}

variable "vm_zone" {
  type        = string
  default     = "us-central1-a"
}

variable "backend_port" {
  type    = number
  default = 80
}

variable "network" {
  type    = string
  default = "ecom-vpc"
}

variable "instance_group_name" {
  type    = string
  default = "ecom-app-group"
}

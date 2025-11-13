variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "region" {
  type        = string
  default     = "us-central1"
  description = "Region of your backend VM"
}

variable "vm_name" {
  type        = string
  description = "Name of the existing VM to attach to LB"
}

variable "vm_zone" {
  type        = string
  default     = "us-central1-a"
  description = "Zone of the existing VM"
}

variable "backend_port" {
  type        = number
  default     = 80
  description = "Port exposed by your application on the VM"
}

variable "network" {
  type        = string
  default     = "ecom-vpc"
  description = "VPC network name"
}

variable "instance_group_name" {
  type        = string
  default     = "ecom-app-group"
  description = "Name of unmanaged instance group"
}

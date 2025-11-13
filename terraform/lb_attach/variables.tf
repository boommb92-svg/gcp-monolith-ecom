variable "project_id" {
  type = string
  description = "GCP project id"
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "zone" {
  type    = string
  default = "us-central1-a"
}

variable "instance_group_name" {
  type        = string
  description = "Name of existing unmanaged instance group that contains the VM"
}

variable "instance_group_zone" {
  type        = string
  default     = "us-central1-a"
  description = "Zone of the unmanaged instance group"
}

variable "backend_port" {
  type        = number
  default     = 80
  description = "Port on the backend VM that the load balancer should connect to (e.g. 80 or 8080)"
}

variable "reserve_static_ip" {
  type        = bool
  default     = false
  description = "If true, reserve a named global static IP (name: lb-static-ip) and attach it to forwarding rule."
}

variable "lb_domain" {
  type        = string
  default     = ""
  description = "Optional domain for managed SSL (e.g. lb.example.com). Leave empty to use HTTP/IP only"
}

variable "resource_group_name" {
  type        = string
  description = "The name of the RG created at the root."
}

variable "location" {
  type        = string
  description = "The Azure region for the network."
}

variable "hub_cidr" {
  type        = string
  default     = "10.100.0.0/16"
}

variable "spoke_cidr" {
  type        = string
  default     = "10.200.0.0/16"
}
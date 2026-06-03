# This file defines the input variables for the Terraform configuration in the development environment.
variable "location" {
  type        = string
  description = "The Azure region"
}

variable "project_name" {
  type        = string
  description = "Project name for resource naming"
}
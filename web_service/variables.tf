variable "region" {
  type = string
  default = "eu-central-1"
  description = "Used for region and avialability zones"
}

variable "proj_azs" {
  type = list(string)
  default = ["eu-central-1a", "eu-central-1b"]
  description = "We need at least 2 availability zones for LB"
}

variable "proj_name" {
  type = string
  default = "test-task"
  description = "Project name added to all names and tags in main.tf"
}

variable "proj_cidr" {
  type = string
  default = "10.50.48.0/22"
  description = "Determinates network for VPC and some security groups"
}

variable "proj_private_subnets" {
  type = list(string)
  default = ["10.50.50.0/24"]
  description = "Used in VPC module for private subnets. We need only 1 subnet."
}

variable "proj_public_subnets" {
  type = list(string)
  default = ["10.50.48.0/24","10.50.49.0/24"]
  description = "Used in VPC module for public subnetes. We need at least 2 because LB"
}
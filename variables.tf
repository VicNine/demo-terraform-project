variable "aws_region" {
  type        = string
  description = "aws_region"
}

variable "aws_profile" {
  type        = string
  description = "aws_profile"
}

variable "vpc_cidr_block" {
  type        = string
  description = "vpc_cidr_block"
}

variable "subnet_cidr_block" {
  type        = string
  description = "subnet_cidr_block"
}

variable "env_prefix" {
  type        = string
  description = "env_prefix"
}

variable "avail_zone" {
  type        = string
  description = "subnet avail_zone"
}

variable "my_ip" {
  description = "ip white list on sg"
}

variable "instance_type" {}
variable "public_key_location" {}

variable "ami_name" {
  description = "regular expression of ami name"
}

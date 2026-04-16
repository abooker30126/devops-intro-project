variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "ssh_username" {
  type    = string
  default = "ubuntu"
}

variable "ami_name_prefix" {
  type    = string
  default = "control-ubuntu-22.04"
}

variable "ami_description" {
  type    = string
  default = "Control node with Jenkins, Prometheus, Grafana"
}

variable "ami_volume_size" {
  type    = number
  default = 20
}

variable "ami_volume_type" {
  type    = string
  default = "gp3"
}

variable "vpc_id" {
  type    = string
  default = ""
}

variable "subnet_id" {
  type    = string
  default = ""
}

variable "security_group_id" {
  type    = string
  default = ""
}

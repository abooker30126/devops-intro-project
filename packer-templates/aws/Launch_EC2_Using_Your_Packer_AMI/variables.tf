variable "ami_id" {
  description = "AMI ID created by Packer"
  type        = string
}
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}
variable "key_name" {
  description = "Name of the key pair to use for SSH access"
  type        = string
}
variable "subnet_id" {
  description = "ID of the subnet to launch the EC2 instance in"
  type        = string
}
variable "security_group_ids" {
  description = "List of security group IDs to associate with the EC2 instance"
  type        = list(string)
}
variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
  default     = "Packer-EC2-Instance"
}

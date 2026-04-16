output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.control_server.id
}

output "public_ip" {
  description = "Public IP address"
  value       = aws_instance.control_server.public_ip
}

output "public_dns" {
  description = "Public DNS name"
  value       = aws_instance.control_server.public_dns
}

output "ssh_command" {
  description = "SSH command to connect"
  value       = "ssh -i ~/.ssh/${var.key_name} ubuntu@${aws_instance.control_server.public_ip}"
}

output "ssm_command" {
  description = "SSM Session Manager command (no SSH key needed)"
  value       = "aws ssm start-session --target ${aws_instance.control_server.id} --region ${var.aws_region}"
}

output "http_url" {
  description = "HTTP URL to reach Nginx"
  value       = "http://${aws_instance.control_server.public_ip}"
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "bastion_public_ip" {
  description = "Public IP address of Bastion Host"
  value       = aws_instance.bastion.public_ip
}

output "backend_private_ip" {
  description = "Private IP address of Backend EC2"
  value       = aws_instance.backend.private_ip
}

output "mongodb_private_ip" {
  description = "Private IP address of MongoDB EC2"
  value       = aws_instance.mongodb.private_ip
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = aws_lb.main.dns_name
}

output "application_url" {
  description = "HTTP URL for MuchTodo backend"
  value       = "http://${aws_lb.main.dns_name}"
}

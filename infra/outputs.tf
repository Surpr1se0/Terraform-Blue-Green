output "instance_hostname" {
  description = "Private DNS name of the EC2 instance"
  value       = "aws_instance.app_server.private_dns"
}


output "alb_dns" {
  value = aws_lb.app.dns_name
}
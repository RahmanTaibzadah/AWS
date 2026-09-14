output "instance_id" {
  description = "ID of the WordPress EC2 instance"
  value       = aws_instance.wordpress.id
}

output "public_ip" {
  description = "Public IP address of the WordPress instance"
  value       = aws_instance.wordpress.public_ip
}

output "wordpress_url" {
  description = "URL to access the WordPress site"
  value       = "http://${aws_instance.wordpress.public_ip}"
}

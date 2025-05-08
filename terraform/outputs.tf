output "ec2_instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.todo_app.public_ip
}

output "ec2_instance_public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = aws_instance.todo_app.public_dns
}

output "rds_endpoint" {
  description = "Endpoint of the RDS instance"
  value       = aws_db_instance.todo_db.endpoint
}

output "s3_website_endpoint" {
  description = "S3 website endpoint"
  value       = aws_s3_bucket_website_configuration.frontend_website.website_endpoint
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.frontend_bucket.id
}


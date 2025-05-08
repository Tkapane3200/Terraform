variable "aws_region" {
  description = "AWS region"
  type        = string
  #   default     = "us-east-1"
  default = "ap-south-1"
}

variable "ec2_ami" {
  description = "Amazon Machine Image ID for EC2 instance"
  type        = string
  #   default     = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 - update this with the correct AMI for your region
  # default = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 - update this with the correct AMI for your region
  default = "ami-062f0cc54dbfd8ef1" # Amazon Linux 2 - update this with the correct AMI for your region
}

variable "key_pair_name" {
  description = "Name of the key pair for SSH access"
  type        = string
  default     = "mykey"
}

variable "db_username" {
  description = "Username for the RDS MySQL instance"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Password for the RDS MySQL instance"
  type        = string
  sensitive   = true
  default     = "adminadmin" # Change this in production
}

variable "frontend_bucket_name" {
  description = "S3 bucket name for frontend static assets"
  type        = string
  default     = "todo-app-frontend-assets-sunny" # Must be globally unique
}


variable "name" {
  description = "Base name prefix for app resources (e.g. project-env-blue)."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where app instances will run."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for the app Auto Scaling Group."
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID attached to the ALB, used to restrict ingress to app instances."
  type        = string
}

variable "target_group_arn" {
  description = "Target group ARN to register the ASG with (blue or green)."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for app instances."
  type        = string
  default     = "t3.micro"
}

variable "desired_capacity" {
  description = "Desired number of app instances."
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Minimum size of the ASG."
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum size of the ASG."
  type        = number
  default     = 4
}

variable "image_id" {
  description = "AMI ID for app instances (e.g. latest Amazon Linux 2023)."
  type        = string
}

variable "ecr_repository_url" {
  description = "ECR repository URL (without tag) for the app image."
  type        = string
}

variable "image_tag" {
  description = "Tag for the Docker image to run."
  type        = string
  default     = "latest"
}

variable "container_port" {
  description = "Port the application listens on (ALB target group port)."
  type        = number
  default     = 80
}

variable "additional_policy_arns" {
  description = "Additional IAM policy ARNs to attach to the app role (e.g. Secrets Manager read)."
  type        = list(string)
  default     = []
}

# When true, user_data runs the ECR app container with container_env; when false, runs nginx placeholder.
variable "use_app_container" {
  description = "If true, launch template runs the ECR app container; if false, runs nginx placeholder."
  type        = bool
  default     = false
}

# Env vars passed to the app container (e.g. DB_SECRET_ARN, AWS_REGION). Only used when use_app_container is true.
variable "container_env" {
  description = "Environment variables for the app container (key = value). Injected as docker run -e."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Common tags to apply to all resources."
  type        = map(string)
  default     = {}
}


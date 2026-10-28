# ============================================================
# IAM MODULE VARIABLES
# ============================================================

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "ecr_repository_arns" {
  description = "ECR repository ARNs Jenkins may push to (least privilege)."
  type        = list(string)
}

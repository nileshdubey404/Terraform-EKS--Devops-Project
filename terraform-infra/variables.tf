# vrariable definitions for provider
variable "aws_region" {
  type        = string
  description = "AWS region for the infrastructure"
}

variable "project_name" {
  type        = string
  description = "Name of the project"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

#variable definitions for networking module

variable "vpc_cidr_block" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "vpc_name" {
  type        = string
  description = "Name of the VPC"
}

variable "public_subnet_cidr_block" {
  type        = list(string)
  description = "CIDR block for the public subnet"
}

variable "private_subnet_cidr_block" {
  type        = list(string)
  description = "CIDR block for the private subnet"
}

variable "ap_availability_zone" {
  type        = list(string)
  description = "List of availability zones in the region"
}

#######################################

variable "kubernetes_version" {
  type        = string
  default     = "1.33"
  description = "Kubernetes version (string, e.g. \"1.33\"). Check EKS standard-support dates before choosing."
}

variable "cluster_name" {
  type        = string
  default     = "demo-eks-cluster"
  description = "EKS cluster name. Keep in sync with EKS_CLUSTER in the Jenkinsfile."
}

#####

variable "admin_cidr" {
  type        = string
  description = "CIDR allowed to access Jenkins"
}

variable "jenkins_ami_id" {
  description = "AMI ID for Jenkins EC2"
  type        = string
}

variable "jenkins_instance_type" {
  description = "EC2 instance type for Jenkins"
  type        = string
}

variable "jenkins_key_name" {
  description = "Existing EC2 key pair name for Jenkins"
  type        = string
}


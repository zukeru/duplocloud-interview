variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "dev-eks-cluster"
}

variable "instance_type" {
  description = "The instance type for your cluster."
  type        = string
  default     = "m5.large"
}

variable "number_of_nodes" {
  description = "The number of nodes for your cluster."
  type        = string
  default     = "1"
}

variable "max_number_of_nodes" {
  description = "The number of nodes for your cluster."
  type        = string
  default     = "10"
}

variable "min_number_of_nodes" {
  description = "The number of nodes for your cluster."
  type        = string
  default     = "1"
}

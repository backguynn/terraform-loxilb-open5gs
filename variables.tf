////////////////////// Custom Values ////////////////////
variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "ap-northeast-3"
}

variable "key_name" {
  description = "SSH Key for LoxiLB EC2 instances"
  type        = string
  default     = "my-key"
}

variable "ssh_private_key_path" {
  description = "SSH Key file for LoxiLB EC2 access"
  type        = string
  default     = "~/.ssh/my-key.pem"
}

variable "user_name" {
  description = "AWS User Name"
  type        = string
  default     = "my-iam-user"
}

variable "aws_id" {
  description = "AWS ID"
  type        = string
  default     = "123456789012"
}

variable "cluster1_smf_subnet" {
  description = "Subnet for SMF service"
  type        = string
  default     = "10.45.0.1/16"
}

variable "cluster2_smf_subnet" {
  description = "Subnet for SMF service"
  type        = string
  default     = "10.46.0.1/16"
}
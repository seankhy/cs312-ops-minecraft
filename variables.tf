variable "onid" {
  description = "Your ONID, used to name and tag all resources for identification"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the Minecraft server. t3.medium recommended for Minecraft."
  type        = string
  default     = "t3.large"
}

variable "key_name" {
  description = "Name of the existing EC2 key pair used for SSH admin access"
  type        = string
  default     = "cs312-key1"
}

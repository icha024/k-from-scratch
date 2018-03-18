variable "ACCESS_KEY" {
  description = "access key"
}

variable "SECRET_KEY" {
  description = "secret key"
}

variable "security_group_ids" {
  default = ["sg-07939d6f"]
}

variable "key_name" {
  description = "Name of the SSH keypair to use in AWS."
  default     = "Ubt"
}

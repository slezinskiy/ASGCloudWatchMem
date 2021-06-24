variable "region" {
  description = "DefaultRegion"
  type        = string
  default     = "eu-central-1"
}

variable "instance_type" {
  description = "instance_type"
  type        = string
  default     = "t3.nano"
}

variable "key_name" {
  type    = string
  default = "amazon"
}

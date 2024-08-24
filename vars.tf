variable "region" {
    description = "The AWS region where the infrastructure will be deployed"
    type        = string
    default     = "me-south-1"
}
variable "env" {
    description = "The produnce environment"
    type        = string
    default     = "bah-dknz"
}

variable "access_key" {
  description = "AWS access key"
  type        = string
}

variable "secret_key" {
  description = "AWS secret key"
  type        = string
}


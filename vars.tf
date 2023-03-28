variable "default_tags" {
  type = map(string)
  default = {
    "env" = "vo"
  }
  description = "vo variables desciption"
}

variable "public_subnet_count" {
  type        = number
  description = "public subnet count description (OPTIONAL)"
  default     = 2
}
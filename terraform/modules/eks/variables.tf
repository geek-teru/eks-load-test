variable "env" {
  type = string
}

variable "service_name" {
  type = string
}

variable "vpc_id" {
  type    = string
  default = null
}

variable "subnet_ids" {
  type    = list(string)
  default = []
}

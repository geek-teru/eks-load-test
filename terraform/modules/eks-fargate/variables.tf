variable "env" {
  type = string
}

variable "service_name" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

# Pod を Fargate で動かす namespace。CoreDNS のため kube-system は必ず含める
variable "namespaces" {
  type = list(string)
}

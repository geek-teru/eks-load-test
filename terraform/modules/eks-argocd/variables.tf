variable "env" {
  type = string
}

variable "service_name" {
  type = string
}

variable "cluster_name" {
  type = string
}

# Argo CD の UI へのログインに使う Identity Center のインスタンス ARN とリージョン
variable "idc_instance_arn" {
  type = string
}

variable "idc_region" {
  type = string
}

# Argo CD の ADMIN にする Identity Center のグループ ID
variable "admin_group_id" {
  type = string
}

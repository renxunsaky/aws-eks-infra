variable "dns_domain_suffix" {
  type = string
  description = "DNS domain suffix."
}

variable "core_node_group_name_suffix" {
  type = string
  description = "DNS domain suffix."
  default = "eks-core"
}
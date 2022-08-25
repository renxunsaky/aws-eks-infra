variable "tags" {
  type        = map(string)
  description = "A map of tags."
}

variable "role_name" {
  type = string
  description = "Role name for Karpenter."
}

variable "dns_domain_suffix" {
  type = string
  description = "DNS domain suffix."
}

variable "core_node_group_name_suffix" {
  type = string
  description = "DNS domain suffix."
  default = "eks-core"
}
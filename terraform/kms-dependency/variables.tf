variable "vpc_id" {
  type        = string
  description = "ID of virtual private cloud."
}

variable "tags" {
  type        = map(string)
  description = "A map of tags."
}
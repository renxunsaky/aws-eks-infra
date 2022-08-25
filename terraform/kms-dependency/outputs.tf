output "key_arn" {
  value       = data.terraform_remote_state.key.outputs.arn
  description = "ARN of KMS key."
}
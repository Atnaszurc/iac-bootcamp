variable "subscription_id" {
  description = "Azure subscription ID. Can also be set via ARM_SUBSCRIPTION_ID env var."
  type        = string
  default     = "" # Set via env var ARM_SUBSCRIPTION_ID or az login
}
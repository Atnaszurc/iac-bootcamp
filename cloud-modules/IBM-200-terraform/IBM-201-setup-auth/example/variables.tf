variable "ibm_region" {
  description = "IBM Cloud region to use for this lesson."
  type        = string
  default     = "us-south"

  validation {
    condition = contains([
      "au-syd",
      "br-sao",
      "ca-tor",
      "eu-de",
      "eu-es",
      "eu-gb",
      "jp-osa",
      "jp-tok",
      "us-east",
      "us-south",
    ], var.ibm_region)
    error_message = "ibm_region must be a supported IBM Cloud region used by this course."
  }
}

variable "resource_group_name" {
  description = "IBM Cloud resource group name to resolve for the lesson example."
  type        = string
  default     = "Default"
}

variable "environment" {
  description = "Environment label used for naming and tagging examples."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "test", "stage", "prod"], lower(var.environment))
    error_message = "environment must be one of: dev, test, stage, prod."
  }
}

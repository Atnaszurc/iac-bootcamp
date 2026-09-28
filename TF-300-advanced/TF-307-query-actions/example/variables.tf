variable "environment" {
  description = "Deployment environment written into each service config"
  type        = string
  default     = "dev"
}

variable "app_version" {
  description = "Application version — change it to trigger after_update actions"
  type        = string
  default     = "1.0.0"
}

variable "services" {
  description = "Services to generate config files for"
  type = map(object({
    port = number
  }))
  default = {
    api    = { port = 8080 }
    worker = { port = 9090 }
  }
}

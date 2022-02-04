variable "resource_group_name" {
  default = "BookWorkzSlackBot"
}

variable "resource_group_location"{
  default = "westeurope"
}

variable "failover_location"{
  default = "northeurope"
}

variable "resource_group_environment"{
  default = "Dev"
}

variable "app_service_plan_tier"{
  default = "Dynamic"
}

variable "app_service_plan_size"{
  default = "Y1"
}

variable "slack_api_token" {
  type        = string
  description = "OAUTH token to communicate to slack with."

  validation {
    condition     = length(var.slack_api_token) > 4 && substr(var.slack_api_token, 0, 4) == "xoxb"
    error_message = "The token should start with xoxb."
  }
}
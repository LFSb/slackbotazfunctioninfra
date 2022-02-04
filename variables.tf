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
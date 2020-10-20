  
variable "resource_group_name" {
  description = "The name for a resource group. This will allow us to get the other attributes necessary."
}

variable "function_size" {
  description = "The SKU indicating instance size. These can be retrieved by running Get-AzVmSize cmdlet."
  default     = "Y1"
}

variable "function_tier" {
  description = "The tier relating to the SKU of the App Service."
  default     = "Dynamic"
}

variable "name" {
  description = "This name will be used with defaults as a unique identifier"
}

variable "env" {
  description = "An identifier for the environment. d for dev, t for test, p for prod"
}

variable "os" {
  type        = string
  description = "Windows or Linux. Defaults to Windows."
  default     = "windows"
}

variable "function_runtime_version" {
  description = "What is the runtime version we want for this function?"
  default = "~2"
}
variable "namespace" {
  type        = string
  description = "Namespace (e.g. `ml` or `milli`)"
}

variable "enabled" {
  type        = string
  description = "Set to false to prevent the module from creating any resources"
  default     = "true"
}

variable "stage" {
  type        = string
  description = "Stage (e.g. `prod`, `dev`, `staging`)"
}

variable "delimiter" {
  type        = string
  default     = "-"
  description = "Delimiter to be used between `namespace`, `stage`, `name`, and `attributes`"
}

variable "attributes" {
  type        = list(any)
  default     = []
  description = "Additional attributes (e.g. `policy` or `role`)"
}

variable "tags" {
  type        = map(any)
  default     = {}
  description = "Additional tags (e.g. map(`BusinessUnit`,`XYZ`)"
}

variable "switchrole_url" {
  type        = string
  description = "URL to the IAM console to switch to a role"
  default     = "https://signin.aws.amazon.com/switchrole?account=%s&roleName=%s&displayName=%s"
}

###################################################################
# Name of the Group and Role 
###################################################################

variable "admin_name" {
  type        = string
  default     = "admin"
  description = "Name for the admin group and role (e.g. `admin`)"
}

variable "readonly_name" {
  type        = string
  default     = "readonly"
  description = "Name for the readonly group and role (e.g. `readonly`)"
}

variable "security_name" {
  type        = string
  default     = "security"
  description = "Name for the admin group and role (e.g. `security`)"
}

variable "leaddeveloper_name" {
  type        = string
  default     = "leaddeveloper"
  description = "Name for the leaddeveloper group and role (e.g. `leaddeveloper`)"
}

variable "frontenddeveloper_name" {
  type        = string
  default     = "frontenddeveloper"
  description = "Name for the frontenddeveloper group and role (e.g. `frontenddeveloper`)"
}

variable "backenddeveloper_name" {
  type        = string
  default     = "backenddeveloper"
  description = "Name for the backenddeveloper group and role (e.g. `backenddeveloper`)"
}

variable "platform_name" {
  type        = string
  default     = "platform"
  description = "Name for the platform group and role (e.g. `platform`)"
}

variable "qualityassurance_name" {
  type        = string
  default     = "qualityassurance"
  description = "Name for the qualityassurance group and role (e.g. `qualityassurance`)"
}

variable "projectteam_name" {
  type        = string
  default     = "projectteam"
  description = "Name for the projectteam group and role (e.g. `admin`)"
}

variable "developer_name" {
  type        = string
  default     = "developer"
  description = "Name for the developer group and role (e.g. `admin`)"
}
###################################################################
# List of IAM Users to add to groups
###################################################################

variable "admin_user_names" {
  type        = list(any)
  default     = []
  description = "Optional list of IAM user names to add to the admin group"
}


variable "readonly_user_names" {
  type        = list(any)
  default     = []
  description = "Optional list of IAM user names to add to the readonly group"
}

variable "security_user_names" {
  type        = list(any)
  default     = []
  description = "Optional list of IAM user names to add to the security group"
}

variable "leaddeveloper_user_names" {
  type        = list(any)
  default     = []
  description = "Optional list of IAM user names to add to the leaddeveloper group"
}

variable "frontenddeveloper_user_names" {
  type        = list(any)
  default     = []
  description = "Optional list of IAM user names to add to the frontenddeveloper group"
}

variable "backenddeveloper_user_names" {
  type        = list(any)
  default     = []
  description = "Optional list of IAM user names to add to the backenddeveloper group"
}

variable "platform_user_names" {
  type        = list(any)
  default     = []
  description = "Optional list of IAM user names to add to the platform group"
}

variable "qualityassurance_user_names" {
  type        = list(any)
  default     = []
  description = "Optional list of IAM user names to add to the qualityassurance group"
}

variable "projectteam_user_names" {
  type        = list(any)
  default     = []
  description = "Optional list of IAM user names to add to the projectteam group"
}

variable "developer_user_names" {
  type        = list(any)
  default     = []
  description = "Optional list of IAM user names to add to the developer group"
}

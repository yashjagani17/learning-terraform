variable "db_username" {
  description = "Username for the AWS MySQL database"
  type = string
  sensitive = true
}

variable "db_password" {
    description = "Password for the AWS MySQL database"
    type = string
    sensitive = true
}
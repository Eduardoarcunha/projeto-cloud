variable "private_subnets_cidr_blocks" {
  type = list(string)
  default = [
    "10.0.101.0/24",
    "10.0.102.0/24"
  ]
}

variable "db_username" {
    description = "Master user of the db"
    type = string
    sensitive = true
}

variable "db_password" {
    description = "Master password of the db"
    type = string
    sensitive = true
}
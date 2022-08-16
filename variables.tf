variable "region" {
	type = string
}

variable "vpc_cidr" {
	type = string
}

variable "env" {
	type = string
}

variable "pub_cidr" {
	type = list(string)
}

variable "lightsail_cidr" {
	type = list(string)
}

variable "db_cidr" {
	type = list(string)
}

variable "db_name" {
	type = string
}

variable "azs" {
	type = list(string)
}

variable "instance_name" {
	type = list (string)
}

variable "wp_blueprint_id" {
	type = string
	default = "wordpress"
}

variable "bundle_id" {
	type = string
	default = "nano_2_0"
}

variable "ingress_config" {
  type = list(object({
    port        = string
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
    {
      port        = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      port        = 3306
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    }
  ]
  description = "list of ingress config"
}

variable "allocated_storage" { default = 10 }

variable "storage_type" { default = "gp2" }

variable "db_username" { default = "admin"  }

variable "engine" { default = "mysql" }

variable "engine_version" { default = "8.0.20" }

variable "db_instance" { default = "db.t2.micro" }

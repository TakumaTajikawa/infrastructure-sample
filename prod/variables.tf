variable "env" {
  default = "prod"
}

variable "region" {
  default = "ap-northeast-1"
}

variable "tf_s3_bucket" {
  default = "offkai-terraform"
}

variable "common_state_file" {
  default = "common.terraform.tfstate"
}

variable "domain" {
  default = "offkai.site"
}

variable "project" {
  default = "offkai"
}

variable "availability_zones" {
  type = map(number)
  default = {
    ap-northeast-1a = 0
    ap-northeast-1c = 1
    ap-northeast-1d = 2
  }
}

variable "mysql_password" {
  type = string
}

variable "region" {
  type = string
  default = "ap-southeast-1"
}

variable "def_tag" {
  type = map
  default = {
    "Name" = "VPC-singa"
    "type" = "Network"
  }
}

variable "zones" {
  type = list
  default = ["ap-southeast-1a","ap-southeast-1b"]
}

variable "singa_igw" {
  type = string
  default = "main_igw"
}

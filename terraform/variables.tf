variable "profile" {
  type    = string
  default = "default"
}

variable "region_master" {
  type    = string
  default = "us-east-1"
}

variable "region_worker" {
  type    = string
  default = "us-west-2"
}

variable "vpc_master_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "vpc_worker_cidr" {
  type    = string
  default = "192.168.0.0/16"
}

variable "master_subnets" {
  type    = number
  default = 2
}

variable "external_ip" {
  type    = string
  default = "0.0.0.0/0"
}

variable "intance_key_name" {
  type    = string
  default = "key"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "worker_count" {
  type    = number
  default = 2
}

variable "webserver_port" {
  type    = number
  default = 80
}
locals {
  worker_cidr_sbnt = cidrsubnet(var.vpc_worker_cidr, 8, 1)
  master_cidr_sbnt = cidrsubnet(var.vpc_master_cidr, 8, 1)
}
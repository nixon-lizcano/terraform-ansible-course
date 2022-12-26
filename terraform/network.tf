# Create VPCs
resource "aws_vpc" "vpc_master" {
  provider = aws.region_master

  cidr_block           = var.vpc_master_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "master-vpc-jenkins"
  }
}

resource "aws_vpc" "vpc_master_oregon" {
  provider = aws.region_worker

  cidr_block           = var.vpc_worker_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "master-vpc-jenkins"
  }
}

# Create internet gateways
resource "aws_internet_gateway" "igw" {
  provider = aws.region_master
  vpc_id   = aws_vpc.vpc_master.id
}

resource "aws_internet_gateway" "igw_oregon" {
  provider = aws.region_worker
  vpc_id   = aws_vpc.vpc_master_oregon.id
}

# Create subnets in master
resource "aws_subnet" "subnets_master" {
  count             = var.master_subnets
  provider          = aws.region_master
  availability_zone = element(data.aws_availability_zones.azs.names, count.index)
  vpc_id            = aws_vpc.vpc_master.id
  cidr_block        = cidrsubnet(var.vpc_master_cidr, 8, count.index + 1)
}

# Create subnets in worker
resource "aws_subnet" "subnet_worker" {
  provider   = aws.region_worker
  vpc_id     = aws_vpc.vpc_master_oregon.id
  cidr_block = local.worker_cidr_sbnt
}

# Initiate Peering connection request from master
resource "aws_vpc_peering_connection" "master2worker" {
  provider    = aws.region_master
  vpc_id      = aws_vpc.vpc_master.id
  peer_vpc_id = aws_vpc.vpc_master_oregon.id
  peer_region = var.region_worker
}

# Accept VPC peering request in worker from master
resource "aws_vpc_peering_connection_accepter" "accept_peering" {
  provider                  = aws.region_worker
  vpc_peering_connection_id = aws_vpc_peering_connection.master2worker.id
  auto_accept               = true
}

# Create route table in master
resource "aws_route_table" "internet_route" {
  provider = aws.region_master
  vpc_id   = aws_vpc.vpc_master.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  route {
    cidr_block                = local.worker_cidr_sbnt
    vpc_peering_connection_id = aws_vpc_peering_connection.master2worker.id
  }

  lifecycle {
    ignore_changes = all
  }
  tags = {
    Name = "Master-Region-RT"
  }
}

# Overwrite default route table of VPC(Master) with our route table entries
resource "aws_main_route_table_association" "set_master_default_rt_assoc" {
  provider       = aws.region_master
  vpc_id         = aws_vpc.vpc_master.id
  route_table_id = aws_route_table.internet_route.id
}

# Create route table in worker
resource "aws_route_table" "internet_route_oregon" {
  provider = aws.region_worker
  vpc_id   = aws_vpc.vpc_master_oregon.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_oregon.id
  }
  route {
    cidr_block                = local.master_cidr_sbnt
    vpc_peering_connection_id = aws_vpc_peering_connection.master2worker.id
  }

  lifecycle {
    ignore_changes = all
  }
  tags = {
    Name = "Worker-Region-RT"
  }
}

# Overwrite default route table of VPC(Worker) with our route table entries
resource "aws_main_route_table_association" "set_worker_default_rt_assoc" {
  provider       = aws.region_worker
  vpc_id         = aws_vpc.vpc_master_oregon.id
  route_table_id = aws_route_table.internet_route_oregon.id
}
# Get all available AZ's in VPC for master region
data "aws_availability_zones" "azs" {
  provider = aws.region_master
  state    = "available"
}
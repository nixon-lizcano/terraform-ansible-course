# Get all available AZ's in VPC for master region
data "aws_availability_zones" "azs" {
  provider = aws.region_master
  state    = "available"
}

# Get Linux AMI ID ussing SSM Parameter endpoint in master
data "aws_ssm_parameter" "linux_AMI_master" {
  provider = aws.region_master
  name     = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

# Get Linux AMI ID ussing SSM Parameter endpoint in worker
data "aws_ssm_parameter" "linux_AMI_worker" {
  provider = aws.region_worker
  name     = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}
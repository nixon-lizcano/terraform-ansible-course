terraform {
  backend "s3" {
    bucket         = "terraform-1672083986-bucket"
    key            = "terraform/terraform.tfstate"
    dynamodb_table = "terraform_tf_state_1672083986"
    region         = "us-east-1"
  }
}

terraform {
  backend "s3" {
    key     = "cloud-obligatorio/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
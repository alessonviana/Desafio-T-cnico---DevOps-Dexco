terraform {
  backend "s3" {
    bucket = "dexco-terraform-state"
    key    = "development/eu-central-1/ecs/terraform.tfstate"
    region = "eu-central-1"
}
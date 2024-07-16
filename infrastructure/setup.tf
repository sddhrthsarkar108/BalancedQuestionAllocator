provider "aws" {
  region = "ap-south-1"
}

terraform {
  backend "s3" {
    bucket = "question_allocator_poc"
    key    = "tf-state"
    region = "us-east-1"
  }
}
terraform {
  backend "s3" {
    bucket       = "aws-infra-remote-backend-tfstate-bucket-123456"
    key          = "s3-backend/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true # encrypt state at rest
    use_lockfile = true # S3-native locking, prevents concurrent applies
  }
}

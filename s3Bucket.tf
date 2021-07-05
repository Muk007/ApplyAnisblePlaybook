resource "aws_s3_bucket" "ssm_output" {
  bucket        = var.s3_bucket_name
  acl           = "private"
  force_destroy = true
  tags = {
    Name        = "ssm-output-bucket"
    Environment = "Test"
  }
}

resource "aws_s3_bucket" "drohealth-tf-state" {
  bucket = "drohealth-tf-state"
  lifecycle {
    # prevent_destroy = true
  }
}


resource "aws_dynamodb_table" "test_EHR_tf_lock_db" {
  name = "test_EHR_tf_lock_db"
  hash_key = "LockID"
  read_capacity  = 5
  write_capacity = 5

  attribute {
    name = "LockID"
    type = "S"
  }
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.drohealth-tf-state.arn
  description = "The ARN of the S3 bucket"
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.test_EHR_tf_lock_db.name
  description = "The name of the DynamoDB table"
}
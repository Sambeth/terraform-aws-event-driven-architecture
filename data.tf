data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "archive_file" "lambda_script_zip" {
  source_dir  = "${path.module}/scripts/"
  output_path = "${path.module}/scripts.zip"
  type        = "zip"
}
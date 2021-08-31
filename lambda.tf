resource "aws_iam_role" "iam_role_lambda" {
  name = "lambda-iam-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "iam_policy_lambda" {
  name        = "lambda-role-policy"
  description = "Policy for lambda role"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "sqs:SendMessage"
      ],
      "Resource": "${aws_sqs_queue.standard_dead_letter_queue.arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "sns:Publish"
      ],
      "Resource": "${aws_sns_topic.sns_topic.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_role_policy_attachment" {
  policy_arn = aws_iam_policy.iam_policy_lambda.arn
  role       = aws_iam_role.iam_role_lambda.name
}

resource "aws_lambda_function" "publish_to_sns_function" {
  function_name    = "Publish-To-SNS"
  handler          = "publish_to_sns.handler"
  role             = aws_iam_role.iam_role_lambda.arn
  runtime          = "python3.8"
  filename         = data.archive_file.lambda_script_zip.output_path
  source_code_hash = data.archive_file.lambda_script_zip.output_base64sha256
  dead_letter_config {
    target_arn = aws_sqs_queue.standard_dead_letter_queue.arn
  }
}

resource "aws_lambda_permission" "lambda_allow_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.publish_to_sns_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.rest_api_gateway.execution_arn}/*/*/*"
}
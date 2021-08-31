resource "aws_sns_topic" "sns_topic" {
  name                              = "sns-topic.fifo"
  fifo_topic                        = true
  content_based_deduplication       = true
  http_success_feedback_sample_rate = 100
  http_success_feedback_role_arn    = aws_iam_role.sns_success_feedback_role.arn
  http_failure_feedback_role_arn    = aws_iam_role.sns_failure_feedback_role.arn

  //  kms_master_key_id = ""
}

// sns policy
data "aws_iam_policy_document" "sns_topic_subs_policy" {
  statement {
    sid    = "Limit topic subscription to SQS"
    effect = "Allow"

    principals {
      identifiers = ["*"]
      type        = "AWS"
    }
    actions = [
      "sns:Subscribe"
    ]
    resources = [
      aws_sns_topic.sns_topic.arn
    ]
    condition {
      test = "ArnEquals"
      values = [
        aws_sqs_queue.products_sqs_queue.arn
      ]
      variable = "aws:SourceArn"
    }
  }

  statement {
    sid    = "Limit topic publishing to user"
    effect = "Allow"

    principals {
      identifiers = [
        aws_iam_role.iam_role_lambda.arn
      ]
      type        = "AWS"
    }
    actions = [
      "sns:Publish"
    ]
    resources = [
      aws_sns_topic.sns_topic.arn
    ]

    condition {
      test = "ArnEquals"
      values = [
        data.aws_caller_identity.current.arn
      ]
      variable = "aws:SourceArn"
    }
  }
}

resource "aws_sns_topic_policy" "bloom_products_topic_policy" {
  arn    = aws_sns_topic.sns_topic.arn
  policy = data.aws_iam_policy_document.sns_topic_subs_policy.json
}

// roles for logging delivery in cloudwatch
// success role
resource "aws_iam_role" "sns_success_feedback_role" {
  name_prefix = "sns_success_delivery_logging-"
  description = "Role to log successful message delivery by SNS in Cloudwatch"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "sns.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "sns_success_feedback_role_iam_policy" {
  name_prefix = "sns_success_delivery_logging-"
  description = "IAM policy for SNS to log to Cloudwatch"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:PutMetricFilter",
        "logs:PutRetentionPolicy"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "sns_success_feedback_role_policy_attachment" {
  role       = aws_iam_role.sns_success_feedback_role.name
  policy_arn = aws_iam_policy.sns_success_feedback_role_iam_policy.arn
}

// failure role
resource "aws_iam_role" "sns_failure_feedback_role" {
  name_prefix = "sns_failed_delivery_logging-"
  description = "Role to log failed message delivery by SNS in Cloudwatch"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "sns.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "sns_failure_feedback_role_iam_policy" {
  name_prefix = "sns_failed_delivery_logging-"
  description = "IAM policy for SNS to log to Cloudwatch"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:PutMetricFilter",
        "logs:PutRetentionPolicy"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "sns_failure_feedback_role_policy_attachment" {
  role       = aws_iam_role.sns_failure_feedback_role.name
  policy_arn = aws_iam_policy.sns_failure_feedback_role_iam_policy.arn
}

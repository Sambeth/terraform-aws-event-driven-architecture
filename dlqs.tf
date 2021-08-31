// fifo dlq
resource "aws_sqs_queue" "fifo_dead_letter_queue" {
  name                        = "dead_letter_queue.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  max_message_size            = 2048
  visibility_timeout_seconds  = 600
  message_retention_seconds   = 1209600 // 14 days
  //  kms_master_key_id = ""
}

resource "aws_sqs_queue_policy" "fifo_dead_letter_queue_policy" {
  queue_url = aws_sqs_queue.fifo_dead_letter_queue.id
  policy    = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "DeadLetterSQSPolicy",
  "Statement": [
    {
      "Sid": "EventsTo",
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ],
      "Resource": "${aws_sqs_queue.fifo_dead_letter_queue.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "${data.aws_caller_identity.current.arn}"
        }
      }
    },
    {
      "Sid": "FromSNS",
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "sqs:SendMessage"
      ],
      "Resource": "${aws_sqs_queue.fifo_dead_letter_queue.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": [
            "${aws_sns_topic.sns_topic.arn}",
            "${aws_sqs_queue.products_sqs_queue.arn}"
          ]
        }
      }
    }
  ]
}
POLICY
}

// standard dlq
resource "aws_sqs_queue" "standard_dead_letter_queue" {
  name                       = "standard_dead_letter_queue"
  max_message_size           = 2048
  visibility_timeout_seconds = 600
  message_retention_seconds  = 1209600 // 14 days
  //  kms_master_key_id = ""
}

resource "aws_sqs_queue_policy" "standard_letter_queue_policy" {
  queue_url = aws_sqs_queue.standard_dead_letter_queue.id
  policy    = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "DeadLetterSQSPolicy",
  "Statement": [
    {
      "Sid": "EventsTo",
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ],
      "Resource": "${aws_sqs_queue.standard_dead_letter_queue.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "${data.aws_caller_identity.current.arn}"
        }
      }
    },
    {
      "Sid": "FromSNS",
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "sqs:SendMessage"
      ],
      "Resource": "${aws_sqs_queue.standard_dead_letter_queue.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": [
            "${aws_lambda_function.publish_to_sns_function.arn}"
          ]
        }
      }
    }
  ]
}
POLICY
}

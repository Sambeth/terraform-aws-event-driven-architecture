resource "aws_sqs_queue" "products_sqs_queue" {
  name                        = "products-sqs-queue.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  max_message_size            = 2048
  visibility_timeout_seconds  = 600
  message_retention_seconds   = 1209600 // 14 days
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.fifo_dead_letter_queue.arn
    maxReceiveCount     = 4
  })
  //  kms_master_key_id = ""
}

resource "aws_sqs_queue_policy" "products_sqs_queue_policy" {
  queue_url = aws_sqs_queue.products_sqs_queue.id
  policy    = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "BloomProductsSQSPolicy",
  "Statement": [
    {
      "Sid": "EventsToNIFI",
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ],
      "Resource": "${aws_sqs_queue.products_sqs_queue.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "${data.aws_caller_identity.current.arn}"
        }
      }
    },
    {
      "Sid": "EventsFromSNS",
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "sqs:SendMessage"
      ],
      "Resource": "${aws_sqs_queue.products_sqs_queue.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "${aws_sns_topic.sns_topic.arn}"
        }
      }
    }
  ]
}
POLICY
}

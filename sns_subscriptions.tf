resource "aws_sns_topic_subscription" "products_topic_subscription" {
  endpoint  = aws_sqs_queue.products_sqs_queue.arn
  protocol  = "sqs"
  topic_arn = aws_sns_topic.sns_topic.arn
  filter_policy = jsonencode({
    "ProductType" : [
      "PRODUCTS"
    ]
  })
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.fifo_dead_letter_queue.arn
  })
}

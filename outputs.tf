output "region_name" {
  value = data.aws_region.current.name
}

output "sns_topic" {
  value = aws_sns_topic.sns_topic.arn
}

output "bloom_product_sqs_queue" {
  value = aws_sqs_queue.products_sqs_queue.arn
}

output "invoke_arn" {
  value = aws_api_gateway_deployment.rest_api_gateway_deployment.invoke_url
}

output "stage_name" {
  value = aws_api_gateway_stage.rest_api_gateway_stage.stage_name
}

output "path_part" {
  value = aws_api_gateway_resource.rest_api_gateway_resource.path_part
}

output "complete_url" {
  value = "${aws_api_gateway_deployment.rest_api_gateway_deployment.invoke_url}${aws_api_gateway_stage.rest_api_gateway_stage.stage_name}/${aws_api_gateway_resource.rest_api_gateway_resource.path_part}"
}
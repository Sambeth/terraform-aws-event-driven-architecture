resource "aws_api_gateway_rest_api" "rest_api_gateway" {
  name = "Lambda-REST-API-Gateway"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "rest_api_gateway_resource" {
  parent_id   = aws_api_gateway_rest_api.rest_api_gateway.root_resource_id
  path_part   = "publish"
  rest_api_id = aws_api_gateway_rest_api.rest_api_gateway.id
}

resource "aws_api_gateway_method" "rest_api_gateway_post_method" {
  authorization = "NONE"
  http_method   = "POST"
  resource_id   = aws_api_gateway_resource.rest_api_gateway_resource.id
  rest_api_id   = aws_api_gateway_rest_api.rest_api_gateway.id
}

resource "aws_api_gateway_method_response" "rest_api_gateway_response_200" {
  rest_api_id = aws_api_gateway_rest_api.rest_api_gateway.id
  resource_id = aws_api_gateway_resource.rest_api_gateway_resource.id
  http_method = aws_api_gateway_method.rest_api_gateway_post_method.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

//resource "aws_api_gateway_integration_response" "rest_api_gateway_integration_response_200" {
//  rest_api_id = aws_api_gateway_rest_api.rest_api_gateway.id
//  resource_id = aws_api_gateway_resource.rest_api_gateway_resource.id
//  http_method = aws_api_gateway_method.rest_api_gateway_post_method.http_method
//  status_code = aws_api_gateway_method_response.rest_api_gateway_response_200.status_code
//}

resource "aws_api_gateway_method_response" "rest_api_gateway_response_400" {
  rest_api_id = aws_api_gateway_rest_api.rest_api_gateway.id
  resource_id = aws_api_gateway_resource.rest_api_gateway_resource.id
  http_method = aws_api_gateway_method.rest_api_gateway_post_method.http_method
  status_code = "400"
  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "rest_api_gateway_integration_response_400" {
  rest_api_id = aws_api_gateway_rest_api.rest_api_gateway.id
  resource_id = aws_api_gateway_resource.rest_api_gateway_resource.id
  http_method = aws_api_gateway_method.rest_api_gateway_post_method.http_method
  status_code = aws_api_gateway_method_response.rest_api_gateway_response_400.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [aws_api_gateway_integration.rest_api_gateway_integration]
}

resource "aws_api_gateway_integration" "rest_api_gateway_integration" {
  http_method             = aws_api_gateway_method.rest_api_gateway_post_method.http_method
  resource_id             = aws_api_gateway_resource.rest_api_gateway_resource.id
  rest_api_id             = aws_api_gateway_rest_api.rest_api_gateway.id
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.publish_to_sns_function.invoke_arn
}

resource "aws_api_gateway_deployment" "rest_api_gateway_deployment" {
  rest_api_id = aws_api_gateway_rest_api.rest_api_gateway.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.rest_api_gateway.body))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_method.rest_api_gateway_post_method,
    aws_api_gateway_integration.rest_api_gateway_integration
  ]
}

resource "aws_api_gateway_stage" "rest_api_gateway_stage" {
  deployment_id = aws_api_gateway_deployment.rest_api_gateway_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.rest_api_gateway.id
  stage_name    = "dev"
}
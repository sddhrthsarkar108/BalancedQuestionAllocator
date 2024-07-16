# get s3 bucket details
data "aws_s3_bucket" "storage" {
  bucket = "question-allocator-lambda-poc"
}

# create and upload lambda zip to s3
# data "archive_file" "lambda_handler" {
#   type = "zip"

#   source_dir  = "${path.module}/../lambda/handler"
#   output_path = "${path.module}/lambda/handler.zip"
# }

resource "aws_s3_object" "lambda_handler" {
  bucket = data.aws_s3_bucket.storage.id

  key    = "lambda/handler.zip"
  source = "${path.module}/lambda/handler.zip"

  source_hash = filebase64sha256("${path.module}/lambda/handler.zip")
}

# create and upload lambda layer zip to s3
# resource "terraform_data" "lambda_layer" {
#   input = filebase64sha256("${path.module}/../lambda/layer/requirements.txt")

#   provisioner "local-exec" {
#     command = <<EOT
#       mkdir python
#       pip3 install --platform manylinux2014_x86_64 -t python/ --python-version 3.12 --only-binary=:all: -r ${path.module}/../lambda/layer/requirements.txt
#       zip -r ${path.module}/lambda/layer.zip python/
#     EOT
#   }
# }

resource "aws_s3_object" "lambda_layer" {
  bucket = data.aws_s3_bucket.storage.id

  key    = "lambda/layer.zip"
  source = "${path.module}/lambda/layer.zip"

  source_hash = filebase64sha256("${path.module}/lambda/layer.zip")
}

resource "aws_lambda_layer_version" "lambda_layer" {
  s3_bucket           = data.aws_s3_bucket.storage.id
  s3_key              = aws_s3_object.lambda_layer.key
  layer_name          = "question_allocator_lambda_layer"
  compatible_runtimes = ["python3.12"]
  source_code_hash    = filebase64sha256("${path.module}/lambda/layer.zip")
  depends_on          = [aws_s3_object.lambda_layer]
}

# create role for lambda
resource "aws_iam_role" "lambda_exec" {
  name = "question_allocator_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# create lambda function
resource "aws_lambda_function" "lambda_handler" {
  function_name = "question_allocator_lambda"

  s3_bucket = data.aws_s3_bucket.storage.id
  s3_key    = aws_s3_object.lambda_handler.key

  runtime = "python3.12"
  handler = "main.lambda_handler"
  layers  = [aws_lambda_layer_version.lambda_layer.arn]
  timeout = 360

  source_code_hash = filebase64sha256("${path.module}/lambda/handler.zip")

  role = aws_iam_role.lambda_exec.arn
}

resource "aws_cloudwatch_log_group" "lambda_handler" {
  name = "/aws/lambda/${aws_lambda_function.lambda_handler.function_name}"

  retention_in_days = 30
}

# create api gateway
resource "aws_apigatewayv2_api" "lambda_handler" {
  name          = "question_allocator_lambda_gw"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["*"]
    allow_headers = ["*"]
    expose_headers = ["*"]
    max_age = 3000
  }
}

resource "aws_cloudwatch_log_group" "lambda_handler_gw" {
  name              = "/aws/api_gw/${aws_apigatewayv2_api.lambda_handler.name}"
  retention_in_days = 30
}

resource "aws_apigatewayv2_stage" "lambda_handler" {
  api_id = aws_apigatewayv2_api.lambda_handler.id

  name        = "question_allocator_lambda_gw_stage"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.lambda_handler_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}

resource "aws_apigatewayv2_integration" "lambda_handler" {
  api_id = aws_apigatewayv2_api.lambda_handler.id

  integration_uri    = aws_lambda_function.lambda_handler.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "lambda_handler" {
  api_id = aws_apigatewayv2_api.lambda_handler.id

  route_key = "GET /invoke"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_handler.id}"
}

resource "aws_apigatewayv2_integration" "lambda_handler_post" {
  api_id = aws_apigatewayv2_api.lambda_handler.id

  integration_uri    = aws_lambda_function.lambda_handler.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "lambda_handler_post" {
  api_id = aws_apigatewayv2_api.lambda_handler.id

  route_key = "POST /invoke"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_handler_post.id}"
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_handler.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda_handler.execution_arn}/*/*"
}

output "api_gw_url" {
  description = "Base URL for API Gateway stage."
  value       = aws_apigatewayv2_stage.lambda_handler.invoke_url
}

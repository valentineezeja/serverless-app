resource "aws_s3_bucket" "web-files" {
  bucket = "web-files-for-deployment1"

  tags = {
    Name        = "Web files"
    Environment = "Dev"
  }
}

  # Zip the Lamda function
data "archive_file" "source" {
  type        = "zip"
  source_dir  = "../project-1.0/web-files"
  output_path = "../project-1.0/web-files.zip"
}
# upload zip to s3 and then update lamda function from s3
resource "aws_s3_bucket_object" "file_upload" {
  bucket = "web-files-for-deployment1"
  key    = "project-1.0/web-files.zip"
  source = "${data.archive_file.source.output_path}" # its mean it depended on zip
  etag = filemd5(data.archive_file.source.output_path)

}

resource "aws_lambda_function" "weather_app" {
  function_name = "WeatherApp"

  s3_bucket = "web-files-for-deployment1"
  s3_key    = "project-1.0/web-files.zip"

  runtime = "nodejs12.x"
  handler = "index.handler"

  source_code_hash = "${base64sha256(data.archive_file.source.output_path)}"
  
  role= aws_iam_role.lambda_exec.arn
}

resource "aws_iam_role" "lambda_exec" {
  name = "serverless_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

resource "aws_api_gateway_rest_api" "api" {
  name          = "api-gateway"
  description   = "API form WebApp function"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "resource" {
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  parent_id   = "${aws_api_gateway_rest_api.api.root_resource_id}"
  path_part   = "{proxy+}"
}
resource "aws_api_gateway_method" "method" {
  rest_api_id   = "${aws_api_gateway_rest_api.api.id}"
  resource_id   = "${aws_api_gateway_resource.resource.id}"
  http_method   = "ANY"
  authorization = "NONE"
  request_parameters = {
    "method.request.path.proxy" = true
  }
}
resource "aws_api_gateway_integration" "integration" {
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  resource_id = "${aws_api_gateway_resource.resource.id}"
  http_method = "${aws_api_gateway_method.method.http_method}"
  integration_http_method = "ANY"
  type                    = "AWS_PROXY"
  uri                     = "aws_lambda_function.lambda.invoke_arn"
    
    request_parameters =  {
    "integration.request.path.proxy" = "method.request.path.proxy"
    }

} 
  
  # Lambda
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "WeatherApp"
  principal     = "apigateway.amazonaws.com"

}


  



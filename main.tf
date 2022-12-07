# Create the S3 bucket that would contain the Lambda function/web files

resource "aws_s3_bucket" "web-files" {
  bucket = "web-files-for-deployment1"

  tags = {
    Name        = "Web files"
    Environment = "Dev"
  }
}

  # Zip the Lamda function/web files

data "archive_file" "source" {
  type        = "zip"
  source_dir  = "../project-1.0/web-files"
  output_path = "../project-1.0/web-files.zip"
}

# Upload the zipped files to an s3 bucket 

resource "aws_s3_object" "file_upload" {
  bucket = "web-files-for-deployment1"
  key    = "project-1.0/web-files.zip"
  source = "${data.archive_file.source.output_path}" 
  etag = filemd5(data.archive_file.source.output_path)

}

#Create a Lambda function using the zipped files in the S3 bucket

resource "aws_lambda_function" "weather_app" {
  function_name = "WeatherApp"

  s3_bucket = "web-files-for-deployment1"
  s3_key    = "project-1.0/web-files.zip"

  runtime = "nodejs12.x"
  handler = "index.handler"

  source_code_hash = "${base64sha256(data.archive_file.source.output_path)}"
  
  role= aws_iam_role.lambda_exec.arn #this refers to the IAM role in the next block

}

#Create an IAM role which determines other services the function can access. NB: No access policy has been described in this role in the meantime as it is not needed

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

# Create the API gateway 

resource "aws_api_gateway_rest_api" "api" {
  name          = "api-gateway"
  description   = "API form WebApp function"
   binary_media_types = [
    "*/*"
    ]
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
  uri                     = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:431227929488:function:WeatherApp/invocations"
    
    request_parameters =  {
    "integration.request.path.proxy" = "method.request.path.proxy"
    }

} 
resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = "${aws_api_gateway_rest_api.api.id}"
  resource_id   = "${aws_api_gateway_rest_api.api.root_resource_id}"
  http_method   = "ANY"
  authorization = "NONE"
}  

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  resource_id = "${aws_api_gateway_method.proxy_root.resource_id}"
  http_method = "${aws_api_gateway_method.proxy_root.http_method}"
  integration_http_method = "ANY"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:431227929488:function:WeatherApp/invocations"


}

# Create a deployment for the API gateway

resource "aws_api_gateway_deployment" "deploy" {
  depends_on = [
    aws_api_gateway_integration.integration,
    aws_api_gateway_integration.lambda_root,
    aws_cloudwatch_log_group.CW_group
  ]

  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  stage_name  = "web"
}

# Create a stage for the deployment and configure access log for CW

resource "aws_api_gateway_stage" "web" {
  stage_name            = "web"
  description           = "Prod / main stage for my initial deployment"
  rest_api_id           = aws_api_gateway_rest_api.api.id
  deployment_id         = aws_api_gateway_deployment.deploy.id

# Configure CloudWatch logs for the API gateway stage (ie, access logs)
  access_log_settings {                               
    destination_arn = "${aws_cloudwatch_log_group.CW_group.arn}"
    format          = "JSON"

}

}

# Enable CloudWatch logging and metrics for the API gateway (ie, execution logs)

resource "aws_api_gateway_method_settings" "CW_settings" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "web"
  method_path = "*/*"

  settings {
    metrics_enabled = true
    logging_level   = "INFO"
    data_trace_enabled  = true
  }

}

# Create a log group where the logs configured in the steps above would be saved

resource "aws_cloudwatch_log_group" "CW_group" {
  name              = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.api.id}/web"
  retention_in_days = 7

}

  # Create Lambda permission. This gives the API gateway permission to access/call the Lambda function

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "WeatherApp"
  principal     = "apigateway.amazonaws.com"

}

# Create an API Gateway account and permissions for the API gateway to access/write to CloudWatch

resource "aws_api_gateway_account" "account" {
  cloudwatch_role_arn = "${aws_iam_role.cloudwatch.arn}"
}

resource "aws_iam_role" "cloudwatch" {
  name = "api_gateway_cloudwatch_global"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "cloudwatch" {
  name = "default"
  role = "${aws_iam_role.cloudwatch.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents",
                "logs:GetLogEvents",
                "logs:FilterLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}



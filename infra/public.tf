# Using ECR proxy implementation from https://github.com/monken/aws-ecr-public
module "lambda_function" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "public-ecr"
  description   = "Proxy to ECR"
  handler       = "exports.handler"
  runtime       = "nodejs12.x"

  source_path = "src/public-repo.js"

  tags = local.common_tags
}

module "api_gateway" {
  source = "terraform-aws-modules/apigateway-v2/aws"

  name          = "public-ecr"
  description   = "Tyk public build registry"
  protocol_type = "HTTPS"

  cors_configuration = {
    allow_headers = ["content-type", "x-amz-date", "authorization", "x-api-key", "x-amz-security-token", "x-amz-user-agent"]
    allow_methods = ["*"]
    allow_origins = ["*"]
  }

  # Custom domain
  domain_name                 = "ecr.dev.tyk.technology"
  domain_name_certificate_arn = "arn:aws:acm:eu-west-1:052235179155:certificate/2b3a7ed9-05e1-4f9e-952b-27744ba06da6"

  # Access logs
  default_stage_access_log_destination_arn = "arn:aws:logs:eu-west-1:835367859851:log-group:debug-apigateway"
  default_stage_access_log_format          = "$context.identity.sourceIp - - [$context.requestTime] \"$context.httpMethod $context.routeKey $context.protocol\" $context.status $context.responseLength $context.requestId $context.integrationErrorMessage"

  # Routes and integrations
  integrations = {
    "POST /" = {
      lambda_arn             = "arn:aws:lambda:eu-west-1:052235179155:function:my-function"
      payload_format_version = "2.0"
      timeout_milliseconds   = 12000
    }

    "$default" = {
      lambda_arn = "arn:aws:lambda:eu-west-1:052235179155:function:my-default-function"
    }
  }

  tags = local.common_tags
}

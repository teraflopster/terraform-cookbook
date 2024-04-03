resource "aws_cloudwatch_event_rule" "main_lambda_schedule_rule" {
  name                = "trigger-name-${var.env}"
  description         = "Fires every Mon at 1 AM PST (8 AM UTC)"
  schedule_expression = "cron(0 8 ? * SUN *)"
}

resource "aws_cloudwatch_event_target" "trigger_main_lambda_converter" {
  rule  = aws_cloudwatch_event_rule.main_lambda_schedule_rule.name
  arn   = module.main_lambda.function_arn
  input = jsonencode({})
}

resource "aws_lambda_permission" "main_lambda_invoke_permission" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = module.main_lambda.function_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.main_lambda_schedule_rule.arn
}

resource "aws_lambda_permission" "allow_event_bridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = module.second_lambda.function_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.main_lambda_success.arn
}

resource "aws_cloudwatch_event_rule" "main_lambda_success" {
  name        = "main-lambda-success"
  description = "Triggered when main Lambda function completes successfully"

  event_pattern = jsonencode(
    {
      detail = {
        requestContext = {
          functionArn = [
            module.main_lambda.function_arn,
          ]
        }
        responsePayload = {
          status = ["SUCCESS", ]
        }
      }
      detail-type = [
        "Lambda Function Invocation Result",
      ]
      source = [
        "aws.lambda",
      ]
    }
  )
}

resource "aws_cloudwatch_event_target" "invoke_second_lambda" {
  rule      = aws_cloudwatch_event_rule.main_lambda_success.name
  target_id = "InvokeSecondLambdaFunction"
  arn       = module.second_lambda.function_arn
}

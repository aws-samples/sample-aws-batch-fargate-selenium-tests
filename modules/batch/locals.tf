data "aws_region" "current" {}

data "aws_caller_identity" "this" {}

locals {
  account_id = data.aws_caller_identity.this.account_id
  order_input_transformer = {
    input_paths = {
      runId = "$.detail.runId"
    }
    input_template = <<-EOF
      {
        "Parameters": {
          "runId": <runId>
        },
        "ContainerOverrides": {
          "Environment": [
            {
              "Name": "RUN_ID",
              "Value": <runId>
            }
          ]
        }
      }
    EOF
  }
}

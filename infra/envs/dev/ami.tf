// Fetch the latest Amazon Linux 2023 AMI via SSM public parameters.
// This is the recommended approach in 2026 for staying patched while
// avoiding hard-coded AMI IDs.

data "aws_ssm_parameter" "al2023_x86_64" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

locals {
  // The SSM parameter value is the AMI ID (e.g. ami-0abcd1234...).
  app_image_id = data.aws_ssm_parameter.al2023_x86_64.value
}


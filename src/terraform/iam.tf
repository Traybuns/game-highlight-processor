data "aws_iam_policy_document" "ecs_task_trust" {
  statement {
    actions = ["sts:AssumeRole"]  # Allow the action sts:AssumeRole

    principals {
      type        = "Service"                      # Specify the type of principal as Service
      identifiers = ["ecs-tasks.amazonaws.com"]    # The service allowed to assume the role
    }
  }
}


resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.project_name}-ecs-task-execution-role"  # Name of the IAM role, incorporating the project name variable
  assume_role_policy = data.aws_iam_policy_document.ecs_task_trust.json  # Attach the trust policy JSON to the role
}


resource "aws_iam_role_policy_attachment" "ecs_task_execution_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name  # The name of the IAM role to attach the policy to
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"  # ARN of the managed policy to attach
}


data "aws_iam_policy_document" "ecs_custom_doc" {
  
  S3 permissions
  statement {
    actions   = ["s3:GetObject", "s3:PutObject"]  # Allow S3 GetObject and PutObject actions
    resources = ["arn:aws:s3:::${var.s3_bucket_name}/*"]  # Apply permissions to all objects in the specified S3 bucket
  }

   SSM Parameter Store permissions
  statement {
    actions = [
      "ssm:GetParameter",          # Allow retrieving a single parameter
      "ssm:GetParameters",         # Allow retrieving multiple parameters
      "ssm:GetParameterHistory"    # Allow retrieving the history of a parameter
    ]
    resources = [
      var.rapidapi_ssm_parameter_arn  # ARN of the specific SSM parameter to grant access to
    ]
  }

   MediaConvert permissions
  statement {
    actions = [
      "mediaconvert:CreateJob",  # Allow creating MediaConvert jobs
      "mediaconvert:GetJob",     # Allow retrieving MediaConvert job details
      "mediaconvert:ListJobs"    # Allow listing MediaConvert jobs
    ]
    resources = ["*"]  # MediaConvert requires "*" for resource ARN as it manages multiple resources
  }
}


resource "aws_iam_policy" "ecs_custom_policy" {
  name   = "${var.project_name}-ecs-custom-policy"  # Name of the custom IAM policy, incorporating the project name variable
  policy = data.aws_iam_policy_document.ecs_custom_doc.json  # Attach the custom policy JSON
}


resource "aws_iam_role_policy_attachment" "ecs_custom_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name  # The name of the IAM role to attach the custom policy to
  policy_arn = aws_iam_policy.ecs_custom_policy.arn        # ARN of the custom IAM policy to attach
}


data "aws_iam_policy_document" "mediaconvert_trust" {
  statement {
    actions = ["sts:AssumeRole"]  # Allow the action sts:AssumeRole

    principals {
      type        = "Service"                      # Specify the type of principal as Service
      identifiers = ["mediaconvert.amazonaws.com"] # The service allowed to assume the role
    }
  }
}

# ------------------------------------------------------------------------
# Resource: aws_iam_role.mediaconvert_role
# ------------------------------------------------------------------------
# This IAM role is created for AWS MediaConvert. It uses the trust policy
# defined in the mediaconvert_trust data source to allow MediaConvert to assume this role.
# ------------------------------------------------------------------------
resource "aws_iam_role" "mediaconvert_role" {
  name               = "${var.project_name}-mediaconvert-role"  # Name of the IAM role, incorporating the project name variable
  assume_role_policy = data.aws_iam_policy_document.mediaconvert_trust.json  # Attach the trust policy JSON to the role
}


data "aws_iam_policy_document" "mediaconvert_policy_doc" {
  
  # Statement for S3 permissions
  statement {
    actions   = ["s3:GetObject", "s3:PutObject"]  # Allow S3 GetObject and PutObject actions
    resources = ["arn:aws:s3:::${var.s3_bucket_name}/*"]  # Apply permissions to all objects in the specified S3 bucket
  }

  # Statement for CloudWatch Logs permissions
  statement {
    actions   = [
      "logs:CreateLogStream",  # Allow creating log streams in CloudWatch Logs
      "logs:PutLogEvents"      # Allow putting log events into CloudWatch Logs
    ]
    resources = [
      "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/ecs/${var.project_name}/*"
      # ARN for the specific CloudWatch Logs log group associated with the ECS project
    ]
  }
}


resource "aws_iam_policy" "mediaconvert_policy" {
  name   = "${var.project_name}-mediaconvert-s3-logs"  # Name of the MediaConvert IAM policy, incorporating the project name variable
  policy = data.aws_iam_policy_document.mediaconvert_policy_doc.json  # Attach the MediaConvert policy JSON
}


resource "aws_iam_role_policy_attachment" "mediaconvert_attach" {
  role       = aws_iam_role.mediaconvert_role.name   # The name of the IAM role to attach the MediaConvert policy to
  policy_arn = aws_iam_policy.mediaconvert_policy.arn # ARN of the MediaConvert IAM policy to attach
}


data "aws_caller_identity" "current" {}
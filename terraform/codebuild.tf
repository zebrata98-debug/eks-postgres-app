resource "aws_iam_role" "codebuild" {
  name = "${var.cluster_name}-codebuild"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Effect = "Allow", Principal = { Service = "codebuild.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
}

resource "aws_iam_role_policy" "codebuild" {
  role = aws_iam_role.codebuild.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = ["ecr:*"], Resource = "*" },
      { Effect = "Allow", Action = ["logs:*", "s3:*"], Resource = "*" }
    ]
  })
}

resource "aws_codebuild_project" "app" {
  name         = "${var.cluster_name}-build"
  service_role = aws_iam_role.codebuild.arn

  artifacts { type = "NO_ARTIFACTS" }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:7.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable { name = "ECR_URI",    value = aws_ecr_repository.app.repository_url }
    environment_variable { name = "AWS_REGION", value = var.aws_region }
  }

  source {
    type            = "GITHUB"
    location        = "https://github.com/${var.github_owner}/${var.github_repo}.git"
    buildspec       = "app/buildspec.yml"
    git_clone_depth = 1
  }
}
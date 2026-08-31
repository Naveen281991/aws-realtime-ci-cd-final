resource "aws_iam_role" "codepipeline" {
  name = "AWS-CICD-CodePipeline-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "codepipeline.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "AWS-CICD-CodePipeline-Role"
  }
}

resource "aws_iam_role_policy" "codepipeline" {
  name = "AWS-CICD-CodePipeline-Policy"
  role = aws_iam_role.codepipeline.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "CodeConnections"
        Effect = "Allow"

        Action = [
          "codeconnections:UseConnection"
        ]

        Resource = var.github_connection_arn
      },
      {
        Sid    = "CodeBuild"
        Effect = "Allow"

        Action = [
          "codebuild:StartBuild",
          "codebuild:BatchGetBuilds"
        ]

        Resource = aws_codebuild_project.application.arn
      },
      {
        Sid    = "S3Artifacts"
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObject",
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ]

        Resource = [
          aws_s3_bucket.artifacts.arn,
          "${aws_s3_bucket.artifacts.arn}/*"
        ]
      },
      {
        Sid    = "ECSDeployment"
        Effect = "Allow"

        Action = [
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeTaskSets",
          "ecs:DescribeClusters",
          "ecs:ListTasks",
          "ecs:ListTaskDefinitions",
          "ecs:RegisterTaskDefinition",
          "ecs:DeregisterTaskDefinition",
          "ecs:UpdateService",
          "ecs:UpdateServicePrimaryTaskSet",
          "ecs:TagResource"
        ]

        Resource = "*"
      },
      {
        Sid    = "PassECSTaskExecutionRole"
        Effect = "Allow"

        Action = [
          "iam:PassRole"
        ]

        Resource = aws_iam_role.ecs_task_execution.arn
      }
    ]
  })
}

resource "aws_codepipeline" "application" {
  name          = "AWS-Enterprise-CICD-Pipeline"
  role_arn      = aws_iam_role.codepipeline.arn
  pipeline_type = "V2"

  artifact_store {
    location = aws_s3_bucket.artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "GitHubSource"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["SourceArtifact"]

      configuration = {
        ConnectionArn    = var.github_connection_arn
        FullRepositoryId = var.github_repository
        BranchName       = var.github_branch
        DetectChanges    = "true"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name     = "DockerBuildAndPush"
      category = "Build"
      owner    = "AWS"
      provider = "CodeBuild"
      version  = "1"

      input_artifacts  = ["SourceArtifact"]
      output_artifacts = ["BuildArtifact"]

      configuration = {
        ProjectName = aws_codebuild_project.application.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name     = "DeployToECS"
      category = "Deploy"
      owner    = "AWS"
      provider = "ECS"
      version  = "1"

      input_artifacts = ["BuildArtifact"]

      configuration = {
        ClusterName = aws_ecs_cluster.main.name
        ServiceName = aws_ecs_service.application.name
        FileName    = "imagedefinitions.json"
      }
    }
  }

  tags = {
    Name = "AWS-Enterprise-CICD-Pipeline"
  }
}

resource "aws_iam_role" "ecs_service" {
  # IAMロール名
  name = "${var.env}_${var.project}_ecs_service"
  path = "/"
  # 信頼ポリシーJSON
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : [
            "ecs.amazonaws.com",
            "ecs-tasks.amazonaws.com"
          ]
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "ecs_service" {
  name = "${var.env}_${var.project}_ecs_service"
  role = aws_iam_role.ecs_service.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "GetParams",
        "Effect" : "Allow",
        "Action" : [
          "kms:Decrypt",
          "ssm:GetParameters"
        ],
        "Resource" : [
          aws_kms_key.application.arn,
          aws_ssm_parameter.mysql_password.arn,
        ]
      }
    ]
  })
}

# マネージドポリシーを作成したIAMロールに紐づける
resource "aws_iam_role_policy_attachment" "policy_ecs_task_execution_role_policy_to_ecs_service_attachment" {
  # IAMロール名
  role = aws_iam_role.ecs_service.name
  # ポリシーARN
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


resource "aws_iam_role" "ecs_task" {
  name = "${var.env}_${var.project}_ecs_task"
  path = "/"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : [
            "ecs-tasks.amazonaws.com"
          ]
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "ecs_task" {
  name = "${var.env}_${var.project}_ecs_task"
  role = aws_iam_role.ecs_task.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "S3Access",
        "Effect" : "Allow",
        "Action" : [
          "s3:*"
        ],
        "Resource" : "arn:aws:s3:::${var.env}-${var.project}*"
      },
      {
        "Sid" : "SendMail",
        "Effect" : "Allow",
        "Action" : [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ],
        "Resource" : "arn:aws:ses:${var.region}:${data.aws_caller_identity.current.account_id}:identity/*"
      },
      {
        "Sid" : "SessionManager",
        "Effect" : "Allow",
        "Action" : [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role" "lambda_edge" {
  name = "${var.env}-lambda-edge"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : [
            "lambda.amazonaws.com",
            "edgelambda.amazonaws.com"
          ]
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_edge" {
  name = "${var.env}-lambda-edge"
  role = aws_iam_role.lambda_edge.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "logs:CreateLogGroup",
        "Resource" : "arn:aws:logs::${data.aws_caller_identity.current.account_id}:*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : [
          "arn:aws:logs::${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${aws_ses_domain_identity.main.domain}"
        ]
      }
    ]
  })
}

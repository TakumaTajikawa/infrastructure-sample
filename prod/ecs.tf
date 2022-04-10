# タスクを配置する仮想空間
resource "aws_ecs_cluster" "production-offkai" {
  name               = "${var.env}-${var.project}"
  # ECSにおけるタスク実行のインフラをより柔軟に設定する仕組み
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]
  # クラスターでデフォルトで使用する容量プロバイダー戦略の構成ブロック
  default_capacity_provider_strategy {
    # 指定された容量プロバイダーで実行する最小限のタスクの数
    base              = 0
    capacity_provider = "FARGATE"
    # 起動したタスクの総数のうち、指定した容量プロバイダを使用する相対的な割合
    weight            = 0
  }
  default_capacity_provider_strategy {
    base              = 0
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
  }

  setting {
    # 管理する設定の名前。有効な値：containerInsightsのみ
    name  = "containerInsights"
    # 設定に割り当てる値。有効な値は enabled or disabled
    value = "enabled"
  }
}

# ALBとAutoScaling Groupに紐付けられたタスク群
resource "aws_ecs_service" "app" {
  name                               = "app"
  # ECSクラスターのARN
  cluster                            = aws_ecs_cluster.production.arn
  # task definitionのARN
  task_definition                    = aws_ecs_task_definition.app.arn
  # 配置し、実行を維持するタスク定義のインスタンスの数
  desired_count                      = 2
  # 配置中にサービス内で実行され、健全な状態を維持しなければならない実行タスクの数の下限 (単位：％) 
  deployment_minimum_healthy_percent = 50
  # サービスを実行するプラットフォームのバージョン。launch_typeがFARGATEに設定されている場合のみ適用可能
  platform_version                   = "1.4.0"
  # enable_execute_command = true

  capacity_provider_strategy {
    base              = 0
    capacity_provider = "FARGATE"
    weight            = 0
  }

  capacity_provider_strategy {
    base              = 0
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
  }

  deployment_controller {
    type = "ECS"
  }

  # ECSタスクの起動後に紐付けるELBターゲットグループ
  load_balancer {
    target_group_arn = aws_lb_target_group.web.arn
    container_name   = "nginx"
    container_port   = 80
  }
  # ECSタスクへ設定するネットワークの設定
  network_configuration {
    # タスクの起動を許可するサブネット
    subnets = [
      for subnet in aws_subnet.public :
      subnet.id
    ]
    # タスクに紐付けるセキュリティグループ
    security_groups  = [aws_security_group.web.id]
    assign_public_ip = true
  }

  # autoscalingで動的に変化する値を無視する
  lifecycle {
    ignore_changes = [
      capacity_provider_strategy,
      task_definition,
      desired_count,
    ]
  }

  depends_on = [
    aws_lb_target_group.web
  ]
}

# オートスケーリング
resource "aws_appautoscaling_target" "app" {
  service_namespace  = "ecs"
  # スケーリングポリシーに関連付けられたリソース
  resource_id        = "service/${aws_ecs_cluster.staging-wellroom.name}/${aws_ecs_service.app.name}"
  # スケーラブルターゲットに関連付けられたスケーラブルディメンション。この文字列は、サービスの名前空間、リソースタイプ、およびスケーリングプロパティで構成される
  # ecs:service:DesiredCount-ECSサービスの目的のタスク数
  scalable_dimension = "ecs:service:DesiredCount"
  # スケーラブルターゲットの最小容量
  min_capacity       = 2
  # スケーラブルターゲットの最大容量
  max_capacity       = 3
  # autoscalingで動的に変化する値を無視する
  lifecycle {
    ignore_changes = [
      max_capacity,
      min_capacity,
    ]
  }
}

# ロートスケーリングポリシー
resource "aws_appautoscaling_policy" "app_scale_out" {
  # ポリシーの名前。1 ～ 255 文字の長さにする必要がある。
  name               = "scale-out"
  # ポリシーの種類。有効な値は、StepScaling および TargetTrackingScaling 。デフォルトはStepScaling
  # --------------------------
  # Step Scaling Policy
  # 指定した閾値に基づいてスケールアウト/インを行うオートスケールです。 スケールアウト/インを段階的に定義できるのが特徴で、例えば以下のような設定が可能。
  # CPUの平均使用率が61-70% -> コンテナを1つ増やす
  # CPUの平均使用率が71-80% -> コンテナを3つ増やす
  # CPUの平均使用率が81%以上 -> コンテナを5つ増やす
  # CPUの平均使用率が50%以下 -> コンテナを1つ減らす

  # Target Tracking Scaling Policy
  # 指定したメトリクスが指定した数値になるようにスケールアウト/インを行うオートスケールです。
  # 例えばCPUの平均使用率が60%となるように指定した場合
  # CPUの平均使用率が70% -> スケールアウト
  # CPUの平均使用率が50% -> スケールイン
  # というような振る舞いをし、CPUの平均使用率が60%になるように努めてくれます。
  # # --------------------------
  policy_type        = "StepScaling"
  resource_id        = "service/${aws_ecs_cluster.staging-wellroom.name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

# ステップスケーリングポリシーの構成
  step_scaling_policy_configuration {
    # 調整が絶対数であるか、現在の容量に対するパーセンテージであるかを指定する。有効な値は、ChangeInCapacity、ExactCapacity、PercentChangeInCapacity。
    adjustment_type         = "ChangeInCapacity"
    // スケールアウトの間隔は120秒空ける
    cooldown                = 120
    # メトリクスの集計タイプ。有効な値は "Minimum"、"Maximum"、"Average" 
    metric_aggregation_type = "Average"
    # スケーリングを管理するための調整セット。
    step_adjustment {
      # アラームしきい値とCloudWatchメトリックスの差の下限
      metric_interval_lower_bound = 0
      # 調整境界を突破したときに、スケーリングするメンバー数。正の値は、スケール・アップし、負の値は、縮小する。
      scaling_adjustment          = 3
    }
  }

  depends_on = [aws_appautoscaling_target.app]
  # autoscalingで動的に変化する値を無視する
  lifecycle {
    ignore_changes = [step_scaling_policy_configuration]
  }
}

resource "aws_appautoscaling_policy" "app_scale_in" {
  name               = "scale-in"
  policy_type        = "StepScaling"
  resource_id        = "service/${aws_ecs_cluster.staging-wellroom.name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 600
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }

  depends_on = [aws_appautoscaling_target.app]

  lifecycle {
    ignore_changes = [step_scaling_policy_configuration]
  }
}

# タスク定義
resource "aws_ecs_task_definition" "app" {
  # タスク定義の一意な名前
  family                   = "${var.env}-${var.project}-app"
  # タスク内のコンテナに使用するDockerネットワーキング・モード。有効な値は、none、bridge、awsvpc、host
  network_mode             = "awsvpc"
  # タスクが必要とする起動タイプのセット。有効な値は"EC2", "FARGATE"
  requires_compatibilities = ["FARGATE"]
  # タスクが使用するcpuユニットの数。requires_compatibilitiesがFARGATEの場合は必須
  cpu                      = 256
  # タスクが使用するメモリの量(MiB単位)
  memory                   = 512
  # Amazon ECS コンテナエージェントと Docker デーモンが引き受けることができるタスク実行ロールの ARN。
  execution_role_arn       = aws_iam_role.ecs_service.arn
  # jsonドキュメントとして提供されるコンテナ定義のリスト
  container_definitions    = file("files/task-definitions/app.json")
}

resource "aws_ecs_service" "queue" {
  name                               = "queue"
  cluster                            = aws_ecs_cluster.staging-wellroom.id
  task_definition                    = aws_ecs_task_definition.queue.arn
  desired_count                      = 1
  deployment_minimum_healthy_percent = 50
  platform_version                   = "1.4.0"

  capacity_provider_strategy {
    base              = 0
    capacity_provider = "FARGATE"
    weight            = 0
  }

  capacity_provider_strategy {
    base              = 0
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
  }

  deployment_controller {
    type = "ECS"
  }

  network_configuration {
    subnets = [
      for subnet in aws_subnet.private :
      subnet.id
    ]
    security_groups  = [aws_security_group.web.id]
  }

  lifecycle {
    ignore_changes = [
      task_definition,
      desired_count,
    ]
  }
}

resource "aws_ecs_task_definition" "queue" {
  family                   = "${var.env}-${var.project}-queue"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_service.arn
  container_definitions    = file("files/task-definitions/queue.json")
}

resource "aws_ecs_task_definition" "migrate" {
  family                   = "${var.env}-${var.project}-migrate"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_service.arn
  container_definitions    = file("files/task-definitions/migrate.json")
}

resource "aws_ecs_service" "cron" {
  name                               = "cron"
  cluster                            = aws_ecs_cluster.staging-wellroom.id
  task_definition                    = aws_ecs_task_definition.cron.arn
  desired_count                      = 1
  deployment_minimum_healthy_percent = 50
  platform_version                   = "1.4.0"

  capacity_provider_strategy {
    base              = 0
    capacity_provider = "FARGATE"
    weight            = 0
  }

  capacity_provider_strategy {
    base              = 0
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
  }

  deployment_controller {
    type = "ECS"
  }

  network_configuration {
    subnets = [
      for subnet in aws_subnet.private :
      subnet.id
    ]
    security_groups  = [aws_security_group.web.id]
  }

  lifecycle {
    ignore_changes = [
      task_definition,
      desired_count,
    ]
  }
}

resource "aws_ecs_task_definition" "cron" {
  family                   = "${var.env}-${var.project}-cron"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_service.arn
  container_definitions    = file("files/task-definitions/cron.json")
}
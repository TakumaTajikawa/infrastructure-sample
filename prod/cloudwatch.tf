resource "aws_cloudwatch_log_group" "nginx" {
  # ロググループの名前。省略した場合はランダムでユニークな名前が割り当てられる
  name              = "${var.env}-${var.project}-nginx"
  # ログイベントを保持する日数。０を指定した場合は常に保持され期限切れになることはない。
  retention_in_days = 5

  tags = {
    application = var.project
  }
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "${var.env}-${var.project}-app"
  retention_in_days = 5

  tags = {
    application = var.project
  }
}

resource "aws_cloudwatch_log_group" "cron" {
  name              = "${var.env}-${var.project}-cron"
  retention_in_days = 5

  tags = {
    application = var.project
  }
}

resource "aws_cloudwatch_log_group" "queue" {
  name              = "${var.env}-${var.project}-queue"
  retention_in_days = 5

  tags = {
    application = var.project
  }
}

resource "aws_cloudwatch_log_group" "migrate" {
  name              = "${var.env}-${var.project}-migrate"
  retention_in_days = 5

  tags = {
    application = var.project
  }
}

# メトリクスアラーム（メトリクスとは、監視対象から取得するある時間ごとのデータの集合）
resource "aws_cloudwatch_metric_alarm" "app-cpu-high" {
  # アラームの名前。AWSアカウント内でユニークである必要がある
  alarm_name          = "${var.env}-${var.project}-app-cpu-high"
  # 指定された統計としきい値を比較するときに使用する算術演算
  comparison_operator = "GreaterThanOrEqualToThreshold"
  # 指定されたしきい値と比較されるデータの期間数
  evaluation_periods  = 2
  # アラームの関連メトリクスの名前
  # （CPUUtilization：割り当てられた EC2 コンピュートユニットのうち、現在インスタンス上で使用されているものの比率。このメトリクスによって、選択したインスタンスでアプリケーションを実行するのに必要な処理能力を特定できます。インスタンスタイプによっては、インスタンスがフルプロセッサコアに割り当てられていない場合に、オペレーティングシステムのツールが CloudWatch とは異なる比率を示す場合があります。）
  metric_name         = "CPUUtilization"
  # 複数のメトリクスをまとめてコンテナ（箱）で管理する概念
  namespace           = "AWS/ECS"
  # 指定された統計が適用される期間 
  period              = 60
  # アラームの関連のメトリクスに適用される統計値
  statistic           = "Average"
  # 指定された統計値と比較される値
  threshold           = 50
  # このアラームがどのように欠損データ点を処理するかを設定
  # missing、ignore、breach、notBreachingのいずれかを指定
  # notBreaching – 欠落データポイントは「良好」とされ、しきい値内として扱われます。
  # breaching – 欠落データポイントは「不良」とされ、しきい値超過として扱われます。
  # ignore – 現在のアラーム状態が維持されます。
  # missing – アラーム評価範囲内のすべてのデータポイントがない場合、アラームは INSUFFICIENT_DATA に移行します。
  treat_missing_data  = "notBreaching"
  # 次元。キーバリューの形でメトリクスを特定するために用いる
  dimensions = {
    ClusterName = aws_ecs_cluster.production-offkai.name
    ServiceName = aws_ecs_service.app.name
  }

  alarm_actions = [aws_appautoscaling_policy.app_scale_out.arn]
}

resource "aws_cloudwatch_metric_alarm" "app-cpu-low" {
  alarm_name          = "${var.env}-${var.project}-app-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 10
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 15
  treat_missing_data  = "notBreaching"
  datapoints_to_alarm = 10

  dimensions = {
    ClusterName = aws_ecs_cluster.staging-wellroom.name
    ServiceName = aws_ecs_service.app.name
  }

  alarm_actions = [aws_appautoscaling_policy.app_scale_in.arn]
} 
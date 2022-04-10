# RDS Aurora Clusterを管理するリソース
resource "aws_rds_cluster" "aurora" {
  # クラスター識別子。省略した場合、Terraformはランダムで一意の識別子を割り当てる
  cluster_identifier = "${var.env}-${var.project}-cluster"
  # DB クラスターで使用するデータベース・エンジンの名前。有効な値：aurora、aurora-mysql、aurora-postgresql、mysql、postgres
  engine = "aurora-mysql"
  # データベースエンジンのバージョン
  engine_version  = "5.7.mysql_aurora.2.09.1"
  database_name   = var.project
  master_username = var.project
  master_password = var.mysql_password
  # バックアップを保持する日数
  backup_retention_period = 1
  # backup_retention_periodパラメータを使用して自動バックアップを有効にした場合に、自動バックアップが作成される毎日の時間範囲
  preferred_backup_window = "03:00-03:30"
  # システムメンテナンスを行う週単位の時間範囲
  preferred_maintenance_window = "sun:04:00-sun:04:30"
  vpc_security_group_ids       = [aws_security_group.aurora.id]
  db_subnet_group_name         = aws_db_subnet_group.main.id
  # このDBクラスターに関連付けるクラスタ・パラメータ・グループ
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.main.name
  # このDBクラスターが削除されたときの最終DBスナップショットの名前。
  # 省略した場合、最終的なスナップショットは作成されない。
  final_snapshot_identifier = "${var.env}-${var.env}-aurora-cluster"
  # cloudwatchにエクスポートするログタイプのセット。省略した場合、ログはエクスポートされない。
  # 次のログタイプがサポートされている：audit, error, general, slowquery, postgresql (PostgreSQL)。
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]
  # リリース前にON
  # deletion_protection             = true

  lifecycle {
    ignore_changes = [master_password]
  }
}

resource "aws_db_subnet_group" "main" {
  name        = "${var.env}-${var.project}"
  description = "${var.env} group of subnets"
  subnet_ids = [
    for subnet in aws_subnet.private :
    subnet.id
  ]

  tags = {
    Name = "${var.project} DB subnet group"
  }
}

# RDSクラスターインスタンス
resource "aws_rds_cluster_instance" "aurora_instance" {
  # インスタンスの数
  count = "1"
  # RDSインスタンスの識別子、省略した場合はTerraformがランダムでユニークな識別子を割り当てる
  identifier = "${var.env}-${var.project}-aurora-instance-${count.index + 1}"
  # このインスタンスを起動する aws_rds_cluster の識別子
  cluster_identifier      = aws_rds_cluster.aurora.id
  engine                  = "aurora-mysql"
  instance_class          = "db.t3.small"
  db_subnet_group_name    = aws_db_subnet_group.main.name
  db_parameter_group_name = aws_db_parameter_group.main.name
  # インスタンスがパブリックにアクセス可能かどうか
  publicly_accessible = false

  tags = {
    Name       = "${var.env}-${var.project}-${count.index}"
    Group      = var.project
    Enviroment = var.env
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [instance_class]
  }
}

# DBクラスターパラメーターグループ
resource "aws_rds_cluster_parameter_group" "main" {
  name = "${var.env}-${var.project}-aurora-pg"
  # DBクラスターパラメーターグループのファミリー
  family      = "aurora-mysql5.7"
  description = "RDS parameter group for ${var.project}"

  # 適用するDBパラメーターのリスト
  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_client"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_database"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_connection"
    value = "utf8mb4"
  }

  lifecycle {
    ignore_changes = [parameter]
  }
}

resource "aws_db_parameter_group" "main" {
  name        = "${var.env}-${var.project}-pg"
  family      = "aurora-mysql5.7"
  description = "RDS parameter group for ${var.project}"

  parameter {
    name  = "max_connections"
    value = "512"
  }

  parameter {
    name         = "slow_query_log"
    value        = 1
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "long_query_time"
    value        = 0.1
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "log_output"
    value        = "file"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "query_cache_type"
    value        = 1
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "general_log"
    value        = 1
    apply_method = "pending-reboot"
  }
} 
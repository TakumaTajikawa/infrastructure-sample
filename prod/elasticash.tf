# セットアップ、運用や拡張が簡単にできるマネージド型インメモリキャッシュサービス
# （memcachedとRedisを提供している）
resource "aws_elasticache_cluster" "main" {
  # グループ識別子
  cluster_id = "${var.env}-${var.project}-redis"
  # このキャッシュ・クラスターに使用するキャッシュ・エンジンの名前です。有効な値はmemcachedまたはredis。
  engine = "redis"
  # 使用するキャッシュエンジンのバージョン番号。設定しない場合、デフォルトは最新バージョンになる
  engine_version = "6.x"
  # 使用するインスタンスクラス
  node_type = "cache.t3.micro"
  port      = 6379
  # キャッシュクラスタが持つキャッシュノード（ElastiCache クラスターを構築するときの最小構成要素）の初期数。Redis の場合、この値は 1 である必要がある。Memcached の場合、この値は 1 から 40 の間でなければならない。
  num_cache_nodes = 1
  # このキャッシュクラスタと関連付けるパラメータグループの名前
  parameter_group_name = aws_elasticache_parameter_group.main.id
  # このキャッシュクラスタと関連付けるサブネットグループの名前
  subnet_group_name = aws_elasticache_subnet_group.main.name
  # キャッシュ・クラスターに関連する1つまたは複数のVPCセキュリティ・グループ
  security_group_ids = [aws_security_group.redis.id]

  lifecycle {
    ignore_changes = [engine_version]
  }
}

resource "aws_elasticache_parameter_group" "main" {
  name        = "${var.env}-${var.project}-redis-cache-params"
  family      = "redis6.x"
  description = "Cache cluster default param group"

  parameter {
    # Redis のアクティブな再ハッシュ機能を有効にするかどうか。主要なハッシュテーブルは、1 秒あたり 10 回再ハッシュされます。再ハッシュ操作ごとに 1 ミリ秒の CPU が消費される
    name  = "activerehashing"
    value = "yes"
  }

  parameter {
    # edis はクライアントに通知できる keyspace のタイプ。各イベントタイプは 1 文字で表される
    name = "notify-keyspace-events"
    # K — Keyspace イベント、プレフィックス __keyspace@<db>__ を付けて発行
    # E — Key-event イベント、プレフィックス __keyevent@<db>__ を付けて発行
    # x — 期限切れのイベント（キーの期限が切れるたびにイベントが生成されます）
    value = "KEx"
  }
}

resource "aws_elasticache_subnet_group" "main" {
  name        = "${var.env}-${var.project}"
  description = "${var.env} CacheSubnetGroup"

  subnet_ids = [
    for subnet in aws_subnet.private :
    subnet.id
  ]
}

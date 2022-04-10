resource "aws_lb" "web" {
  name            = "${var.env}-${var.project}-web"
  internal        = false
  security_groups = [aws_security_group.alb.id]
  subnets = [
    for subnet in aws_subnet.public :
    subnet.id
  ]

  # trueの場合、ロードバランサの削除はAWS API経由で無効になる。これにより、Terraformがロードバランサーを削除するのを防ぐことができる。デフォルトはfalse。
  enable_deletion_protection = true

  access_logs {
    bucket = aws_s3_bucket.alb_logs.bucket
    prefix = "web"
  }

  tags = {
    Group       = var.project
    Environment = var.env
  }
}

resource "aws_lb_target_group" "web" {
  name = "${var.env}-${var.project}-tg-web"
  # "instance", "ip", "lambda", "alb"いずれかを記入(デフォルトはinstance)
  # instance: インスタンスIDでターゲットを登録する
  # ip: IPアドレスでターゲットを登録する
  # lambda: 単一のLambda関数をターゲットとして登録する
  # alb: 単一のアプリケーションロードバランサーをターゲットとして登録する
  target_type = "ip"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id

  # スティッキーセッション
  stickiness {
    type = "lb_cookie"
    # タイプがlb_cookieのときだけ使用される。クライアントからの要求が同じターゲットにルーティングされる期間 (秒単位)。この期間が過ぎると、ロードバランサーによって生成されたクッキーは古いとみなされます。設定可能な範囲は、1 秒から 1 週間（604800 秒）。デフォルト値は1日（86400秒）。
    cookie_duration = 600
    # スティッキネスを有効／無効にするためのブール値。デフォルトはtrue
    enabled = false
  }

  # Application Load Balancerが、登録されたターゲットのステータスをテストするため、定期的にリクエストを送信するテストのこと
  health_check {
    # 不健全なターゲットを健全とみなす前に必要な連続したヘルスチェックの成功回数。デフォルトは３。
    healthy_threshold = 5
    # ターゲットを不健全と見なす前に必要な連続したヘルスチェック失敗の数。ネットワークロードバランサーの場合、この値は healthy_threshold と同じである必要がある。デフォルトは３。
    unhealthy_threshold = 2
    # ヘルスチェック要求の宛先
    path = "/healthcheck"
  }

  tags = {
    Group      = var.project
    Enviroment = var.env
  }

  # このリソースの作成は、depends_onに指定したリソースの作成後に行われる
  depends_on = [
    aws_lb.web
  ]
}

# 設定したプロトコルとポートを使用して接続リクエストをチェックするプロセス
resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web.arn
  port              = 443
  protocol          = "HTTPS"
  # リスナーのSSLポリシーの名前。プロトコルがHTTPSまたはTLSの場合は必須。
  ssl_policy = "ELBSecurityPolicy-FS-1-2-Res-2020-10"
  # 証明書(ACM)のURL
  certificate_arn = module.acm_web.this_acm_certificate_arn

  default_action {
    # ルーティングアクションのタイプ。有効な値は、forward、redirect、fixed-response、authenticate-cognito、authenticate-oidcのいずれかを記入する。
    type = "fixed-response"
    # カスタムのHTTPレスポンスを返すアクションを作成するための情報。
    fixed_response {
      content_type = "text/html"
      status_code  = 404
      message_body = "<html><head><title>404 Not Found</title></head><body><h1>Not Found</h1><hr><address>Apache/2.2.31</address></body></html>"
    }
  }
}

resource "aws_lb_listener_rule" "web" {
  listener_arn = aws_lb_listener.web.arn
  # 条件ブロック。異なるタイプの複数の条件ブロックを設定することができる。
  condition {
    # ALBへのアクセスを許可するドメイン
    host_header {
      values = [
        aws_route53_record.api.name,
        aws_route53_record.auth.name,
        aws_route53_record.root.name,
      ]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# ロードバランサーリスナー証明書リソース
resource "aws_lb_listener_certificate" "web" {
  listener_arn    = aws_lb_listener.web.arn
  certificate_arn = module.acm_web.this_acm_certificate_arn
}

resource "aws_lb_listener_certificate" "web_api" {
  listener_arn    = aws_lb_listener.web.arn
  certificate_arn = module.acm_api.this_acm_certificate_arn
}

resource "aws_lb_listener_certificate" "web_auth" {
  listener_arn    = aws_lb_listener.web.arn
  certificate_arn = module.acm_auth.this_acm_certificate_arn
}

resource "aws_lb_listener_rule" "admin" {
  listener_arn = aws_lb_listener.web.arn

  condition {
    host_header {
      values = [
        aws_route53_record.admin.name,
      ]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

resource "aws_lb_listener_certificate" "web_admin" {
  listener_arn    = aws_lb_listener.web.arn
  certificate_arn = module.acm_admin.this_acm_certificate_arn
}

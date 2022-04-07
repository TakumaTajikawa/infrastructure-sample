# Cloud Frontとは、キャッシュをすることでウェブコンテンツの配信速度を高速化するサービス
resource "aws_cloudfront_distribution" "web" {
  # 有効かどうか
  enabled = true
  # IPv6通信を有効にするか
  is_ipv6_enabled = true
  comment         = "For ${var.project} Web files(${var.env})"
  # ドメイン名設定
  aliases = [var.domain]

  # 証明書
  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn            = module.acm_web_cdn.this_acm_certificate_arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2019"
  }

  # アクセス制限
  restrictions {
    geo_restriction {
      # "none" "whitelist" "blacklist"のいずれかを記入
      restriction_type = "none"
    }
  }

  origin {
    # DNSドメイン名
    domain_name = aws_s3_bucket.assets.bucket_regional_domain_name
    # オリジンを識別するユニークなID
    origin_id = aws_s3_bucket.assets.bucket

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.web_assets.cloudfront_access_identity_path
    }
  }

  origin {
    domain_name = aws_s3_bucket.uploads.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.uploads.bucket

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.web_uploads.cloudfront_access_identity_path
    }
  }

  origin {
    domain_name = aws_lb.web.dns_name
    origin_id   = aws_lb.web.name
    # 独自オリジン
    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_keepalive_timeout = 5
      origin_protocol_policy   = "https-only"
      origin_read_timeout      = 60
      origin_ssl_protocols = [
        "TLSv1.2",
      ]
    }
  }

  ordered_cache_behavior {
    # 許可するメソッド
    allowed_methods = [
      "GET",
      "HEAD",
    ]
    # キャッシュするメソッド
    cached_methods = [
      "GET",
      "HEAD",
    ]
    compress               = false
    default_ttl            = 86400
    max_ttl                = 259200
    min_ttl                = 0
    path_pattern           = "/public/*"
    smooth_streaming       = false
    target_origin_id       = aws_s3_bucket.assets.bucket
    trusted_signers        = []
    viewer_protocol_policy = "redirect-to-https"

    # 転送するリクエストデータ
    forwarded_values {
      # キャッシュ動作に関連するオリジンにクエリ文字列を転送するか
      query_string = false
      # 上のquery_string に true を指定すると、すべてのクエリ文字列が転送されるが、転送するクエリ文字列を制限したい場合、この引数にリストされたクエリ文字列キーのみがキャッシュされる
      query_string_cache_keys = []
      # CloudFrontがこのキャッシュ動作のために変化させたいHeaderを指定する。すべてのヘッダーを含める場合は * を指定する。
      headers = [
        "Origin",
        "Access-Control-Request-Headers",
        "Access-Control-Request-Method"
      ]
      cookies {
        forward           = "none"
        whitelisted_names = []
      }
    }
  }

  # このディストリビューションのキャッシュ動作リソースの順序付きリスト。優先順位の高い順に上から下へ並べる。
  ordered_cache_behavior {
    allowed_methods = [
      "GET",
      "HEAD",
    ]
    cached_methods = [
      "GET",
      "HEAD",
    ]
    compress               = false
    default_ttl            = 86400
    max_ttl                = 259200
    min_ttl                = 0
    path_pattern           = "/uploads/*"
    smooth_streaming       = false
    target_origin_id       = aws_s3_bucket.uploads.bucket
    trusted_signers        = []
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      headers = [
        "Origin",
        "Access-Control-Request-Headers",
        "Access-Control-Request-Method"
      ]
      query_string            = false
      query_string_cache_keys = []

      cookies {
        forward           = "none"
        whitelisted_names = []
      }
    }
  }

  # このディストリビューションにおけるデフォルトのキャッシュの動作
  default_cache_behavior {
    allowed_methods = [
      "GET",
      "HEAD",
      "DELETE",
      "OPTIONS",
      "PATCH",
      "POST",
      "PUT",
    ]
    cached_methods = [
      "GET",
      "HEAD",
    ]
    # リクエストヘッダにAccept-Encoding: gzipを含むWebリクエストに対して、CloudFrontが自動的にコンテンツを圧縮するかどうか
    compress = false
    #  Cache-Control max-ageまたはExpiresヘッダーがない場合、CloudFrontが別のリクエストを転送する前にオブジェクトがCloudFrontキャッシュにあるデフォルトの時間(秒)
    default_ttl = 86400
    # CloudFrontがあなたのオリジンに別のリクエストを転送し、オブジェクトが更新されたかどうかを判断するまでの、CloudFrontキャッシュ内にある最大時間（単位：秒）(Cache-Control max-age、Cache-Control s-maxage、Expiresヘッダがある場合のみ有効)
    max_ttl = 259200
    # CloudFrontがオリジンにオブジェクトが更新されたかどうかを問い合わせる前に、オブジェクトがCloudFrontキャッシュに留まるようにする最小時間(単位：秒)
    min_ttl = 0
    # このキャッシュ動作に関連付けられたオリジンを使用して、Microsoft Smooth Streaming 形式でメディア ファイルを配布するかどうか
    smooth_streaming = false
    target_origin_id = aws_lb.web.name
    # プライベートコンテンツの署名付きURLの作成を許可するAWSアカウントIDのリスト
    trusted_signers = []
    # この要素を使用して、要求が PathPattern のパスパターンに一致する場合に、TargetOriginId で指定したオリジンのファイルにアクセスするためにユーザーが使用できるプロトコルを指定する。allow-all、https-only、または redirect-to-https のいずれかを指定する。
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = true
      headers      = ["*"]
      cookies {
        forward = "all"
      }
    }

    # lambda_function_association {
    #   event_type   = "viewer-request"
    #   lambda_arn   = "${module.cloudfront_basic_auth.lambda_function_arn}:${module.cloudfront_basic_auth.lambda_function_version}"
    #   include_body = false
    # }
  }

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.cloudfront_logs.bucket_domain_name
    prefix          = "web"
  }

  # custom_error_response {
  #   error_caching_min_ttl = 60
  #   error_code            = 404
  #   response_code         = 404
  #   response_page_path    = "/uploads/error/404.html"
  # }
}

resource "aws_cloudfront_origin_access_identity" "web_assets" {
  comment = "${var.project} origin access identity for assets files"
}

resource "aws_cloudfront_distribution" "admin" {
  # 有効かどうか
  enabled = true
  # IPv6通信を有効にするか
  is_ipv6_enabled = true
  comment         = "For ${var.project} Admin files(${var.env})"
  # ドメイン名設定
  aliases = ["admin.${var.domain}"]
  # 証明書
  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn            = module.acm_admin_cdn.this_acm_certificate_arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2019"
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  origin {
    domain_name = aws_s3_bucket.admin_assets.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.admin_assets.bucket

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.admin_assets.cloudfront_access_identity_path
    }
  }

  origin {
    # DNSドメイン名
    domain_name = aws_s3_bucket.uploads.bucket_regional_domain_name
    # オリジンを識別するユニークな名前
    origin_id = aws_s3_bucket.uploads.bucket

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.web_uploads.cloudfront_access_identity_path
    }
  }

  origin {
    domain_name = aws_lb.web.dns_name
    origin_id   = aws_lb.web.name

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_keepalive_timeout = 5
      origin_protocol_policy   = "https-only"
      origin_read_timeout      = 60
      origin_ssl_protocols = [
        "TLSv1.2",
      ]
    }
  }

  ordered_cache_behavior {
    allowed_methods = [
      "GET",
      "HEAD",
    ]
    cached_methods = [
      "GET",
      "HEAD",
    ]
    compress               = false
    default_ttl            = 86400
    max_ttl                = 259200
    min_ttl                = 0
    path_pattern           = "/public/*"
    smooth_streaming       = false
    target_origin_id       = aws_s3_bucket.admin_assets.bucket
    trusted_signers        = []
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      headers                 = []
      query_string            = false
      query_string_cache_keys = []

      cookies {
        forward           = "none"
        whitelisted_names = []
      }
    }
  }

  ordered_cache_behavior {
    allowed_methods = [
      "GET",
      "HEAD",
    ]
    cached_methods = [
      "GET",
      "HEAD",
    ]
    compress               = false
    default_ttl            = 86400
    max_ttl                = 259200
    min_ttl                = 0
    path_pattern           = "/uploads/*"
    smooth_streaming       = false
    target_origin_id       = aws_s3_bucket.uploads.bucket
    trusted_signers        = []
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      headers = [
        "Origin",
        "Access-Control-Request-Headers",
        "Access-Control-Request-Method"
      ]
      query_string            = false
      query_string_cache_keys = []

      cookies {
        forward           = "none"
        whitelisted_names = []
      }
    }
  }

  default_cache_behavior {
    allowed_methods = [
      "GET",
      "HEAD",
      "DELETE",
      "OPTIONS",
      "PATCH",
      "POST",
      "PUT",
    ]
    cached_methods = [
      "GET",
      "HEAD",
    ]
    compress               = false
    default_ttl            = 86400
    max_ttl                = 259200
    min_ttl                = 0
    smooth_streaming       = false
    target_origin_id       = aws_lb.web.name
    trusted_signers        = []
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = true
      headers      = ["*"]
      cookies {
        forward = "all"
      }
    }

    lambda_function_association {
      event_type   = "viewer-request"
      lambda_arn   = "${module.cloudfront_basic_auth.lambda_function_arn}:${module.cloudfront_basic_auth.lambda_function_version}"
      include_body = false
    }
  }

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.cloudfront_logs.bucket_domain_name
    prefix          = "admin"
  }

  custom_error_response {
    error_caching_min_ttl = 60
    error_code            = 404
    response_code         = 404
    response_page_path    = "/uploads/error/404.html"
  }
}

resource "aws_cloudfront_origin_access_identity" "admin_assets" {
  comment = "${var.project} origin access identity for Admin assets files"
}

resource "aws_cloudfront_origin_access_identity" "web_uploads" {
  comment = "${var.project} origin access identity for upload files"
}
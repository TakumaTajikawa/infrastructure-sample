resource "aws_route53_record" "root" {
  # このレコードを含むホストされたゾーンの ID
  zone_id = data.terraform_remote_state.common.outputs.zone_id
  name    = var.domain
  # レコードのタイプ。有効な値は、A、AAAA、CAA、CNAME、DS、MX、NAPTR、NS、PTR、SOA、SPF、SRV、TXT
  # A: IPv4 アドレスを使用して、ウェブサーバーなどのリソースにトラフィックをルーティングする
  type    = "A"
  # トラフィックルーティング先
  alias {
    name                   = aws_cloudfront_distribution.web.domain_name
    zone_id                = aws_cloudfront_distribution.web.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "root_AAAA" {
  zone_id = data.terraform_remote_state.common.outputs.zone_id
  name    = var.domain
  # AAAA: IPv6 アドレスを使用して、ウェブサーバーなどのリソースにトラフィックをルーティングする
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.web.domain_name
    zone_id                = aws_cloudfront_distribution.web.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "admin" {
  zone_id = data.terraform_remote_state.common.outputs.zone_id
  name    = "admin.${var.domain}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.admin.domain_name
    zone_id                = aws_cloudfront_distribution.admin.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "admin_AAAA" {
  zone_id = data.terraform_remote_state.common.outputs.zone_id
  name    = "admin.${var.domain}"
  type    = "AAAA"

  alias {
    # DNSドメイン名
    name                   = aws_cloudfront_distribution.admin.domain_name
    # ホストゾーンID
    zone_id                = aws_cloudfront_distribution.admin.hosted_zone_id
    # ヘルスチェックするか
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "api" {
  zone_id = data.terraform_remote_state.common.outputs.zone_id
  name    = "api.${var.domain}"
  type    = "A"

  alias {
    name                   = aws_lb.web.dns_name
    zone_id                = aws_lb.web.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "auth" {
  zone_id = data.terraform_remote_state.common.outputs.zone_id
  name    = "auth.${var.domain}"
  type    = "A"

  alias {
    name                   = aws_lb.web.dns_name
    zone_id                = aws_lb.web.zone_id
    evaluate_target_health = false
  }
}

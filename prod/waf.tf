resource "aws_wafv2_web_acl" "web" {
    name = "${var.env}-web-acl-web"
    # AWS CloudFront ディストリビューション用か、地域アプリケーション用かを指定する。有効な値は、CLOUDFRONTまたはREGIONAL。CloudFrontで動作させるには、AWSプロバイダー上でリージョンus-east-1（N. Virginia）も指定する必要がある。
    scope = "CLOUDFRONT"
    provider = aws.virginia

    # WebACL に含まれるルールのいずれにも一致しない場合に実行するアクション
    default_action {
        allow {}
    }

    # Amazon CloudWatchのメトリクスとWebリクエストのサンプル収集を定義し、有効にする。
    visibility_config {
        # 関連するリソースがCloudWatchにメトリクスを送信するかどうか
        cloudwatch_metrics_enabled = true
        # CloudWatchのメトリクスの名前
        metric_name = "${var.env}-web-acl"
        # AWS WAF が規則に一致する Web リクエストのサンプリングを保存するかどうか
        sampled_requests_enabled = true
    }

    rule {
        # ルールの名前
        name = "AWSManagedRulesCommonRuleSet"
        # ルールの優先順位
        priority = 1
        override_action {
            none {}
        }
        statement {
            managed_rule_group_statement {
                name = "AWSManagedRulesCommonRuleSet"
                excluded_rule {
                    # リクエスト本文のサイズが最大 10,240 バイトであることを確認する
                    name = "SizeRestrictions_BODY"
                }
                excluded_rule {
                    # リクエスト本文の値を検査し、ウェブアプリケーションの RFI (リモートファイルインクルージョン) を悪用しようとするリクエストをブロックする
                    name = "GenericRFI_BODY"
                }
                excluded_rule {
                    # リクエスト本文に、ローカルファイルインクルージョン (LFI) を悪用する形跡がないかを検査する
                    name = "GenericLFI_BODY"
                }
                vendor_name = "AWS"
            }
        }
        visibility_config {
            metric_name = "AWSManagedRulesCommonRuleSet"
            cloudwatch_metrics_enabled = true
            sampled_requests_enabled = true
        }
    }

    rule {
        # 既知の不正な入力ルールグループ
        name = "AWSManagedRulesKnownBadInputsRuleSet"
        priority = 2
        override_action {
            none {}
        }
        statement {
            managed_rule_group_statement {
                name = "AWSManagedRulesKnownBadInputsRuleSet"
                vendor_name = "AWS"
            }
        }
        visibility_config {
            metric_name = "AWSManagedRulesKnownBadInputsRuleSet"
            cloudwatch_metrics_enabled = true
            sampled_requests_enabled = true
        }
    }

    rule {
        # SQL インジェクション攻撃などの SQL データベースの悪用に関連するリクエストパターンをブロックするルールが含まれるルールグループ
        name = "AWSManagedRulesSQLiRuleSet"
        priority = 3
        override_action {
            none {}
        }
        statement {
            managed_rule_group_statement {
                name = "AWSManagedRulesSQLiRuleSet"
                vendor_name = "AWS"
            }
        }
        visibility_config {
            metric_name = "AWSManagedRulesSQLiRuleSet"
            cloudwatch_metrics_enabled = true
            sampled_requests_enabled = true
        }
    }

    rule {
        # Linux 固有のローカルファイルインクルージョン (LFI) 攻撃など、Linux 固有の脆弱性の悪用に関連するリクエストパターンをブロックするルールが含まれるルールグループ
        name = "AWSManagedRulesLinuxRuleSet"
        priority = 4
        override_action {
            none {}
        }
        statement {
            managed_rule_group_statement {
                name = "AWSManagedRulesLinuxRuleSet"
                vendor_name = "AWS"
            }
        }
        visibility_config {
            metric_name = "AWSManagedRulesLinuxRuleSet"
            cloudwatch_metrics_enabled = true
            sampled_requests_enabled = true
        }
    }

    rule {
        # 安全でない PHP 関数のインジェクションなど、PHP プログラミング言語の使用に固有の脆弱性の悪用に関連するリクエストパターンをブロックするルールが含まれるルールグループ
        name = "AWSManagedRulesPHPRuleSet"
        priority = 5
        override_action {
            none {}
        }
        statement {
            managed_rule_group_statement {
                name = "AWSManagedRulesPHPRuleSet"
                vendor_name = "AWS"
            }
        }
        visibility_config {
            metric_name = "AWSManagedRulesPHPRuleSet"
            cloudwatch_metrics_enabled = true
            sampled_requests_enabled = true
        }
    }

    rule {
        # Amazon 脅威インテリジェンスによってボットとして識別された IP アドレスのリストを検査する
        name = "AWSManagedRulesAmazonIpReputationList"
        priority = 6
        override_action {
            none {}
        }
        statement {
            managed_rule_group_statement {
                name = "AWSManagedRulesAmazonIpReputationList"
                vendor_name = "AWS"
            }
        }
        visibility_config {
            metric_name = "AWSManagedRulesAmazonIpReputationList"
            cloudwatch_metrics_enabled = true
            sampled_requests_enabled = true
        }
    }

    rule {
        # ボットからのリクエストをブロックおよび管理するためのルールが含まれるルールグループ
        name = "AWSManagedRulesBotControlRuleSet"
        priority = 7
        override_action {
            none {}
        }
        statement {
            managed_rule_group_statement {
                name = "AWSManagedRulesBotControlRuleSet"
                vendor_name = "AWS"
            }
        }
        visibility_config {
            metric_name = "AWSManagedRulesBotControlRuleSet"
            cloudwatch_metrics_enabled = true
            sampled_requests_enabled = true
        }
    }
}


resource "aws_wafv2_web_acl" "admin" {
    name = "${var.env}-web-acl-admin"
    scope = "CLOUDFRONT"
    provider = aws.virginia

    default_action {
        allow {}
    }

    visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name = "${var.env}-web-acl"
        sampled_requests_enabled = true
    }

    rule {
        name = "AWSManagedRulesCommonRuleSet"
        priority = 1
        override_action {
            none {}
        }
        statement {
            managed_rule_group_statement {
                name = "AWSManagedRulesCommonRuleSet"
                excluded_rule {
                    # リクエスト本文のサイズが最大 10,240 バイトであることを確認する
                    name = "SizeRestrictions_BODY"
                }
                excluded_rule {
                    # リクエスト本文の値を検査し、ウェブアプリケーションの RFI (リモートファイルインクルージョン) を悪用しようとするリクエストをブロックする
                    name = "GenericRFI_BODY"
                }
                excluded_rule {
                    # リクエスト本文に、ローカルファイルインクルージョン (LFI) を悪用する形跡がないかを検査する
                    name = "GenericLFI_BODY"
                }
                excluded_rule {
                    # 組み込み XSS 検出ルールを使用して、リクエスト本文の値を検査し、一般的なクロスサイトスクリプティング (XSS) パターンをブロックする
                    name = "CrossSiteScripting_BODY"
                }
                vendor_name = "AWS"
            }
        }
        visibility_config {
            metric_name = "AWSManagedRulesCommonRuleSet"
            cloudwatch_metrics_enabled = true
            sampled_requests_enabled = true
        }
    }

    rule {
        name = "AWSManagedRulesKnownBadInputsRuleSet"
        priority = 2
        override_action {
            none {}
        }
        statement {
            managed_rule_group_statement {
                name = "AWSManagedRulesKnownBadInputsRuleSet"
                vendor_name = "AWS"
            }
        }
        visibility_config {
            metric_name = "AWSManagedRulesKnownBadInputsRuleSet"
            cloudwatch_metrics_enabled = true
            sampled_requests_enabled = true
        }
    }

    rule {
        name = "AWSManagedRulesSQLiRuleSet"
        priority = 3
        override_action {
            none {}
        }
        statement {
            managed_rule_group_statement {
                name = "AWSManagedRulesSQLiRuleSet"
                vendor_name = "AWS"
                excluded_rule {
                    name = "SQLi_BODY"
                }
            }
        }
        visibility_config {
            metric_name = "AWSManagedRulesSQLiRuleSet"
            cloudwatch_metrics_enabled = true
            sampled_requests_enabled = true
        }
    }

    rule {
        name = "AWSManagedRulesLinuxRuleSet"
        priority = 4
        override_action {
            none {}
        }
        statement {
            managed_rule_group_statement {
                name = "AWSManagedRulesLinuxRuleSet"
                vendor_name = "AWS"
            }
        }
        visibility_config {
            metric_name = "AWSManagedRulesLinuxRuleSet"
            cloudwatch_metrics_enabled = true
            sampled_requests_enabled = true
        }
    }

    rule {
        name = "AWSManagedRulesPHPRuleSet"
        priority = 5
        override_action {
            none {}
        }
        statement {
            managed_rule_group_statement {
                name = "AWSManagedRulesPHPRuleSet"
                vendor_name = "AWS"
            }
        }
        visibility_config {
            metric_name = "AWSManagedRulesPHPRuleSet"
            cloudwatch_metrics_enabled = true
            sampled_requests_enabled = true
        }
    }

    rule {
        name = "AWSManagedRulesAmazonIpReputationList"
        priority = 6
        override_action {
            none {}
        }
        statement {
            managed_rule_group_statement {
                name = "AWSManagedRulesAmazonIpReputationList"
                vendor_name = "AWS"
            }
        }
        visibility_config {
            metric_name = "AWSManagedRulesAmazonIpReputationList"
            cloudwatch_metrics_enabled = true
            sampled_requests_enabled = true
        }
    }

    rule {
        name = "AWSManagedRulesBotControlRuleSet"
        priority = 7
        override_action {
            none {}
        }
        statement {
            managed_rule_group_statement {
                name = "AWSManagedRulesBotControlRuleSet"
                vendor_name = "AWS"
            }
        }
        visibility_config {
            metric_name = "AWSManagedRulesBotControlRuleSet"
            cloudwatch_metrics_enabled = true
            sampled_requests_enabled = true
        }
    }
}

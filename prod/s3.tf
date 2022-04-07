resource "aws_s3_bucket" "admin_assets" {
  bucket = "${var.env}-${var.project}-admin-assets"

  tags = {
    Name  = var.project
    Group = var.project
  }
}

resource "aws_s3_bucket" "cloudfront_logs" {
  bucket = "${var.env}-${var.project}-cloudfront-logs"

  tags = {
    Name  = var.project
    Group = var.project
  }
}

resource "aws_s3_bucket" "alb_logs" {
  bucket = "${var.env}-${var.project}-alb-logs"

  tags = {
    Name  = var.project
    Group = var.project
  }
}

resource "aws_s3_bucket" "assets" {
  bucket = "${var.env}-${var.project}-assets"

  # 許可するオリジンやメソッドをルールとして設定
  # cors_rule {
  #   allowed_headers = ["*"]
  #   allowed_methods = ["GET", "HEAD"]
  #   allowed_origins = [
  #     "https://admin.${var.domain}"
  #   ]
  #   expose_headers  = []
  #   max_age_seconds = 3600
  # }

  tags = {
    Name  = var.project
    Group = var.project
  }
}

resource "aws_s3_bucket" "uploads" {
  bucket = "${var.env}-${var.project}-uploads"
  # cors_rule {
  #   allowed_headers = ["*"]
  #   allowed_methods = ["GET", "HEAD"]
  #   allowed_origins = [
  #     "https://admin.${var.domain}"
  #   ]
  #   expose_headers  = []
  #   max_age_seconds = 3600
  # }

  tags = {
    Name  = var.project
    Group = var.project
  }
}

data "aws_iam_policy_document" "assets_oai" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.assets.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.web_assets.iam_arn]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.assets.arn]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.web_assets.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "assets" {
  bucket = aws_s3_bucket.assets.id
  policy = data.aws_iam_policy_document.assets_oai.json
}

data "aws_iam_policy_document" "admin_assets_oai" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.admin_assets.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.admin_assets.iam_arn]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.admin_assets.arn]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.admin_assets.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "admin_assets" {
  bucket = aws_s3_bucket.admin_assets.id
  policy = data.aws_iam_policy_document.admin_assets_oai.json
}

data "aws_iam_policy_document" "uploads" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.uploads.arn}/*"]

    principals {
      type = "AWS"
      identifiers = [
        aws_cloudfront_origin_access_identity.web_assets.iam_arn,
        aws_cloudfront_origin_access_identity.web_uploads.iam_arn,
      ]
    }
  }
  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.uploads.arn]

    principals {
      type = "AWS"
      identifiers = [
        aws_cloudfront_origin_access_identity.web_assets.iam_arn,
        aws_cloudfront_origin_access_identity.web_uploads.iam_arn,
      ]
    }
  }
}

resource "aws_s3_bucket_policy" "uploads" {
  bucket = aws_s3_bucket.uploads.id
  policy = data.aws_iam_policy_document.uploads.json
}

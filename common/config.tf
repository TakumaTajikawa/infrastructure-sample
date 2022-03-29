# 自身のアカウント情報（アカウントID、ユーザーID、およびARN）を取得することができる
data "aws_caller_identity" "currnet" {}

terraform {
    required_version = "1.0.0"

    # S3バケットでtfstateファイルを管理するよう設定
    backend "s3" {
        bucket = "sample-pj-terraform"
        key = "common.terraform.tfstate"
        region = "ap-northeast-1"
    }

    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "3.37.0"
        }
    }
}

provider "aws" {
    region = var.region
}
# 自身のアカウント情報（アカウントID、ユーザーID、およびARN）を取得することができる
data "aws_caller_identity" "current" {}

terraform {
  required_version = "1.0.0"

  # S3バケットでtfstateファイルを管理するよう設定
  backend "s3" {
    bucket = "offkai-terraform"
    key    = "prod.terraform.tfstate"
    region = "ap-northeast-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.8.0"
    }
  }
}

provider "aws" {
  region = var.region
}

provider "aws" {
  region = "us-east-1"
  alias  = "virginia"
}

# tfstateの保存先
data "terraform_remote_state" "common" {
  backend = "s3"
  config = {
    bucket = var.tf_s3_bucket
    region = var.region
    key    = var.common_state_file
  }
}

data "aws_ssm_parameter" "amzn2_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
} 
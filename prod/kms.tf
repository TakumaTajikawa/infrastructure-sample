# データの暗号化／復号化をするためのキーをセキュアに管理できるサービス
resource "aws_kms_key" "application" {
  # WSコンソールで表示されるキーの説明
  description = "A key to encrypt sensitive data in application ${var.env}"
  # キーローテーションを有効にするかどうかを指定する。デフォルトは false
  enable_key_rotation = true

  tags = {
    Group      = var.project
    Enviroment = var.project
  }
}

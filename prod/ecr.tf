resource "aws_ecr_repository" "app" {
  name = "${var.project}/${var.env}/app"

  # リポジトリ用のコンテナイメージスキャン設定を定義
  # (コンテナイメージスキャン：作成したコンテナイメージへの脆弱性の混入を特定する)
  image_scanning_configuration {
    # リポジトリにプッシュされた後にコンテナイメージをスキャンするか（true）、スキャンしないか（false）
    scan_on_push = true
  }
}

# 不要になったイメージを自動的に削除する
# (イメージ数が指定数を超えた時、イメージをプッシュしてから指定した日数が経った時)
resource "aws_ecr_lifecycle_policy" "app" {
  # ポリシーを適用するリポジトリの名前
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    "rules" : [
      {
        "rulePriority" : 1,
        "description" : "Keep last 10 images",
        "selection" : {
          "tagStatus" : "any",
          "countType" : "imageCountMoreThan",
          "countNumber" : 10
        },
        "action" : {
          "type" : "expire"
        }
      }
    ]
  })
}

resource "aws_ecr_repository" "nginx" {
  name = "${var.project}/${var.env}/nginx"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "nginx" {
  repository = aws_ecr_repository.nginx.name

  policy = jsonencode({
    "rules" : [
      {
        "rulePriority" : 1,
        "description" : "Keep last 10 images",
        "selection" : {
          "tagStatus" : "any",
          "countType" : "imageCountMoreThan",
          "countNumber" : 10
        },
        "action" : {
          "type" : "expire"
        }
      }
    ]
  })
}

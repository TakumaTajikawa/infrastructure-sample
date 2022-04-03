resource "aws_security_group" "web" {
  name        = "${var.env}-${var.project}-web"
  description = "security group for ${var.env}-${var.project} web"
  vpc_id      = aws_vpc.main.id

  # インバウンド(EC2インスタンスから出る内向きの通信)ルール
  ingress {
    description = "alb"
    # 開始ポート番号、または開始ICMPタイプ番号
    from_port = 80
    # 終了ポート番号、または終了ICMPタイプ番号
    to_port  = 80
    protocol = "tcp"
    security_groups = [
      aws_security_group.alb.id,
    ]
  }

  # アウトバウンド(外部からEC2インスタンスへ向かう外向きの通信)ルール
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env}-${var.project}-web"
  }
}

resource "aws_security_group" "alb" {
  name        = "${var.env}-${var.project}-alb"
  description = "security group for ${var.env}-${var.project} alb"

  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env}-${var.project}-alb"
  }
}

resource "aws_security_group" "aurora" {
  name        = "${var.env}-${var.project}-aurora"
  description = "security group for ${var.env}-${var.project} aurora"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "bastion"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [
      data.terraform_remote_state.common.outputs.bastion_security_group_id
    ]
  }

  ingress {
    description = "app"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [
      aws_security_group.web.id
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env}-${var.project}-aurora"
  }
}

resource "aws_security_group" "redis" {
  name        = "${var.env}-${var.project}-redis"
  description = "security group for ${var.env}-${var.project} redis"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "bastion"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    security_groups = [
      data.terraform_remote_state.common.outputs.bastion_security_group_id
    ]
  }

  ingress {
    description = "app"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    security_groups = [
      aws_security_group.web.id
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env}-${var.project}-redis"
  }
}

resource "aws_security_group" "vpc_endpoint" {
  name        = "${var.env}-${var.project}-vpc-endpoint"
  description = "securitu group for ${var.env}-${var.project} vpc-endpoint"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env}-${var.project}-vpc-endpoint"
  }
} 
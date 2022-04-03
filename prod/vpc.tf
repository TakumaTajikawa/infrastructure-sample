resource "aws_vpc" "main" {
  # IPv4 CIDRブロック
  # CIDRブロックとはIPアドレスの範囲を示したもの
  cidr_block = "172.28.0.0/16"
  # VPC がパブリック IP アドレスを持つインスタンスへのパブリック DNS ホスト名の割り当てをサポートするかどうか
  enable_dns_hostnames = true
  # VPC が Amazon 提供の DNS サーバーを介した DNS 解決策をサポートするかどうか
  enable_dns_support = true
  # EC2 インスタンスが物理ハードウェアに分散される方法
  # "default"（共有） - 複数の AWS アカウント が、同じ物理ハードウェアを共有できる
  # "dedicated"（ハードウェア専有インスタンス）- インスタンスはシングルテナントのハードウェアで実行される
  instance_tenancy = "default"
  # IPv6 CIDRブロック
  assign_generated_ipv6_cidr_block = false

  tags = {
    Name  = "${var.env}-${var.project}"
    Group = var.project
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name  = "${var.env}-${var.project}"
    Group = var.project
  }
}

# ネットワーク経路のルールが記載されたテーブル
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  # このリソースに変更が発生する際の挙動を変更できる
  lifecycle {
    # 実際のリソースとTerraform管理下のリソースの差分があった際、指定したリソースの変更が無視される
    ignore_changes = [
      route,
    ]
  }

  tags = {
    Name  = "${var.env}-${var.project}-public"
    Group = var.project
  }
}

# ルートテーブルに経路情報(ルール)を追加する
resource "aws_route" "default_gw" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_subnet" "public" {
  for_each                = var.availability_zones
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 4, each.value)
  availability_zone       = each.key
  map_public_ip_on_launch = true
  tags = {
    Name  = "${var.env}-${var.project}-public-${each.key}"
    Group = var.project
  }
}

# サブネットとルートテーブル間の関連付けを作成するためのリソース
resource "aws_route_table_association" "public" {
  for_each       = var.availability_zones
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  lifecycle {
    ignore_changes = [
      route,
    ]
  }

  tags = {
    Name  = "${var.env}-${var.project}-private"
    Group = var.project
  }
}

resource "aws_subnet" "private" {
  for_each                = var.availability_zones
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 4, each.value + 3)
  availability_zone       = each.key
  map_public_ip_on_launch = false
  tags = {
    Name  = "${var.env}-${var.project}-private-${each.key}"
    Group = var.project
  }
}

# サブネットとルートテーブル間の関連付けを作成するためのリソース
resource "aws_route_table_association" "private" {
  for_each       = var.availability_zones
  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private.id
}

resource "aws_vpc_peering_connection" "common" {
  peer_vpc_id = aws_vpc.main.id
  vpc_id      = data.terraform_remote_state.common.outputs.vpc_id
  auto_accept = true

  tags = {
    Name = "${var.env}-to-common-${var.project}-peering"
  }
}

resource "aws_route" "peering_route_env_to_coomon" {
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = data.terraform_remote_state.common.outputs.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.common.id
}

resource "aws_route" "peering_route_common_to_env" {
  route_table_id            = data.terraform_remote_state.common.outputs.route_table_id
  destination_cidr_block    = aws_vpc.main.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.common.id
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id          = aws_vpc.main.id
  service_name    = "com.amazonaws.ap-northeast-1.s3"
  route_table_ids = [aws_route_table.public.id, aws_route_table.private.id]

  policy = jsonencode({
    "Statement" : [
      {
        "Action" : "*",
        "Effect" : "Allow",
        "Resource" : "*",
        "Principal" : "*"
      }
    ]
  })

  tags = {
    Name = "${var.env}-${var.project}-s3"
  }

  lifecycle {
    ignore_changes = [policy]
  }
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.ap-northeast-1.ssm"
  subnet_ids = [
    for subnet in aws_subnet.private :
    subnet.id
  ]
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true

  policy = jsonencode({
    "Statement" : [
      {
        "Action" : "*",
        "Effect" : "Allow",
        "Resource" : "*",
        "Principal" : "*"
      }
    ]
  })

  tags = {
    Name = "${var.env}-${var.project}-ssm"
  }

  lifecycle {
    ignore_changes = [policy]
  }
}

resource "aws_vpc_endpoint" "ses" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.ap-northeast-1.email-smtp"
  subnet_ids = [
    for subnet in aws_subnet.private :
    subnet.id
  ]
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true

  policy = jsonencode({
    "Statement" : [
      {
        "Action" : "*",
        "Effect" : "Allow",
        "Resource" : "*",
        "Principal" : "*"
      }
    ]
  })

  tags = {
    Name = "${var.env}-${var.project}-ses"
  }

  lifecycle {
    ignore_changes = [policy]
  }
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.ap-northeast-1.ecr.dkr"
  subnet_ids = [
    for subnet in aws_subnet.private :
    subnet.id
  ]
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true

  policy = jsonencode({
    "Statement" : [
      {
        "Action" : "*",
        "Effect" : "Allow",
        "Resource" : "*",
        "Principal" : "*"
      }
    ]
  })

  tags = {
    Name = "${var.env}-${var.project}-ecr-dkr"
  }

  lifecycle {
    ignore_changes = [policy]
  }
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.ap-northeast-1.ecr.api"
  subnet_ids = [
    for subnet in aws_subnet.private :
    subnet.id
  ]
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true

  policy = jsonencode({
    "Statement" : [
      {
        "Action" : "*",
        "Effect" : "Allow",
        "Resource" : "*",
        "Principal" : "*"
      }
    ]
  })

  tags = {
    Name = "${var.env}-${var.project}-ecr-api"
  }

  lifecycle {
    ignore_changes = [policy]
  }
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.ap-northeast-1.logs"
  subnet_ids = [
    for subnet in aws_subnet.private :
    subnet.id
  ]
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true

  policy = jsonencode({
    "Statement" : [
      {
        "Action" : "*",
        "Effect" : "Allow",
        "Resource" : "*",
        "Principal" : "*"
      }
    ]
  })

  tags = {
    Name = "${var.env}-${var.project}-logs"
  }

  lifecycle {
    ignore_changes = [policy]
  }
}

resource "aws_vpc" "main" {
    # IPv4 CIDRブロック
    # CIDRブロックとはIPアドレスの範囲を示したもの
    cidr_block = "172.31.0.0/16"
    # VPC がパブリック IP アドレスを持つインスタンスへのパブリック DNS ホスト名の割り当てをサポートするかどうか
    enable_dns_hostnames = true
    # VPC が Amazon 提供の DNS サーバーを介した DNS 解決策をサポートするかどうか
    enable_dns_support   = true
    # EC2 インスタンスが物理ハードウェアに分散される方法
    # "default"（共有） - 複数の AWS アカウント が、同じ物理ハードウェアを共有できる
    # "dedicated"（ハードウェア専有インスタンス）- インスタンスはシングルテナントのハードウェアで実行される
    instance_tenancy     = "default"
    # IPv6 CIDRブロック
    assign_generated_ipv6_cidr_block = false

    tags = {
        Name = "${var.project}-${var.env}"
    }
}

resource "aws_internet_gateway" "main" {
    vpc_id = aws_vpc.main.id

    tags = {
        Name = "${var.project}-${var.env}"
        Group = var.project
    }
}

# ネットワーク経路のルールが記載されたテーブル
resource "aws_route_table" "main" {
    vpc_id = aws_vpc.main.id
    # このリソースに変更が発生する際の挙動を変更できる
    lifecycle {
        # 実際のリソースとTerraform管理下のリソースの差分があった際、指定したリソースの変更が無視される
        ignore_changes = [
            route,
        ]
    }

    tags = {
        Name = "${var.project}-${var.env}"
        Grroup = var.project
    }
}

# ルートテーブルに経路情報(ルール)を追加する
resource "aws_route" "default_gw" {
    route_table_id = aws_route_table.main.id
    # 宛先のCIDRブロック
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
}

resource "aws_subnet" "main_a" {
    vpc_id = aws_vpc.main.id
    cidr_block = "172.31.0.0/24"
    availability_zone = "${var.region}a"

    tags = {
        Name = "${var.project}-${var.env}"
        Group = var.project
    }
}

# サブネットとルートテーブル間の関連付けを作成するためのリソース
resource "aws_route_table_association" "main" {
    subnet_id = aws_subnet.main_a.id
    route_table_id = aws_route_table.main.id
} 
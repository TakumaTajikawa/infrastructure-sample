resource "aws_security_group" "bastion" {
    vpc_id = aws_vpc.main.id
    name = "${var.project}-${var.env}-bastion"
    description = "security group for bastion"

    # インバウンド(EC2インスタンスから出る内向きの通信)ルール
    ingress {
        description = "arsaga office"
        # 開始ポート番号、または開始ICMPタイプ番号
        from_port   = 22
        # 終了ポート番号、または終了ICMPタイプ番号
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = [
            "159.28.73.15/32",
            "219.111.2.150/32",
            "118.27.19.83/32",
            "159.28.73.17/32",
            "159.28.73.16/32",
            "52.192.163.218/32",
            "133.114.60.207/32",
        ]
    }

    ingress {
        # -1指定は全てを意味する
        from_port   = -1
        to_port     = -1
        protocol    = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # アウトバウンド(外部からEC2インスタンスへ向かう外向きの通信)ルール
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.project}-${var.env}-bastion"
    }
}

# 踏み台サーバー
resource "aws_instance" "bastion" {
    ami = data.aws_ssm_parameter.amzn2_ami
    instance_type = "t3.nano"
    key_name = "administrator"
    vpc_security_group_ids = [
        aws_security_group.bastion.id
    ]

    subnet_id = aws_subnet.main_a.id
    # 自動割り当てパブリックIP
    associate_public_ip_address = "true"

    user_data = file("files/start_up_scripts/bastion.sh")

    # クレジット仕様
    credit_specification {
        # CPU使用率のクレジットオプション。"standard" or "unlimited"を記述する
        # Standard Mode(スタンダードモード): CPUクレジット残高が0になると、CPU使用率はベースライン使用率以下までのみ使用できます。CPUがアイドル状態になると、CPUクレジットの残高が回復します。
        # Unlimited Mode(無制限モード): 長時間にわたって高い CPU 使用率でインスタンスを実行する場合には、CPUクレジットが0になった後は、vCPU 時間ごとに均一追加料金が発生します。24 時間ごとのインスタンスの平均 CPU 使用率またはインスタンスの存続期間のいずれか短い方の時間で、インスタンスの平均 CPU 使用率がベースライン以下になった場合、1 時間ごとのインスタンス価格は自動的にすべての CPU 使用率スパイクをカバーします。
        cpu_credits = "standard"
    }
    # 詳細モニタリングを有効にするかどうか
    monitoring = true

    iam_instance_profile = aws_iam_instance_profile.bastion_instance.name

    # ルートデバイスボリュームの設定
    root_block_device {
        # ボリュームのサイズ。単位：GiB(ギビバイト)
        volume_size = "8"
    }

    lifecycle {
        ignore_changes = [
            ami,
        ]
    }

    tags = {
        Name = "${var.project}-${var.env}-bastion"
    }
}

# ElasticIPアドレス(AWS内で使える固定IPアドレス)のリソース
resource "aws_eip" "bastion" {
    instance = aws_instance.bastion.id
    vpc = true

    tags = {
        Name = "${var.project}-${var.env}-bastion"
    }
}
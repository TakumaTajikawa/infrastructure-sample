resource "aws_iam_role" "bastion_instance" {
    name = "bastion_instance"
    assume_role_policy = jsonencode({
        "Version" : "2012-10-17",
        "Statement" : [
            {
                "Sid" : "",
                "Effect" : "Allow",
                "Principal" : {
                    "Service" : "ec2.amazonaws.com"
                },
                "Action" : "sts:AssumeRole"
            }
        ]
    })
}

resource "aws_iam_role_policy" "bastion_instance" {
    name = "bastion_instance"
    role = aws_iam_role.bastion_instance.id
    policy = jsonencode({
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "S3Access",
                "Effect": "Allow",
                "Action": [
                    "s3:*"
                ],
                "Resource": "*"
            }
        ]
    })
}

resource "aws_iam_instance_profile" "bastion_instance" {
    name = "bastion_instance"
    role = aws_iam_role.bastion_instance.name
}

resource "aws_iam_policy" "iam_ssh_login_assum_role" {
    name = "iam_ssh_login_assum_role"
    policy = jsonencode({
        "Version" : "2012-10-17",
        "Statement" : [
            {
                "Effect" : "Allow",
                "Action" : "sts:AssumeRole",
                "Resource" : [
                    "arn:aws:iam::597775983412:role/${var.project}_iam_login_role"
                ]
            },
            {
                "Effect" : "Allow",
                "Action" : "ec2:DescribeTags",
                "Resource" : "*"
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "bastion_iam_ssh" {
    role       = aws_iam_role.bastion_instance.name
    policy_arn = aws_iam_policy.iam_ssh_login_assum_role.arn
} 

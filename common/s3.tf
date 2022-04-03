resource "aws_s3_bucket" "iam_ssh" {
    bucket = "${var.project}-iam-ssh"

    tags = {
        Name = var.project
        Group = var.project
    }
}

# // ファイルをs3にアップする
# resource "aws_s3_bucket_object" "iam_ssh_install_script" {
#     bucket = aws_s3_bucket.iam_ssh.id
#     key = "install_iam_ssh.sh"
#     source = "files/iam_ssh/install_iam_ssh.sh"
#     etag = filemd5("files/iam_ssh/install_iam_ssh.sh")
# }

# // ファイルをs3にアップする
# resource "aws_s3_bucket_object" "iam_ssh_config" {
#     bucket = aws_s3_bucket.iam_ssh.id
#     key = "aws-ec2-ssh.conf"
#     source = "files/iam_ssh/aws-ec2-ssh.conf"
#     etag = filemd5("files/iam_ssh/aws-ec2-ssh.conf")
# }

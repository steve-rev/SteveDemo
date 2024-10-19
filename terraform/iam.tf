resource "aws_iam_role" "ec2allrole" {
  name = "ec2AllRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "ec2allprofile" {
  name = "ec2AllProfile"
  role = aws_iam_role.ec2allrole.name
}

resource "aws_iam_policy" "ec2allpolicy" {
  name        = "ec2all"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "roleattach" {
  role       = aws_iam_role.ec2allrole.name
  policy_arn = aws_iam_policy.ec2allpolicy.arn
}


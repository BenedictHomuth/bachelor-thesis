resource "aws_ssm_parameter" "param_node_token" {
  type = "String"
  name = "/k3s/node-token"
  value = "inital"
}

resource "aws_ssm_parameter" "param_control_plane_ip" {
  type = "String"
  name = "/k3s/control-plane-ip"
  value = "initial"
}

resource "aws_iam_role" "ssm_role" {
  name = "test_role"

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

  tags = {
      tag-key = "tag-value"
  }
}

resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "ssm_instance_profile"
  role = "${aws_iam_role.ssm_role.name}"
}

resource "aws_iam_role_policy" "ssm_policy" {
  name = "ssm_policy"
  role = "${aws_iam_role.ssm_role.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssm:PutParameter",
                "ssm:DeleteParameter",
                "ssm:GetParameterHistory",
                "ssm:GetParametersByPath",
                "ssm:GetParameters",
                "ssm:GetParameter",
                "ssm:DeleteParameters"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "ssm:DescribeParameters",
            "Resource": "*"
        }
    ]
}
  EOF
}

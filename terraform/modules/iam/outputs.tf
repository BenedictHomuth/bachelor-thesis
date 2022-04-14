output "iam_policy" {
  value = aws_iam_instance_profile.k3s_instance_profile.name
}
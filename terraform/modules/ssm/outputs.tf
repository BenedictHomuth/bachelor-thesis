output "ssm_parameter_policy" {
  value = aws_iam_instance_profile.ssm_instance_profile.name
}
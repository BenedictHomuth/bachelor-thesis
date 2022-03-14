output "vm_ip_amd64" {
  value = aws_instance.test_ec2_amd64.public_ip
}

output "vm_ip_arm64" {
  value = aws_instance.test_ec2_arm64.public_ip
}

output "docker_steps" {
  value = var.docker_setup
}

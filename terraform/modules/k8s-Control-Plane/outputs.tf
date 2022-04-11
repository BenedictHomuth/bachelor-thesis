output "ip" {
  value = aws_instance.ec2_control_plane.public_ip
}
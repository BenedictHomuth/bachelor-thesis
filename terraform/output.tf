output "k3s-master" {
  value = aws_instance.k3s-master.public_ip
}

output "k3s-worker-one" {
  value = aws_instance.k3s-worker-one.public_ip
}

output "k3s-worker-two" {
  value = aws_instance.k3s-worker-two.public_ip
}
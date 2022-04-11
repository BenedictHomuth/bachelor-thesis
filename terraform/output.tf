output "k3s-master" {
  value = aws_instance.k3s-master.public_ip
}

output "k3s-worker" {
  value = aws_instance.k3s-worker.public_ip
}